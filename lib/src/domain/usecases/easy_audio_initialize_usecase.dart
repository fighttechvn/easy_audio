import 'dart:async';

import 'package:stt_record/stt_record.dart';

import '../../core/controllers/recorder_state_observer.dart';
import '../../core/errors/easy_audio_exception.dart';
import '../entities/easy_audio_config.dart';
import '../entities/easy_audio_service_context.dart';
import '../entities/easy_audio_state.dart';

class EasyAudioInitializeUseCase {
  Future<void> initialize(
    EasyAudioServiceContext ctx, {
    EasyAudioConfig? config,
    required Future<void> Function() onAutoResume,
  }) async {
    if (ctx.isInitialized) {
      return;
    }

    ctx.config = config ?? const EasyAudioConfig();

    ctx.sttRecord = SttRecord();
    _attachRecorderStateListener(ctx, onAutoResume: onAutoResume);

    ctx.isInitialized = true;
    ctx.updateState(EasyAudioState.idle);
  }

  Future<void> updateConfig(
    EasyAudioServiceContext ctx,
    EasyAudioConfig config, {
    required Future<void> Function() reinitialize,
  }) async {
    final isRecording =
        ctx.currentState == EasyAudioState.recording ||
        ctx.currentState == EasyAudioState.paused;

    if (isRecording) {
      throw EasyAudioException.alreadyRecording();
    }

    if (config.mode != ctx.config.mode) {
      ctx.isInitialized = false;
      await reinitialize();
    } else {
      ctx.config = config;
    }
  }

  void _attachRecorderStateListener(
    EasyAudioServiceContext ctx, {
    required Future<void> Function() onAutoResume,
  }) {
    final sttRecord = ctx.sttRecord;
    if (sttRecord == null) {
      return;
    }

    ctx.recorderStateObserver ??= RecorderStateObserver(
      sttRecord: sttRecord,
      getCurrentState: () => ctx.currentState,
      isInitialized: () => ctx.isInitialized,
      pauseRequestedByUser: () => ctx.pauseRequestedByUser,
      resumeRequestedByUser: () => ctx.resumeRequestedByUser,
      autoResumeAfterInterruption: () =>
          ctx.pausedByInterruption && ctx.config.autoResumeAfterInterruption,
      onInterruptedPause: () async {
        ctx.pausedByInterruption = true;

        ctx.amplitudeMonitor?.stop();
        ctx.updateState(EasyAudioState.paused);
      },
      onAutoResumeRequested: onAutoResume,
    );

    ctx.recorderStateObserver!.attach();
  }
}
