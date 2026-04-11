import 'dart:async';

import 'package:audio_session/audio_session.dart';

import '../../core/controllers/amplitude_monitor.dart';
import '../../core/controllers/speech_recognition_controller.dart';
import '../../core/errors/easy_audio_exception.dart';
import '../../core/utils/easy_audio_cache_info.dart';
import '../../core/utils/easy_audio_paths.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/permission_guards.dart';
import '../../core/utils/record_config_factory.dart';
import '../entities/easy_audio_mode.dart';
import '../entities/easy_audio_service_context.dart';
import '../entities/easy_audio_state.dart';
import '../entities/recording_result.dart';

class EasyAudioRecordingUseCase {
  Future<void> start(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    final isRecording = ctx.currentState == EasyAudioState.recording ||
        ctx.currentState == EasyAudioState.paused;

    if (isRecording) {
      throw EasyAudioException.alreadyRecording();
    }

    await PermissionGuards.ensureCanStart(
      mode: ctx.config.mode,
      recorder: ctx.recorder!,
      speechAvailable: ctx.speechAvailable,
    );

    ctx.updateState(EasyAudioState.initializing);
    ctx.recordingStartTime = DateTime.now();
    ctx.transcriptBuffer.clear();
    ctx.speechRecognition?.resetCommittedTranscript();
    ctx.pausedByInterruption = false;

    try {
      if (ctx.config.mode != EasyAudioMode.speechToTextOnly) {
        ctx.currentFilePath = await EasyAudioPaths.generateFilePath(ctx.config);

        final recordPath = ctx.currentFilePath!;

        await ctx.recorder!.start(
          RecordConfigFactory.build(ctx.config),
          path: recordPath,
        );
        if (ctx.config.enableCrashRecovery) {
          await EasyAudioCacheInfo.save(
            config: ctx.config,
            recordingStartTime: ctx.recordingStartTime,
            cachePath: recordPath,
            targetPath: recordPath,
          );
        }
        _startAmplitudeMonitoring(ctx);
      }

      if (ctx.config.mode != EasyAudioMode.recordOnly && ctx.speechAvailable) {
        await _startSpeechRecognition(ctx);
      }

      if (ctx.config.maxDuration != null) {
        ctx.maxDurationTimer = Timer(ctx.config.maxDuration!, () {
          unawaited(stop(ctx));
        });
      }

      ctx.updateState(EasyAudioState.recording);
    } catch (e, stack) {
      ctx.updateState(EasyAudioState.error);
      throw EasyAudioException.unknown(e, stack);
    }
  }

  Future<void> pause(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    if (ctx.currentState != EasyAudioState.recording) {
      throw EasyAudioException.notRecording();
    }

    try {
      ctx.pauseRequestedByUser = true;
      if (ctx.config.mode != EasyAudioMode.speechToTextOnly) {
        await ctx.recorder!.pause();
      }

      if (ctx.config.mode != EasyAudioMode.recordOnly) {
        await ctx.speechRecognition?.stop();
      }

      _stopAmplitudeMonitoring(ctx);
      ctx.updateState(EasyAudioState.paused);
    } catch (e, stack) {
      throw EasyAudioException.unknown(e, stack);
    } finally {
      ctx.pauseRequestedByUser = false;
    }
  }

  Future<void> resume(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    if (ctx.currentState != EasyAudioState.paused) {
      throw const EasyAudioException(
        code: 'NOT_PAUSED',
        message: 'Recording is not paused.',
      );
    }

    try {
      ctx.resumeRequestedByUser = true;
      if (ctx.config.mode != EasyAudioMode.speechToTextOnly) {
        await ctx.recorder!.resume();
        _startAmplitudeMonitoring(ctx);
      }

      if (ctx.config.mode != EasyAudioMode.recordOnly && ctx.speechAvailable) {
        await _startSpeechRecognition(ctx);
      }

      ctx.pausedByInterruption = false;
      ctx.updateState(EasyAudioState.recording);
    } catch (e, stack) {
      throw EasyAudioException.unknown(e, stack);
    } finally {
      ctx.resumeRequestedByUser = false;
    }
  }

  Future<RecordingResult> stop(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    final isRecording = ctx.currentState == EasyAudioState.recording ||
        ctx.currentState == EasyAudioState.paused;

    if (!isRecording) {
      throw EasyAudioException.notRecording();
    }

    ctx.updateState(EasyAudioState.processing);
    _stopAmplitudeMonitoring(ctx);
    ctx.maxDurationTimer?.cancel();

    final endTime = DateTime.now();
    String? finalPath;
    int? fileSize;

    try {
      if (ctx.config.mode != EasyAudioMode.recordOnly) {
        await ctx.speechRecognition?.stop();

        try {
          await ctx.speechToText?.cancel();
        } catch (_) {}
      }

      if (ctx.config.mode != EasyAudioMode.speechToTextOnly) {
        final path = await ctx.recorder!.stop();

        finalPath = path;

        fileSize = await FileUtils.safeLength(finalPath);

        await EasyAudioCacheInfo.clear();
      }

      final result = RecordingResult(
        filePath: finalPath,
        duration: endTime.difference(ctx.recordingStartTime!),
        transcript: ctx.transcriptBuffer.toString().trim(),
        wasRecovered: false,
        startTime: ctx.recordingStartTime!,
        endTime: endTime,
        fileSizeBytes: fileSize,
        localeId: ctx.config.locale,
      );

      _cleanup(ctx);
      ctx.pausedByInterruption = false;
      ctx.updateState(EasyAudioState.idle);

      return result;
    } catch (e, stack) {
      _cleanup(ctx);
      ctx.pausedByInterruption = false;
      ctx.updateState(EasyAudioState.error);
      throw EasyAudioException.unknown(e, stack);
    } finally {
      await _deactivateAudioSession();
    }
  }

  Future<void> cancel(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    final isRecording = ctx.currentState == EasyAudioState.recording ||
        ctx.currentState == EasyAudioState.paused;

    if (!isRecording && ctx.currentState != EasyAudioState.processing) {
      return;
    }

    _stopAmplitudeMonitoring(ctx);
    ctx.maxDurationTimer?.cancel();

    try {
      if (ctx.config.mode != EasyAudioMode.recordOnly) {
        await ctx.speechRecognition?.stop();

        try {
          await ctx.speechToText?.cancel();
        } catch (_) {}
      }

      if (ctx.config.mode != EasyAudioMode.speechToTextOnly) {
        await ctx.recorder!.cancel();

        await FileUtils.safeDelete(ctx.currentFilePath);
        await EasyAudioCacheInfo.clear();
      }
    } finally {
      _cleanup(ctx);
      ctx.pausedByInterruption = false;
      ctx.updateState(EasyAudioState.idle);

      await _deactivateAudioSession();
    }
  }

  Future<void> _startSpeechRecognition(EasyAudioServiceContext ctx) async {
    final speechToText = ctx.speechToText;
    if (speechToText == null) {
      return;
    }

    ctx.speechRecognition ??= SpeechRecognitionController(
      speechToText: speechToText,
      transcriptController: ctx.transcriptController,
      transcriptBuffer: ctx.transcriptBuffer,
      getCurrentState: () => ctx.currentState,
      isSpeechAvailable: () => ctx.speechAvailable,
    );

    await ctx.speechRecognition!.start(localeId: ctx.config.locale);
  }

  void _startAmplitudeMonitoring(EasyAudioServiceContext ctx) {
    final recorder = ctx.recorder;
    if (recorder == null) {
      return;
    }

    ctx.amplitudeMonitor ??= AmplitudeMonitor(
      recorder: recorder,
      onAmplitude: (normalized) {
        if (!ctx.amplitudeController.isClosed) {
          ctx.amplitudeController.add(normalized);
        }
      },
    );

    ctx.amplitudeMonitor!.start();
  }

  void _stopAmplitudeMonitoring(EasyAudioServiceContext ctx) {
    ctx.amplitudeMonitor?.stop();
  }

  void _cleanup(EasyAudioServiceContext ctx) {
    ctx.recordingStartTime = null;
    ctx.currentFilePath = null;
    ctx.transcriptBuffer.clear();
    ctx.maxDurationTimer?.cancel();
    ctx.maxDurationTimer = null;
  }

  Future<void> _deactivateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}
  }
}
