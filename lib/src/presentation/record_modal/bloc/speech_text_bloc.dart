import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../domain/usecase/speech_to_text_usecase.dart';
import '../../../record_audio_constants.dart';
import '../entities/speech_text_state_ui.dart';

part 'speech_text_event.dart';
part 'speech_text_state.dart';

class SpeechTextBloc extends Bloc<SpeechTextEvent, SpeechTextState> {
  SpeechTextBloc(this._speechToTextUsecase)
      : super(const SpeechTextInitial(SpeechTextStateUI())) {
    on<InitSpeechToTextEvent>(_onInitSpeechToText);
    on<StartRecordEvent>(_onStartRecord);
    on<StopRecordEvent>(_onStopRecord);
    on<PauseRecordEvent>(_onPauseRecord);
    on<ResumeRecordEvent>(_onResumeRecord);
    on<_SpeechPipelineErrorEvent>(_onPipelineError);

    add(InitSpeechToTextEvent(retryCount: 0));
  }

  final SpeechToTextUsecase _speechToTextUsecase;
  DateTime? _recordingStartedAt;
  Duration _totalPausedDuration = Duration.zero;
  DateTime? _pausedAt;

  /// Get the microphone audio stream for real-time waveform visualization
  MicrophoneAudioStream? get microphoneStream =>
      _speechToTextUsecase.microphoneStream;

  Future<void> _onInitSpeechToText(
    InitSpeechToTextEvent event,
    Emitter<SpeechTextState> emit,
  ) async {
    try {
      emit(
        InitialingService(
          state.stateUI.copyWith(retryInitCount: event.retryCount),
        ),
      );

      final currentLocaleId = await _speechToTextUsecase.initSpeechToText(
        statusListener: (status) {
          if (kDebugMode) {
            debugPrint('SpeechTextBloc: status $status');
          }
        },
      );

      if (currentLocaleId?.isNotEmpty ?? false) {
        emit(
          InitSucceeded(
            state.stateUI.copyWith(
              currentLocaleId: currentLocaleId,
              stateInit: StateInitSpeechText.succeeded,
            ),
          ),
        );
      } else {
        emit(
          InitFailed(
            state.stateUI.copyWith(
              stateInit: StateInitSpeechText.failed,
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      emit(
        InitFailed(
          state.stateUI.copyWith(
            stateInit: StateInitSpeechText.failed,
          ),
        ),
      );
      _logError('Init speech-to-text failed', error, stackTrace);
    }
  }

  Future<void> _onStartRecord(
    StartRecordEvent event,
    Emitter<SpeechTextState> emit,
  ) async {
    if (!state.stateUI.isInitSuccess) {
      if (!state.stateUI.isCloseFeature) {
        add(
          InitSpeechToTextEvent(
            retryCount: state.stateUI.retryInitCount + 1,
          ),
        );
      } else {
        emit(InitFailed(state.stateUI));
      }
      return;
    }

    try {
      await WakelockPlus.enable();
      await WakelockPlus.toggle(enable: true);

      await _speechToTextUsecase.startSpeak(
        event.callbackToText,
        state.stateUI.currentLocaleId,
        onError: (Object error, StackTrace stackTrace) {
          add(_SpeechPipelineErrorEvent(error, stackTrace));
        },
      );

      _recordingStartedAt = DateTime.now();
      _totalPausedDuration = Duration.zero;
      _pausedAt = null;
      emit(Recording(state.stateUI));
    } catch (error, stackTrace) {
      await WakelockPlus.toggle(enable: false);
      _recordingStartedAt = null;
      emit(RecordError(state.stateUI, error.toString(), error));
      _logError('Start record failed', error, stackTrace);
    }
  }

  Future<void> _onPauseRecord(
    PauseRecordEvent event,
    Emitter<SpeechTextState> emit,
  ) async {
    try {
      await _speechToTextUsecase.pauseRecording();
      _pausedAt ??= DateTime.now();
      emit(PausedRecording(state.stateUI));
    } catch (error, stackTrace) {
      add(_SpeechPipelineErrorEvent(error, stackTrace));
    }
  }

  Future<void> _onResumeRecord(
    ResumeRecordEvent event,
    Emitter<SpeechTextState> emit,
  ) async {
    try {
      await _speechToTextUsecase.resumeRecording();
      if (_pausedAt != null) {
        _totalPausedDuration += DateTime.now().difference(_pausedAt!);
        _pausedAt = null;
      }
      emit(Recording(state.stateUI));
    } catch (error, stackTrace) {
      add(_SpeechPipelineErrorEvent(error, stackTrace));
    }
  }

  Future<void> _onStopRecord(
    StopRecordEvent event,
    Emitter<SpeechTextState> emit,
  ) async {
    if (!state.stateUI.isInitSuccess) {
      return;
    }

    try {
      emit(StopingRecord(state.stateUI));

      final startedAt = _recordingStartedAt;
      final recordedDuration = startedAt != null
          ? DateTime.now().difference(startedAt) - _totalPausedDuration
          : Duration.zero;

      final result = await _speechToTextUsecase.stopSpeak(
        discardRecording: !event.isSave,
      );

      await WakelockPlus.toggle(enable: false);
      _recordingStartedAt = null;
      _totalPausedDuration = Duration.zero;
      _pausedAt = null;

      emit(
        StoppedRecord(
          state.stateUI,
          event.isSave,
          recordedDuration: recordedDuration,
          filePath: event.isSave ? result.recordingPath : null,
          recordingAvailable: result.recordingEnabled,
        ),
      );
    } catch (error, stackTrace) {
      await WakelockPlus.toggle(enable: false);
      _recordingStartedAt = null;
      emit(RecordError(state.stateUI, error.toString(), error));
      _logError('Stop record failed', error, stackTrace);
    }
  }

  Future<void> _onPipelineError(
    _SpeechPipelineErrorEvent event,
    Emitter<SpeechTextState> emit,
  ) async {
    await WakelockPlus.toggle(enable: false);
    _recordingStartedAt = null;
    emit(RecordError(state.stateUI, event.error.toString(), event.error));
    _logError('Speech pipeline error', event.error, event.stackTrace);
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[SpeechTextBloc] $message: $error');
    debugPrint(stackTrace.toString());
  }

  @override
  Future<void> close() async {
    await _speechToTextUsecase.dispose();
    await WakelockPlus.toggle(enable: false);
    return super.close();
  }
}
