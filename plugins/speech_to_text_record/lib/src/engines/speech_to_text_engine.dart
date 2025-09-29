import 'dart:async';
import 'dart:typed_data';

import '../models/speech_recognition_result.dart';

/// Abstraction for a speech-to-text engine consuming a microphone broadcast.
abstract class SpeechToTextEngine {
  const SpeechToTextEngine();

  /// Stream of incremental transcription results.
  Stream<SpeechRecognitionResult> get results;

  /// Whether the engine can operate on the current platform.
  bool get isSupported;

  /// Whether the engine expects microphone PCM to be provided externally
  /// through [start]'s audio stream.
  bool get requiresExternalAudioStream => true;

  /// Prepare underlying resources (models, network connections, etc.).
  Future<void> prepare({
    String? modelPath,
    String? assetPath,
    String? modelUrl,
    bool forceReload = false,
    String? localeId,
  });

  /// Begin consuming audio from the broadcast stream.
  Future<void> start(Stream<Uint8List> audioStream, {String? localeId});

  /// Stop consuming audio and flush any pending results.
  Future<void> stop();

  /// Reset current recognition session without tearing down resources.
  Future<void> reset();

  /// Release resources held by the engine.
  Future<void> dispose();
}
