import 'dart:async';
import 'dart:io' show Platform;

import 'package:path_provider/path_provider.dart';

import '../audio_file_sink.dart';
import '../constants/vosk_model.dart';
import '../models/speech_recognition_result.dart';
import '../speech_to_text_record_controller.dart';

/// Provides a one-call experience to start speech-to-text and recording
/// simultaneously when supported by the platform.
class SpeechToTextRecord {
  const SpeechToTextRecord._();

  /// Start speech recognition (and recording when possible) with a single call.
  ///
  /// If [onResult] is provided, it will receive partial and final results. Any
  /// errors raised by the transcription stream are forwarded to [onError].
  ///
  /// The returned [SpeechToTextRecordSession] exposes the transcription stream
  /// and a [stop] method to end the pipeline and obtain the path to the
  /// recording, if any. On platforms that do not allow simultaneous recording
  /// (e.g., iOS), recording is started before speech recognition and
  /// [SpeechToTextRecordSession.recordingEnabled] reflects whether that step
  /// succeeded.
  ///
  /// [localeId] controls the speech recognition language and defaults to
  /// English (United States).
  static Future<SpeechToTextRecordSession> startCombined({
    int sampleRate = 16000,
    int numChannels = 1,
    String? recordingPath,
    String localeId = RecordLanguage.defaultLocale,
    Iterable<String>? preloadLocales,
    void Function(SpeechRecognitionResult result)? onResult,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    final controller = SpeechToTextRecordController(
      sampleRate: sampleRate,
      numChannels: numChannels,
      preloadLocales: preloadLocales,
    );
    await controller.prepareModel(localeId: localeId);

    String? path;
    var recordingEnabled = false;
    StreamSubscription<SpeechRecognitionResult>? subscription;
    final startRecordingBeforeStt = Platform.isIOS;
    var recordingStarted = false;

    try {
      if (startRecordingBeforeStt) {
        final targetPath =
            recordingPath ?? path ?? await _generateRecordingPath();
        path = targetPath;
        await controller.startRecordingTo(targetPath);
        recordingStarted = true;
        recordingEnabled = true;
      }

      await controller.start(localeId: localeId);

      if (onResult != null) {
        subscription = controller.transcriptions.listen(
          onResult,
          onError: onError,
        );
      }

      if (!startRecordingBeforeStt && controller.canRecordWhileListening) {
        final targetPath =
            recordingPath ?? path ?? await _generateRecordingPath();
        path = targetPath;
        await controller.startRecordingTo(targetPath);
        recordingStarted = true;
        recordingEnabled = true;
      }
    } catch (error, stackTrace) {
      if (recordingStarted) {
        try {
          await controller.stopRecording(discard: true);
        } catch (_) {
          // Best-effort cleanup if stopping the recorder throws.
        }
      }
      await subscription?.cancel();
      await controller.dispose();
      Error.throwWithStackTrace(error, stackTrace);
    }

    return SpeechToTextRecordSession._(
      controller: controller,
      resultsSubscription: subscription,
      recordingPath: path,
      recordingEnabled: recordingEnabled,
    );
  }

  static Future<String> _generateRecordingPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return defaultRecordingPath(directory.path);
  }
}

/// Handle for an active combined speech-to-text and recording session.
class SpeechToTextRecordSession {
  SpeechToTextRecordSession._({
    required SpeechToTextRecordController controller,
    StreamSubscription<SpeechRecognitionResult>? resultsSubscription,
    required this.recordingPath,
    required this.recordingEnabled,
  })  : _controller = controller,
        _resultsSubscription = resultsSubscription;

  final SpeechToTextRecordController _controller;
  final StreamSubscription<SpeechRecognitionResult>? _resultsSubscription;
  final bool recordingEnabled;
  final String? recordingPath;

  bool _stopped = false;
  String? _lastRecordedPath;

  /// Stream of transcription results from the active session.
  Stream<SpeechRecognitionResult> get results => _controller.transcriptions;

  /// Stop the pipeline and optionally discard the recording. Returns the path
  /// to the recording if one exists.
  Future<String?> stop({bool discardRecording = false}) async {
    if (_stopped) {
      return _lastRecordedPath;
    }
    await _resultsSubscription?.cancel();
    _lastRecordedPath = await _controller.stop(
      discardRecording: discardRecording,
    );
    _stopped = true;
    return _lastRecordedPath;
  }

  /// Dispose associated resources. If [stop] wasn't called this will stop the
  /// pipeline and discard any recording.
  Future<void> dispose() async {
    await _resultsSubscription?.cancel();
    if (!_stopped) {
      await _controller.stop(discardRecording: true);
    }
    await _controller.dispose();
  }
}
