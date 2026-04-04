import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/utils/record_session_helper.dart';
import '../../../integration/audio/easy_audio/easy_audio_service.dart';
import '../../entities/android_service.dart';
import '../../entities/audio_encoder.dart';
import '../../entities/easy_audio_config.dart';
import '../../entities/easy_audio_mode.dart';
import '../../entities/easy_audio_state.dart';
import '../../entities/pending_recording.dart';
import '../../entities/record_session.dart';
import '../../entities/recording_result.dart';
import '../pending_recordings_usecase.dart';

class EasyAudioPermissionDeniedException implements Exception {}

@injectable
class RecordSessionUsecase {
  final PendingRecordingsUsecase _pendingRecordingsUsecase;
  final EasyAudioService _easyAudio;

  RecordSessionUsecase(this._pendingRecordingsUsecase)
    : _easyAudio = EasyAudioService();

  EasyAudioService get easyAudio => _easyAudio;

  Future<void> ensureAudioInitialized() async {
    if (_easyAudio.isInitialized) {
      return;
    }

    await _easyAudio.initialize(const EasyAudioConfig());
  }

  Future<String?> prepareAndStartRecording({
    required RecordSession session,
    required int? userId,
    required String fallbackLocale,
  }) async {
    await _pendingRecordingsUsecase.init();

    final initialState = _easyAudio.currentState;
    final wasActiveBefore =
        initialState == EasyAudioState.recording ||
        initialState == EasyAudioState.paused ||
        initialState == EasyAudioState.processing;
    if (wasActiveBefore) {
      return null;
    }

    final isIOS = Platform.isIOS;
    final mode = isIOS ? EasyAudioMode.realtime : EasyAudioMode.recordOnly;

    final prefix = RecordSessionHelper.buildRecordingFilePrefix(
      userIdFallback: userId ?? 0,
      appointmentIdEmr: session.appointmentIdEmr,
      appointmentId: session.appointmentId,
    );

    final config = EasyAudioConfig(
      mode: mode,
      encoder: isIOS ? AudioEncoder.wav : AudioEncoder.aacLc,
      locale: session.localeId ?? fallbackLocale,
      autoResumeAfterInterruption: true,
      enableBackgroundRecording: Platform.isAndroid,
      androidService: Platform.isAndroid
          ? const AndroidService(
              title: 'Recording in progress',
              content: 'Tap to return to the app',
            )
          : null,
      outputDirectory: _pendingRecordingsUsecase.baseDirectoryPath,
      filePrefix: prefix,
      enableCrashRecovery: true,
    );

    if (!_easyAudio.isInitialized) {
      await _easyAudio.initialize(config);
    } else {
      final canUpdateConfig =
          initialState == EasyAudioState.idle ||
          initialState == EasyAudioState.error;
      if (canUpdateConfig) {
        await _easyAudio.updateConfig(config);
      }
    }

    final ok = await _easyAudio.requestPermissions();
    if (!ok) {
      throw EasyAudioPermissionDeniedException();
    }

    if (Platform.isAndroid && config.enableBackgroundRecording) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        throw EasyAudioPermissionDeniedException();
      }
    }
    await _easyAudio.start();

    final filePath = _easyAudio.currentFilePath?.trim() ?? '';
    if (filePath.isEmpty) {
      return null;
    }

    final id = RecordSessionHelper.generatePendingRecordingId();

    await _pendingRecordingsUsecase.upsert(
      PendingRecording.fromRecordSession(
        session,
        id: id,
        userId: userId,
        locale: session.localeId ?? fallbackLocale,
        content: '',
        filePath: filePath,
        fileSizeBytes: 0,
        durationMs: 0,
      ),
    );

    return id;
  }

  Future<String?> persistSheetResult({
    required RecordSession session,
    required RecordingResult result,
    required int? userId,
    required String fallbackLocale,
    required String? pendingRecordingId,
  }) async {
    final filePath = result.filePath?.trim() ?? '';
    if (filePath.isEmpty) {
      return null;
    }

    final locale = session.localeId ?? fallbackLocale;
    final content = (result.transcript ?? '').trim();

    await _pendingRecordingsUsecase.init();

    PendingRecording? existing;
    if (pendingRecordingId != null) {
      existing = _pendingRecordingsUsecase.getById(pendingRecordingId);
    }

    final resolvedContent = content.isNotEmpty
        ? content
        : (existing?.content.trim().isNotEmpty == true)
        ? existing!.content
        : content;

    final id =
        existing?.id ??
        pendingRecordingId ??
        RecordSessionHelper.generatePendingRecordingId();

    final resolvedFileSizeBytes =
        result.fileSizeBytes ?? await File(filePath).length();

    final next =
        (existing ??
                PendingRecording.fromRecordSession(
                  session,
                  id: id,
                  userId: userId,
                  locale: locale,
                  content: resolvedContent,
                  filePath: filePath,
                  fileSizeBytes: resolvedFileSizeBytes,
                  durationMs: result.duration.inMilliseconds,
                ))
            .copyWith(
              userId: userId,
              appointmentIdEmr: session.appointmentIdEmr,
              appointmentId: session.appointmentId,
              clinicName: session.clinicName,
              patientName: session.patientName,
              bookingDate: session.bookingDate,
              bookingTime: session.bookingTime,
              locale: locale,
              content: resolvedContent,
              filePath: filePath,
              fileSizeBytes: resolvedFileSizeBytes,
              durationMs: result.duration.inMilliseconds,
              status: PendingRecordingStatus.pending,
            );

    await _pendingRecordingsUsecase.upsert(next);

    return id;
  }

  Future<void> cancelAndMaybeDeletePending({
    required bool deletePendingFile,
    required String? pendingRecordingId,
  }) async {
    try {
      await _easyAudio.cancel();
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
    }

    if (deletePendingFile && pendingRecordingId != null) {
      try {
        await _pendingRecordingsUsecase.deleteById(
          pendingRecordingId,
          deleteFile: true,
        );
      } catch (_) {}
    }
  }

  Future<void> saveSessionToCache(RecordSession session) =>
      _pendingRecordingsUsecase.saveSessionToCache(session);
  Future<void> clearSessionCache() =>
      _pendingRecordingsUsecase.clearSessionCache();
}
