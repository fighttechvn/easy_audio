import 'dart:async';

import '../constants/vosk_model.dart';
import '../models/speech_recognition_result.dart';
import '../speech_to_text_record_controller.dart';

/// Lightweight facade for running speech-to-text without dealing with the
/// recording APIs.
class SpeechToTextService {
  SpeechToTextService({
    this.sampleRate = 16000,
    this.numChannels = 1,
    Iterable<String>? preloadLocales,
  }) : _controller = SpeechToTextRecordController(
          sampleRate: sampleRate,
          numChannels: numChannels,
          preloadLocales: preloadLocales,
        );

  final int sampleRate;
  final int numChannels;
  final SpeechToTextRecordController _controller;

  bool _prepared = false;

  Stream<SpeechRecognitionResult> get results => _controller.transcriptions;
  bool get isSupported => _controller.isSpeechToTextSupported;
  bool get isActive => _controller.isPipelineRunning;

  Future<void> prepare({
    String? modelPath,
    String? assetPath,
    String? modelUrl,
    bool forceReload = false,
    String? localeId,
  }) async {
    if (_prepared && !forceReload) {
      return;
    }
    await _controller.prepareModel(
      modelPath: modelPath,
      assetPath: assetPath,
      modelUrl: modelUrl,
      forceReload: forceReload,
      localeId: localeId,
    );
    _prepared = true;
  }

  /// Start listening for speech using [localeId] to select the recognition
  /// language. Defaults to English (United States) when not provided.
  Future<void> start({String? localeId}) async {
    if (!_prepared) {
      await prepare();
    }
    await _controller.start(
      localeId: localeId ?? RecordLanguage.defaultLocale,
    );
  }

  Future<void> stop() async {
    await _controller.stop(discardRecording: true);
  }

  Future<void> dispose() async {
    await _controller.dispose();
  }
}
