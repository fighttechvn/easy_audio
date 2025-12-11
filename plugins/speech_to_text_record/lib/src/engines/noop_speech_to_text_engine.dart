import 'dart:async';
import 'dart:typed_data';

import '../exceptions.dart';
import '../models/speech_recognition_result.dart';
import 'speech_to_text_engine.dart';

/// Placeholder engine when no concrete speech-to-text backend is available.
class NoOpSpeechToTextEngine extends SpeechToTextEngine {
  NoOpSpeechToTextEngine();

  final StreamController<SpeechRecognitionResult> _controller =
      StreamController<SpeechRecognitionResult>.broadcast();

  @override
  Stream<SpeechRecognitionResult> get results => _controller.stream;

  @override
  bool get isSupported => false;

  @override
  Future<void> prepare({
    String? modelPath,
    String? assetPath,
    String? modelUrl,
    bool forceReload = false,
    String? localeId,
  }) async {
    throw SpeechToTextNotSupportedException();
  }

  @override
  Future<void> start(Stream<Uint8List> audioStream, {String? localeId}) async {
    throw SpeechToTextNotSupportedException();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  bool get isPaused => false;
}
