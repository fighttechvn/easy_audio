import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

class StopSpeechResult {
  const StopSpeechResult({
    required this.recordingEnabled,
    this.recordingPath,
  });

  final bool recordingEnabled;
  final String? recordingPath;
}

class SpeechToTextUsecase {
  SpeechToTextUsecase({this.local, this.enablePauseResume = true});

  static const String _defaultLocale = 'en-US';

  final String? local;
  final bool enablePauseResume;

  SpeechToTextRecordController? _controller;
  StreamSubscription<SpeechRecognitionResult>? _resultsSubscription;
  bool _isPrepared = false;
  bool _isRunning = false;
  void Function(String)? _onTranscript;
  void Function(Object error, StackTrace stackTrace)? _onError;
  bool _recordingActive = false;
  String? _preparedLocale;

  final List<String> _finalSegments = <String>[];
  String _partialSegment = '';

  /// Get the microphone audio stream for real-time waveform visualization
  MicrophoneAudioStream? get microphoneStream => _controller?.microphoneStream;

  /// Prepare the speech-to-text pipeline.
  Future<String?> initSpeechToText({
    Function(String)? statusListener,
  }) async {
    statusListener?.call('preparing');
    final String targetLocale = _resolveLocale(local);
    try {
      await _ensurePrepared(targetLocale);
      statusListener?.call('ready');
      return targetLocale;
    } on SpeechToTextNotSupportedException catch (error, stackTrace) {
      statusListener?.call('notSupported');
      _logError('Speech recognition not supported', error, stackTrace);
      rethrow;
    } on MicrophonePermissionException catch (error, stackTrace) {
      statusListener?.call('permissionDenied');
      _logError('Microphone permission denied', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      statusListener?.call('error');
      _logError('Failed to initialise speech pipeline', error, stackTrace);
      rethrow;
    }
  }

  /// Start listening and (when available) recording audio at the same time.
  Future<void> startSpeak(
    void Function(String transcript) callback,
    String currentLocaleId, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    final String resolvedLocale = _resolveLocale(currentLocaleId);
    final controller = await _ensurePrepared(resolvedLocale);
    if (_isRunning) {
      await stopSpeak(discardRecording: true);
    }

    _onTranscript = callback;
    _onError = onError;
    _finalSegments.clear();
    _partialSegment = '';

    if (kDebugMode) {
      debugPrint('[SpeechToTextUsecase] start locale: $resolvedLocale');
    }
    await _resultsSubscription?.cancel();
    _resultsSubscription = controller.transcriptions.listen(
      _handleResult,
      onError: _handleStreamError,
      cancelOnError: false,
    );

    final bool startRecordingBeforeStt =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    String? recordingPath;
    var recordingStarted = false;
    _recordingActive = false;

    try {
      Future<void> startRecord() async {
        recordingPath = await _createRecordingPath();
        await controller.startRecordingTo(recordingPath!);
        recordingStarted = true;
      }

      if (startRecordingBeforeStt) {
        await startRecord();
        await controller.start(localeId: resolvedLocale);
      } else if (controller.canRecordWhileListening) {
        await controller.start(localeId: resolvedLocale);
        await startRecord();
      }

      _recordingActive = recordingStarted;
      _isRunning = true;
    } catch (error, stackTrace) {
      if (recordingStarted) {
        try {
          await controller.stopRecording(discard: true);
        } catch (_) {
          // Best-effort cleanup if recording teardown fails.
        }
      }
      await _resultsSubscription?.cancel();
      _resultsSubscription = null;
      _recordingActive = false;
      _isRunning = false;
      _logError('Failed to start speech pipeline', error, stackTrace);
      rethrow;
    }
  }

  /// Stop the active pipeline and optionally discard the recording.
  Future<StopSpeechResult> stopSpeak({
    required bool discardRecording,
  }) async {
    final controller = _controller;
    if (controller == null) {
      return const StopSpeechResult(recordingEnabled: false);
    }

    String? recordedPath;
    final wasRecording = _recordingActive;
    try {
      recordedPath = await controller.stop(
        discardRecording: discardRecording,
      );
    } finally {
      await _resultsSubscription?.cancel();
      _resultsSubscription = null;
      _isRunning = false;
      if (discardRecording) {
        recordedPath = null;
      }
      _onTranscript = null;
      _onError = null;
      _recordingActive = false;
    }

    return StopSpeechResult(
      recordingEnabled:
          wasRecording && !discardRecording && recordedPath != null,
      recordingPath: recordedPath,
    );
  }

  bool get supportsPauseResume {
    // iOS: supported; Android: assume supported via stream-level pause
    return enablePauseResume;
  }

  Future<void> pauseRecording() async {
    if (!enablePauseResume) {
      return;
    }
    await _controller?.pauseRecording();
  }

  Future<void> resumeRecording() async {
    if (!enablePauseResume) {
      return;
    }
    await _controller?.resumeRecording();
  }

  Future<void> dispose() async {
    await _resultsSubscription?.cancel();
    _resultsSubscription = null;
    if (_isRunning) {
      await _controller?.stop(discardRecording: true);
      _isRunning = false;
    }
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
    _isPrepared = false;
    _preparedLocale = null;
  }

  Future<SpeechToTextRecordController> _ensurePrepared(
      [String? localeId]) async {
    final controller = _controller ??= SpeechToTextRecordController();
    final String targetLocale = _resolveLocale(localeId);
    final bool needsReload = !_isPrepared || _preparedLocale != targetLocale;
    if (needsReload) {
      await controller.prepareModel(
        localeId: targetLocale,
        forceReload: _isPrepared && _preparedLocale != targetLocale,
      );
      _isPrepared = true;
      _preparedLocale = targetLocale;
    }
    return controller;
  }

  String _resolveLocale(String? localeId) {
    final String? candidate = localeId ?? local;
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return _defaultLocale;
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (result.isFinal) {
      final text = result.text.trim();
      if (text.isNotEmpty) {
        _finalSegments.add(text);
      }
      _partialSegment = '';
    } else {
      _partialSegment = result.text.trim();
    }
    _emitTranscript();
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    _logError('Speech pipeline error', error, stackTrace);
    final errorHandler = _onError;
    if (errorHandler != null) {
      errorHandler(error, stackTrace);
    }
  }

  void _emitTranscript() {
    final callback = _onTranscript;
    if (callback == null) {
      return;
    }
    final buffer = <String>[
      ..._finalSegments,
      if (_partialSegment.isNotEmpty) _partialSegment,
    ];
    callback(buffer.join(' ').trim());
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[SpeechToTextUsecase] $message: $error');
    debugPrint(stackTrace.toString());
  }

  Future<String> _createRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return defaultRecordingPath(directory.path);
  }
}
