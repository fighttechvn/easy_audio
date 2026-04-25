import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

import '../../core/controllers/amplitude_monitor.dart';
import '../../core/controllers/speech_recognition_controller.dart';
import '../../core/errors/easy_audio_exception.dart';
import '../../core/utils/easy_audio_cache_info.dart';
import '../../core/utils/easy_audio_paths.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/permission_guards.dart';
import '../entities/easy_audio_mode.dart';
import '../entities/easy_audio_service_context.dart';
import '../entities/easy_audio_state.dart';
import '../entities/recording_result.dart';

class EasyAudioRecordingUseCase {
  Future<void> start(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    final sttRecord = ctx.sttRecord;
    if (sttRecord == null) {
      throw EasyAudioException.notInitialized();
    }

    final isRecording =
        ctx.currentState == EasyAudioState.recording ||
        ctx.currentState == EasyAudioState.paused;

    if (isRecording) {
      throw EasyAudioException.alreadyRecording();
    }

    await PermissionGuards.ensureCanStart(
      mode: ctx.config.mode,
      sttRecord: sttRecord,
    );

    ctx.updateState(EasyAudioState.initializing);
    ctx.recordingStartTime = DateTime.now();
    ctx.transcriptBuffer.clear();
    ctx.speechRecognition?.resetCommittedTranscript();
    ctx.pausedByInterruption = false;

    try {
      if (ctx.config.mode != EasyAudioMode.speechToTextOnly) {
        ctx.currentFilePath = await EasyAudioPaths.generateFilePath(ctx.config);

        if (ctx.config.enableCrashRecovery && ctx.currentFilePath != null) {
          final targetPath = ctx.currentFilePath!;
          await EasyAudioCacheInfo.save(
            config: ctx.config,
            recordingStartTime: ctx.recordingStartTime,
            cachePath: targetPath,
            targetPath: targetPath,
          );
        }
      }

      final localeId = (ctx.config.locale ?? 'vi-VN').trim();
      await sttRecord.start(
        localeId: localeId.isEmpty ? 'vi-VN' : localeId,
        partialResults: ctx.config.mode != EasyAudioMode.recordOnly,
        enableSystemNotification: true,
        enableSystemNotificationActionPause: false,
        enableSystemNotificationActionStop: false,
      );

      if (ctx.config.mode != EasyAudioMode.speechToTextOnly) {
        _startAmplitudeMonitoring(ctx);
      }

      if (ctx.config.mode != EasyAudioMode.recordOnly) {
        await _startSpeechRecognition(ctx);
      }

      if (ctx.config.maxDuration != null) {
        ctx.maxDurationTimer = Timer(ctx.config.maxDuration!, () {
          unawaited(stop(ctx));
        });
      }

      ctx.updateState(EasyAudioState.recording);
    } catch (e, stack) {
      if (kDebugMode) {
        print(e);
        print(stack);
      }

      ctx.updateState(EasyAudioState.error);
      throw EasyAudioException.unknown(e, stack);
    }
  }

  Future<void> pause(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    final sttRecord = ctx.sttRecord;
    if (sttRecord == null) {
      throw EasyAudioException.notInitialized();
    }

    if (ctx.currentState != EasyAudioState.recording) {
      throw EasyAudioException.notRecording();
    }

    try {
      ctx.pauseRequestedByUser = true;

      await sttRecord.pause();

      if (ctx.config.mode != EasyAudioMode.recordOnly) {
        await ctx.speechRecognition?.stop();
      }

      _stopAmplitudeMonitoring(ctx);
      ctx.updateState(EasyAudioState.paused);
    } catch (e, stack) {
      if (kDebugMode) {
        print(e);
        print(stack);
      }

      throw EasyAudioException.unknown(e, stack);
    } finally {
      ctx.pauseRequestedByUser = false;
    }
  }

  Future<void> resume(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    final sttRecord = ctx.sttRecord;
    if (sttRecord == null) {
      throw EasyAudioException.notInitialized();
    }

    if (ctx.currentState != EasyAudioState.paused) {
      throw const EasyAudioException(
        code: 'NOT_PAUSED',
        message: 'Recording is not paused.',
      );
    }

    try {
      ctx.resumeRequestedByUser = true;
      await sttRecord.resume();

      if (ctx.config.mode != EasyAudioMode.speechToTextOnly) {
        _startAmplitudeMonitoring(ctx);
      }

      if (ctx.config.mode != EasyAudioMode.recordOnly) {
        await _startSpeechRecognition(ctx);
      }

      ctx.pausedByInterruption = false;
      ctx.updateState(EasyAudioState.recording);
    } catch (e, stack) {
      if (kDebugMode) {
        print(e);
        print(stack);
      }
      throw EasyAudioException.unknown(e, stack);
    } finally {
      ctx.resumeRequestedByUser = false;
    }
  }

  Future<RecordingResult> stop(EasyAudioServiceContext ctx) async {
    ctx.ensureInitialized();

    final sttRecord = ctx.sttRecord;
    if (sttRecord == null) {
      throw EasyAudioException.notInitialized();
    }

    final isRecording =
        ctx.currentState == EasyAudioState.recording ||
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
      }

      final stopResult = await sttRecord.stop();
      final tempPath = stopResult.audioPath;

      if (ctx.config.mode == EasyAudioMode.speechToTextOnly) {
        await FileUtils.safeDelete(tempPath);
        finalPath = null;
        fileSize = null;
      } else {
        final targetPath = ctx.currentFilePath;
        if (targetPath != null && targetPath.isNotEmpty) {
          await _moveFile(tempPath, targetPath);
          finalPath = targetPath;
        } else {
          finalPath = tempPath;
        }

        fileSize = await FileUtils.safeLength(finalPath);
        await EasyAudioCacheInfo.clear();
      }
      // final transcriptText = await ctx.currentState.
      // print(transcriptText.text);
      final text = ctx.transcriptBuffer.toString().trim();
      final DateTime? startTime = ctx.recordingStartTime;

      if (kDebugMode) {
        print('[EasyAudioRecordUsecase] startTime: $startTime');
        print('[EasyAudioRecordUsecase] text: $text');
      }

      if (startTime == null) {
        throw Exception('Nedd check startTime');
      }

      final result = RecordingResult(
        filePath: finalPath,
        duration: endTime.difference(startTime),
        transcript: text,
        wasRecovered: false,
        startTime: startTime,
        endTime: endTime,
        fileSizeBytes: fileSize,
        localeId: ctx.config.locale,
      );

      _cleanup(ctx);
      ctx.pausedByInterruption = false;
      ctx.updateState(EasyAudioState.idle);

      return result;
    } catch (e, stack) {
      if (kDebugMode) {
        print(e);
        print(stack);
      }
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

    final sttRecord = ctx.sttRecord;
    if (sttRecord == null) {
      throw EasyAudioException.notInitialized();
    }

    final isRecording =
        ctx.currentState == EasyAudioState.recording ||
        ctx.currentState == EasyAudioState.paused;

    if (!isRecording && ctx.currentState != EasyAudioState.processing) {
      return;
    }

    _stopAmplitudeMonitoring(ctx);
    ctx.maxDurationTimer?.cancel();

    try {
      if (ctx.config.mode != EasyAudioMode.recordOnly) {
        await ctx.speechRecognition?.stop();
      }

      await sttRecord.cancel();

      await FileUtils.safeDelete(ctx.currentFilePath);
      await EasyAudioCacheInfo.clear();
    } finally {
      _cleanup(ctx);
      ctx.pausedByInterruption = false;
      ctx.updateState(EasyAudioState.idle);

      await _deactivateAudioSession();
    }
  }

  Future<void> _startSpeechRecognition(EasyAudioServiceContext ctx) async {
    final sttRecord = ctx.sttRecord;
    if (sttRecord == null) {
      return;
    }

    ctx.speechRecognition ??= SpeechRecognitionController(
      sttRecord: sttRecord,
      transcriptController: ctx.transcriptController,
      transcriptBuffer: ctx.transcriptBuffer,
    );

    await ctx.speechRecognition!.start();
  }

  void _startAmplitudeMonitoring(EasyAudioServiceContext ctx) {
    final sttRecord = ctx.sttRecord;
    if (sttRecord == null) {
      return;
    }

    ctx.amplitudeMonitor ??= AmplitudeMonitor(
      sttRecord: sttRecord,
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

  Future<void> _moveFile(String fromPath, String toPath) async {
    if (fromPath.isEmpty || toPath.isEmpty || fromPath == toPath) {
      return;
    }

    final source = File(fromPath);
    if (!await source.exists()) {
      return;
    }

    final target = File(toPath);
    await target.parent.create(recursive: true);

    try {
      await source.rename(toPath);
    } on FileSystemException {
      await source.copy(toPath);
      await source.delete();
    }
  }
}
