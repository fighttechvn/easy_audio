import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

import '../../core/services/pending_recording_service.dart';
import '../../core/utils/logs/debug_print/speech_to_text_usecase_log.dart';

class StopSpeechResult {
  const StopSpeechResult({
    required this.recordingEnabled,
    this.recordingPath,
  });

  final bool recordingEnabled;
  final String? recordingPath;
}

/// Configuration for pending recording persistence
class PendingRecordingConfig {
  const PendingRecordingConfig({
    required this.userId,
    this.title,
    this.customData,
    this.enablePersistence = true,
  });

  /// User identifier for this recording session
  final String userId;

  /// Optional title for the recording
  final String? title;

  /// Optional custom data (JSON-encoded) from the app
  /// e.g., appointment ID, patient info, etc.
  final String? customData;

  /// Whether to enable persistence for recovery after app crash
  final bool enablePersistence;
}

class SpeechToTextUsecase {
  SpeechToTextUsecase({
    this.local,
    this.enablePauseResume = true,
    this.pendingRecordingConfig,
  });

  static const String _defaultLocale = 'en-US';

  final String? local;
  final bool enablePauseResume;

  /// Configuration for pending recording persistence.
  /// If provided, the recording session will be tracked and can be
  /// recovered after an unexpected app termination.
  final PendingRecordingConfig? pendingRecordingConfig;

  SpeechToTextRecordController? _controller;
  StreamSubscription<SpeechRecognitionResult>? _resultsSubscription;
  bool _isPrepared = false;
  bool _isRunning = false;
  void Function(String)? _onTranscript;
  void Function(Object error, StackTrace stackTrace)? _onError;
  bool _recordingActive = false;
  String? _preparedLocale;
  String? _currentRecordingPath;
  Timer? _pendingSessionUpdateTimer;

  final List<String> _finalSegments = <String>[];
  String _partialSegment = '';

  /// Get the microphone audio stream for real-time waveform visualization
  MicrophoneAudioStream? get microphoneStream => _controller?.microphoneStream;

  /// Get the current recording file path
  String? get currentRecordingPath => _currentRecordingPath;

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
      debugPrintSpeechRecognitionNotSupported(error, stackTrace);
      rethrow;
    } on MicrophonePermissionException catch (error, stackTrace) {
      statusListener?.call('permissionDenied');
      debugPrintMicrophonePermissionDenied(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      statusListener?.call('error');
      debugPrintFailedToInitialiseSpeechPipeline(error, stackTrace);
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
      debugPrintStartLocale(resolvedLocale);
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
        _currentRecordingPath = recordingPath;
        await controller.startRecordingTo(recordingPath!);
        recordingStarted = true;

        // Start pending recording session if configured
        await _startPendingSession(recordingPath!, resolvedLocale);
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

      // Start periodic pending session updates
      _startPendingSessionUpdateTimer();
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
      _currentRecordingPath = null;

      // Cancel pending session on error
      await _cancelPendingSession();

      debugPrintFailedToStartSpeechPipeline(error, stackTrace);
      rethrow;
    }
  }

  /// Start pending recording session for crash recovery
  Future<void> _startPendingSession(
    String recordingPath,
    String locale,
  ) async {
    final config = pendingRecordingConfig;
    if (config == null || !config.enablePersistence) {
      return;
    }

    try {
      await PendingRecordingService.instance.startSession(
        filePath: recordingPath,
        userId: config.userId,
        locale: locale,
        title: config.title,
        customData: config.customData,
      );
      debugPrintStartedPendingRecordingSession(config.userId);
    } catch (e) {
      debugPrintFailedToStartPendingSession(e);
    }
  }

  /// Start timer to periodically update pending session
  void _startPendingSessionUpdateTimer() {
    _pendingSessionUpdateTimer?.cancel();
    _pendingSessionUpdateTimer = Timer.periodic(
      PendingRecordingService.autoSaveInterval,
      (_) => _updatePendingSession(),
    );
  }

  /// Update the pending session with current transcript and duration
  Future<void> _updatePendingSession() async {
    final config = pendingRecordingConfig;
    if (config == null || !config.enablePersistence) {
      return;
    }

    if (!PendingRecordingService.instance.hasActiveSession) {
      return;
    }

    try {
      // Get current transcript
      final buffer = <String>[
        ..._finalSegments,
        if (_partialSegment.isNotEmpty) _partialSegment,
      ];
      final transcript = buffer.join(' ').trim();

      // Get current duration from audio controller if available
      // For now, we estimate based on session start time
      final session = PendingRecordingService.instance.activeSession;
      final duration = session != null
          ? DateTime.now().difference(session.startedAt)
          : Duration.zero;

      await PendingRecordingService.instance.updateSession(
        transcript: transcript,
        duration: duration,
      );
    } catch (e) {
      debugPrintFailedToUpdatePendingSession(e);
    }
  }

  /// Cancel the pending session (recording was discarded)
  Future<void> _cancelPendingSession() async {
    _pendingSessionUpdateTimer?.cancel();
    _pendingSessionUpdateTimer = null;

    final config = pendingRecordingConfig;
    if (config == null || !config.enablePersistence) {
      return;
    }

    try {
      await PendingRecordingService.instance.cancelSession(deleteFile: false);
      debugPrintCancelledPendingRecordingSession();
    } catch (e) {
      debugPrintFailedToCancelPendingSession(e);
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

      // Handle pending session based on whether recording was saved
      if (discardRecording) {
        await _cancelPendingSession();
      } else if (pendingRecordingConfig?.enablePersistence == true) {
        _pendingSessionUpdateTimer?.cancel();
        _pendingSessionUpdateTimer = null;
        debugPrintPendingRecordingKeptForUpload();
      }
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
      _currentRecordingPath = null;
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
    _pendingSessionUpdateTimer?.cancel();
    _pendingSessionUpdateTimer = null;

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
    _currentRecordingPath = null;
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
    debugPrintSpeechPipelineError(error, stackTrace);
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

  Future<String> _createRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return defaultRecordingPath(directory.path);
  }
}
