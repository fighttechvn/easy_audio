import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/controllers/recorder_state_observer.dart';
import '../../core/errors/easy_audio_exception.dart';
import '../../core/utils/speech_to_text_utils.dart';
import '../entities/easy_audio_config.dart';
import '../entities/easy_audio_mode.dart';
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

    ctx.recorder = AudioRecorder();
    _attachRecorderStateListener(ctx, onAutoResume: onAutoResume);
    _attachAudioInterruptionListener(ctx, onAutoResume: onAutoResume);

    if (ctx.config.mode != EasyAudioMode.recordOnly) {
      ctx.speechToText = SpeechToText();
      ctx.speechAvailable = await SpeechToTextUtils.ensureInitialized(
        ctx.speechToText!,
      );

      if (!ctx.speechAvailable &&
          ctx.config.mode == EasyAudioMode.speechToTextOnly) {
        throw EasyAudioException.speechNotAvailable();
      }
    }

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

  Future<void> handleAudioInterruptionEvent(
    EasyAudioServiceContext ctx,
    AudioInterruptionEvent event, {
    required Future<void> Function() onAutoResume,
  }) async {
    if (!ctx.isInitialized) {
      return;
    }
    if (!ctx.config.pauseOnInterruption) {
      return;
    }

    if (event.begin) {
      if (ctx.currentState != EasyAudioState.recording) {
        return;
      }

      ctx.pausedByInterruption = true;

      try {
        if (ctx.config.mode != EasyAudioMode.speechToTextOnly) {
          await ctx.recorder?.pause();
        }
      } catch (_) {}

      try {
        if (ctx.config.mode != EasyAudioMode.recordOnly) {
          await ctx.speechRecognition?.stop();
        }
      } catch (_) {}

      ctx.amplitudeMonitor?.stop();
      ctx.updateState(EasyAudioState.paused);
      return;
    }

    if (ctx.pausedByInterruption &&
        ctx.config.autoResumeAfterInterruption &&
        ctx.currentState == EasyAudioState.paused) {
      try {
        await onAutoResume();
      } catch (_) {}
    }
  }

  void _attachAudioInterruptionListener(
    EasyAudioServiceContext ctx, {
    required Future<void> Function() onAutoResume,
  }) {
    if (ctx.audioInterruptionSub != null) {
      return;
    }

    try {
      unawaited(
        AudioSession.instance.then((session) {
          ctx.audioInterruptionSub = session.interruptionEventStream.listen((
            event,
          ) {
            unawaited(
              handleAudioInterruptionEvent(
                ctx,
                event,
                onAutoResume: onAutoResume,
              ),
            );
          }, onError: (_) {});
        }),
      );
    } catch (_) {}
  }

  void _attachRecorderStateListener(
    EasyAudioServiceContext ctx, {
    required Future<void> Function() onAutoResume,
  }) {
    final recorder = ctx.recorder;
    if (recorder == null) {
      return;
    }

    ctx.recorderStateObserver ??= RecorderStateObserver(
      recorder: recorder,
      getCurrentState: () => ctx.currentState,
      isInitialized: () => ctx.isInitialized,
      pauseRequestedByUser: () => ctx.pauseRequestedByUser,
      resumeRequestedByUser: () => ctx.resumeRequestedByUser,
      pauseOnInterruption: () => ctx.config.pauseOnInterruption,
      autoResumeAfterInterruption: () =>
          ctx.pausedByInterruption && ctx.config.autoResumeAfterInterruption,
      onInterruptedPause: () async {
        ctx.pausedByInterruption = true;

        try {
          if (ctx.config.mode != EasyAudioMode.recordOnly) {
            await ctx.speechRecognition?.stop();
          }
        } catch (_) {}

        ctx.amplitudeMonitor?.stop();
        ctx.updateState(EasyAudioState.paused);
      },
      onAutoResumeRequested: onAutoResume,
    );

    ctx.recorderStateObserver!.attach();
  }
}
