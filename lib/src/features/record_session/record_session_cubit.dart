import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../core/utils/transcript_persistence.dart';
import '../../domain/entities/data_record.dart';
import '../../domain/entities/easy_audio_state.dart';
import '../../domain/entities/record_session.dart';
import '../../domain/entities/recording_result.dart';
import '../../domain/entities/transcript_result.dart';
import '../../domain/usecases/recording/record_session_usecase.dart';
import '../../integration/audio/easy_audio/easy_audio_service.dart';
import '../../integration/wakelock/wakelock_integration.dart';
import '../pending_upload/pending_upload_bloc.dart';

part 'record_session_state.dart';

enum RecordSessionStartResult { started, resumed, permissionDenied, failed }

@lazySingleton
class RecordSessionCubit extends Cubit<RecordSessionState>
    with WidgetsBindingObserver {
  final RecordSessionUsecase _recordSessionUsecase;
  final PendingUploadBloc _pendingUploadCubit;

  RecordSessionCubit(this._recordSessionUsecase, this._pendingUploadCubit)
    : super(const RecordSessionState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  EasyAudioService get easyAudio => _recordSessionUsecase.easyAudio;

  // Elapsed tracking must survive sheet minimize/restore.
  DateTime? _recordingResumedAt;
  Duration _elapsedBeforeResume = Duration.zero;
  Timer? _elapsedTicker;

  bool _isClosingSession = false;

  StreamSubscription<double>? _ampSub;
  StreamSubscription<TranscriptResult>? _transcriptSub;
  StreamSubscription<EasyAudioState>? _stateSub;

  final List<double> _amplitudeHistory = <double>[];
  String _finalTranscript = '';
  String _liveTranscript = '';

  List<double> get amplitudeHistorySnapshot =>
      List<double>.unmodifiable(_amplitudeHistory);

  String get finalTranscriptSnapshot => _finalTranscript;

  String get liveTranscriptSnapshot => _liveTranscript;

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    _cancelSessionSubscriptions();
    _elapsedTicker?.cancel();
    _elapsedTicker = null;

    return super.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!this.state.hasSession) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeAutoResumeAfterInterruption());
    }
  }

  Future<void> ensureAudioInitialized() async {
    await _recordSessionUsecase.ensureAudioInitialized();
  }

  Future<RecordSessionStartResult> startOrResumeForData({
    required DataRecord<Map<String, dynamic>> data,
    required int? userId,
    required String fallbackLocale,
    String? clinicName,
    String? patientName,
    String? bookingDate,
    String? bookingTime,
    String? localeId,
  }) async {
    if (state.hasSession) {
      if (state.isIdle) {
        _endSession();
      } else {
        await restoreSheet();
        return RecordSessionStartResult.resumed;
      }
    }

    try {
      await ensureAudioInitialized();

      emit(
        state.copyWith(
          session: RecordSession(
            data: data,
            clinicName: clinicName,
            patientName: patientName,
            bookingDate: bookingDate,
            bookingTime: bookingTime,
            localeId: localeId,
            startedAt: DateTime.now(),
          ),
          minimized: false,
          sheetOpen: false,
          pendingRecordingId: null,
          audioState: easyAudio.currentState,
          elapsed: Duration.zero,
        ),
      );

      _resetCaches();
      await _ensureSessionSubscriptions();

      final pendingId = await _recordSessionUsecase.prepareAndStartRecording(
        session: state.session!,
        userId: userId,
        fallbackLocale: fallbackLocale,
      );

      if (pendingId == null) {
        await _cancelAndEnd(deletePendingFile: false);
        return RecordSessionStartResult.failed;
      }

      emit(state.copyWith(pendingRecordingId: pendingId));

      // Save session info for crash recovery
      unawaited(_recordSessionUsecase.saveSessionToCache(state.session!));

      _requestOpenSheet();

      unawaited(enableWakelock(enable: true));

      return RecordSessionStartResult.started;
    } on EasyAudioPermissionDeniedException {
      await _cancelAndEnd(deletePendingFile: false);
      return RecordSessionStartResult.permissionDenied;
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }

      await _cancelAndEnd(deletePendingFile: false);
      return RecordSessionStartResult.failed;
    }
  }

  bool matchesDataId(String id) {
    return state.session?.data.id == id;
  }

  Future<void> maybeAutoOpenForDataId(String id) async {
    if (!state.hasSession) {
      return;
    }
    if (!matchesDataId(id)) {
      return;
    }
    if (!state.minimized) {
      return;
    }

    await restoreSheet();
  }

  Future<void> restoreSheet() async {
    if (!state.hasSession) {
      return;
    }
    if (state.sheetOpen) {
      return;
    }

    _requestOpenSheet();
  }

  void notifyUploadResult({required String id, required bool success}) {
    emit(
      state.copyWith(
        lastUploadedDataId: id.trim(),
        lastUploadSuccess: success,
        lastUploadAt: DateTime.now(),
      ),
    );
  }

  void markSheetOpen() {
    emit(state.copyWith(sheetOpen: true, minimized: false));
    _updateElapsedTicker();
  }

  void markSheetClosed() {
    emit(state.copyWith(sheetOpen: false));
  }

  Future<void> minimize() async {
    if (!state.hasSession) {
      return;
    }
    if (state.minimized) {
      return;
    }

    emit(state.copyWith(minimized: true));
    _updateElapsedTicker();
  }

  Future<void> cancelAndDiscard() async {
    await _cancelAndEnd(deletePendingFile: true);
  }

  Future<void> handleSheetResult({
    required RecordingResult result,
    required int? userId,
    required String fallbackLocale,
  }) async {
    final session = state.session;
    if (session == null) {
      return;
    }

    try {
      final resolvedTranscript = resolveTranscriptForPersistence(
        resultTranscript: result.transcript,
        finalTranscript: _finalTranscript,
        liveTranscript: _liveTranscript,
      );

      final normalizedResult = RecordingResult(
        filePath: result.filePath,
        duration: result.duration,
        transcript: resolvedTranscript,
        wasRecovered: result.wasRecovered,
        startTime: result.startTime,
        endTime: result.endTime,
        fileSizeBytes: result.fileSizeBytes,
        localeId: result.localeId,
      );

      final id = await _recordSessionUsecase.persistSheetResult(
        session: session,
        result: normalizedResult,
        userId: userId,
        fallbackLocale: fallbackLocale,
        pendingRecordingId: state.pendingRecordingId,
      );

      if (id != null) {
        final filePath = result.filePath?.trim() ?? '';
        final fileUri = filePath.isNotEmpty
            ? Uri.file(filePath).toString()
            : null;

        emit(
          state.copyWith(
            pendingRecordingId: id,
            lastSavedRecordingId: id,
            lastSavedAt: DateTime.now(),
            lastSavedFilePath: fileUri,
            lastSavedDataId: session.data.id,
            lastSavedContent: normalizedResult.transcript,
          ),
        );
        unawaited(_pendingUploadCubit.enqueue(id));
      }
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
    } finally {
      unawaited(enableWakelock(enable: false));

      _endSession();
    }
  }

  void _requestOpenSheet() {
    if (!state.hasSession) {
      return;
    }
    if (state.sheetOpen) {
      return;
    }

    emit(state.copyWith(openSheetRequestId: state.openSheetRequestId + 1));
  }

  void _updateElapsedTicker() {
    final shouldTick =
        state.hasSession &&
        state.minimized &&
        state.audioState == EasyAudioState.recording;

    if (shouldTick) {
      _elapsedTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!state.hasSession) {
          return;
        }
        emit(state.copyWith(elapsed: _computeElapsed()));
      });
      return;
    }

    _elapsedTicker?.cancel();
    _elapsedTicker = null;
  }

  Duration _computeElapsed() {
    if (!state.hasSession) {
      return Duration.zero;
    }

    final s = state.audioState;
    if (s == EasyAudioState.idle || s == EasyAudioState.error) {
      return Duration.zero;
    }

    if (s == EasyAudioState.recording) {
      final resumedAt = _recordingResumedAt;
      if (resumedAt == null) {
        return _elapsedBeforeResume;
      }
      return _elapsedBeforeResume + DateTime.now().difference(resumedAt);
    }

    return _elapsedBeforeResume;
  }

  Future<void> _maybeAutoResumeAfterInterruption() async {
    if (!state.hasSession) {
      return;
    }

    if (!easyAudio.wasPausedByInterruption) {
      return;
    }

    if (!easyAudio.config.autoResumeAfterInterruption) {
      return;
    }

    if (easyAudio.currentState != EasyAudioState.paused) {
      return;
    }

    try {
      await easyAudio.resume();
    } catch (_) {
      // Best-effort.
    }
  }

  void _resetCaches() {
    _amplitudeHistory.clear();

    _finalTranscript = '';
    _liveTranscript = '';

    _recordingResumedAt = null;
    _elapsedBeforeResume = Duration.zero;

    _elapsedTicker?.cancel();
    _elapsedTicker = null;

    emit(state.copyWith(elapsed: Duration.zero));
  }

  void _cancelSessionSubscriptions() {
    _ampSub?.cancel();
    _ampSub = null;
    _transcriptSub?.cancel();
    _transcriptSub = null;
    _stateSub?.cancel();
    _stateSub = null;
  }

  Future<void> _ensureSessionSubscriptions() async {
    emit(state.copyWith(audioState: easyAudio.currentState));

    _stateSub ??= easyAudio.stateStream.listen((s) {
      if (s == EasyAudioState.recording) {
        _recordingResumedAt ??= DateTime.now();
      } else if (s == EasyAudioState.paused || s == EasyAudioState.processing) {
        final resumedAt = _recordingResumedAt;
        if (resumedAt != null) {
          _elapsedBeforeResume += DateTime.now().difference(resumedAt);
          _recordingResumedAt = null;
        }
      } else if (s == EasyAudioState.idle || s == EasyAudioState.error) {
        _recordingResumedAt = null;
        _elapsedBeforeResume = Duration.zero;
      }

      emit(state.copyWith(audioState: s, elapsed: _computeElapsed()));
      _updateElapsedTicker();
    });

    _ampSub ??= easyAudio.amplitudeStream.listen((amp) {
      _amplitudeHistory.add(amp.clamp(0.0, 1.0));
      if (_amplitudeHistory.length > state.maxSamples) {
        _amplitudeHistory.removeRange(
          0,
          _amplitudeHistory.length - state.maxSamples,
        );
      }
    });

    _transcriptSub ??= easyAudio.transcriptStream.listen((result) {
      if (result.isFinal) {
        final text = result.text.trim();
        if (text.isNotEmpty) {
          _finalTranscript = _finalTranscript.isEmpty
              ? text
              : '$_finalTranscript $text';
        }
        _liveTranscript = '';
        return;
      }

      _liveTranscript = result.text;
    });
  }

  Future<void> _cancelAndEnd({required bool deletePendingFile}) async {
    if (!state.hasSession) {
      return;
    }
    if (_isClosingSession) {
      return;
    }

    _isClosingSession = true;

    try {
      final pendingId = state.pendingRecordingId;

      await _recordSessionUsecase.cancelAndMaybeDeletePending(
        deletePendingFile: deletePendingFile,
        pendingRecordingId: pendingId,
      );

      _cancelSessionSubscriptions();
      _resetCaches();

      emit(const RecordSessionState());
    } finally {
      _isClosingSession = false;
    }
  }

  void _endSession() {
    _cancelSessionSubscriptions();
    _resetCaches();

    unawaited(_recordSessionUsecase.clearSessionCache());

    emit(
      state.copyWith(
        session: null,
        pendingRecordingId: null,
        minimized: false,
        sheetOpen: false,
        audioState: EasyAudioState.idle,
      ),
    );
    _updateElapsedTicker();
  }
}
