import 'dart:async';
import 'dart:typed_data';

import 'audio_file_sink.dart';
import 'engines/speech_to_text_engine.dart';
import 'engines/speech_to_text_engine_factory.dart';
import 'exceptions.dart';
import 'microphone_audio_stream.dart';
import 'models/speech_recognition_result.dart';

/// Facade that coordinates microphone capture, transcription,
/// and optional file recording.
class SpeechToTextRecordController {
  SpeechToTextRecordController({
    this.sampleRate = 16000,
    this.numChannels = 1,
    SpeechToTextEngine? engine,
    Iterable<String>? preloadLocales,
  })  : _microphone = MicrophoneAudioStream(
          sampleRate: sampleRate,
          numChannels: numChannels,
        ),
        _sttEngine = engine ??
            SpeechToTextEngineFactory.createDefault(
              sampleRate: sampleRate,
              preloadLocales: preloadLocales,
            ) {
    _fileSink = AudioFileSink(
      stream: _microphone.stream,
      sampleRate: sampleRate,
      numChannels: numChannels,
    );
  }

  final int sampleRate;
  final int numChannels;

  final MicrophoneAudioStream _microphone;
  final SpeechToTextEngine _sttEngine;
  late final AudioFileSink _fileSink;
  bool _isSttActive = false;

  Stream<Uint8List> get audioStream => _microphone.stream;
  Stream<SpeechRecognitionResult> get transcriptions => _sttEngine.results;

  /// Get the microphone audio stream for real-time waveform visualization
  MicrophoneAudioStream get microphoneStream => _microphone;

  bool get isPipelineRunning => _microphone.isStarted || _isSttActive;
  bool get isRecording => _fileSink.isRecording;
  bool get isPaused => _fileSink.isPaused;
  bool get isSpeechToTextSupported => _sttEngine.isSupported;
  bool get canRecordWhileListening => _sttEngine.requiresExternalAudioStream;
  bool get supportsPauseResume => true;

  /// Prepare STT resources. Must be called before [start].
  Future<void> prepareModel({
    String? modelPath,
    String? assetPath,
    String? modelUrl,
    bool forceReload = false,
    String? localeId,
  }) async {
    await _sttEngine.prepare(
      modelPath: modelPath,
      assetPath: assetPath,
      modelUrl: modelUrl,
      forceReload: forceReload,
      localeId: localeId,
    );
  }

  /// Start the unified audio pipeline using [localeId] when the engine
  /// supports language selection.
  Future<void> start({String? localeId}) async {
    if (_sttEngine.requiresExternalAudioStream && !_microphone.isStarted) {
      await _microphone.start();
    }
    if (_sttEngine.isSupported) {
      await _sttEngine.start(
        _sttEngine.requiresExternalAudioStream
            ? _microphone.stream
            : Stream<Uint8List>.empty(),
        localeId: localeId,
      );
      _isSttActive = true;
    }
  }

  /// Stop all active processing. Returns the path of the last recording
  /// (if any).
  Future<String?> stop({bool discardRecording = false}) async {
    final recordedPath = await _fileSink.stop(deleteOnCancel: discardRecording);
    if (_sttEngine.isSupported) {
      await _sttEngine.stop();
      _isSttActive = false;
    }
    if (_microphone.isStarted) {
      await _microphone.stop();
    }
    return recordedPath;
  }

  /// Start persisting microphone frames to disk.
  Future<void> startRecordingTo(String filePath) async {
    if (!canRecordWhileListening && _isSttActive) {
      throw AudioPipelineStateException(
        'Recording is unavailable while speech recognition is active on this platform.',
      );
    }
    if (!_microphone.isStarted) {
      if (_sttEngine.requiresExternalAudioStream) {
        throw AudioPipelineStateException(
          'Call start() before starting a file recording.',
        );
      }
      await _microphone.start();
    }
    await _fileSink.start(filePath);
  }

  /// Stop recording and return the saved file path.
  Future<String?> stopRecording({bool discard = false}) async {
    final path = await _fileSink.stop(deleteOnCancel: discard);
    if (!_sttEngine.requiresExternalAudioStream && !_isSttActive) {
      await _microphone.stop();
    }
    return path;
  }

  /// Pause persisting audio data to file while keeping the pipeline running.
  void pauseRecording() {
    _sttEngine.pause();
    _fileSink.pause();
  }

  /// Resume persisting audio data to file after a pause.
  void resumeRecording() {
    _sttEngine.resume();
    _fileSink.resume();
  }

  Future<void> dispose() async {
    await _fileSink.dispose();
    await _sttEngine.dispose();
    await _microphone.dispose();
  }
}
