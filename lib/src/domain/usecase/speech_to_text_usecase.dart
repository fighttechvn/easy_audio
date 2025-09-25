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
  SpeechToTextUsecase({this.local});

  final String? local;

  SpeechToTextRecordController? _controller;
  StreamSubscription<SpeechRecognitionResult>? _resultsSubscription;
  bool _isPrepared = false;
  bool _isRunning = false;
  void Function(String)? _onTranscript;
  void Function(Object error, StackTrace stackTrace)? _onError;

  final List<String> _finalSegments = <String>[];
  String _partialSegment = '';

  /// Prepare the speech-to-text pipeline.
  Future<String?> initSpeechToText({
    Function(String)? statusListener,
  }) async {
    statusListener?.call('preparing');
    final controller = _controller ??= SpeechToTextRecordController();
    try {
      await controller.prepareModel();
      _isPrepared = true;
      statusListener?.call('ready');
      return local ?? 'en-US';
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
    final controller = await _ensurePrepared();
    if (_isRunning) {
      await stopSpeak(discardRecording: true);
    }

    _onTranscript = callback;
    _onError = onError;
    _finalSegments.clear();
    _partialSegment = '';

    if (kDebugMode) {
      debugPrint('[SpeechToTextUsecase] start locale: $currentLocaleId');
    }
    await _resultsSubscription?.cancel();
    _resultsSubscription = controller.transcriptions.listen(
      _handleResult,
      onError: _handleStreamError,
      cancelOnError: false,
    );

    try {
      await controller.start();
      if (controller.canRecordWhileListening) {
        final directory = await getApplicationDocumentsDirectory();
        final recordingPath = defaultRecordingPath(directory.path);
        await controller.startRecordingTo(recordingPath);
      }
      _isRunning = true;
    } catch (error, stackTrace) {
      await _resultsSubscription?.cancel();
      _resultsSubscription = null;
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
    }

    return StopSpeechResult(
      recordingEnabled: !discardRecording && recordedPath != null,
      recordingPath: recordedPath,
    );
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
  }

  Future<SpeechToTextRecordController> _ensurePrepared() async {
    final controller = _controller ??= SpeechToTextRecordController();
    if (!_isPrepared) {
      await controller.prepareModel();
      _isPrepared = true;
    }
    return controller;
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
}
