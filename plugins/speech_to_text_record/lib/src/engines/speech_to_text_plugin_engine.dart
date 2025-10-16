import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart' as stt_error;
import 'package:speech_to_text/speech_recognition_result.dart' as stt_result;
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../exceptions.dart';
import '../models/speech_recognition_result.dart';
import 'speech_to_text_engine.dart';

/// Wraps the `speech_to_text` plugin for platforms where microphone sharing
/// is not supported (iOS, macOS).
class SpeechToTextPluginEngine extends SpeechToTextEngine {
  SpeechToTextPluginEngine()
      : _speech = stt.SpeechToText(),
        _resultsController =
            StreamController<SpeechRecognitionResult>.broadcast();

  final stt.SpeechToText _speech;
  final StreamController<SpeechRecognitionResult> _resultsController;

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isPaused = false;

  @override
  Stream<SpeechRecognitionResult> get results => _resultsController.stream;

  @override
  bool get isPaused => _isPaused;

  @override
  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  bool get requiresExternalAudioStream => false;

  @override
  Future<void> prepare({
    String? modelPath,
    String? assetPath,
    String? modelUrl,
    bool forceReload = false,
    String? localeId,
  }) async {
    if (!isSupported) {
      throw SpeechToTextNotSupportedException();
    }
    if (_isInitialized && !forceReload) {
      return;
    }

    final available = await _speech.initialize(
      onError: (stt_error.SpeechRecognitionError error) {
        if (!_resultsController.isClosed) {
          _resultsController.addError(
            PlatformException(
              code: error.errorMsg,
              message: error.errorMsg,
              details: error,
            ),
          );
        }
      },
      onStatus: (String status) {
        if (status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) {
          _isListening = false;
        }
      },
    );

    if (!available) {
      throw SpeechToTextNotSupportedException(
        'Speech recognition services are unavailable on this device',
      );
    }

    _isInitialized = true;
  }

  String? _normalizedLocale;
  String _cacheValue = '';
  String _sessionValue = '';
  @override
  Future<void> start(Stream<Uint8List> audioStream, {String? localeId}) async {
    if (!isSupported) {
      throw SpeechToTextNotSupportedException();
    }
    if (!_isInitialized) {
      await prepare();
    }
    if (_isListening) {
      return;
    }

    _normalizedLocale = localeId?.replaceAll('-', '_');

    // if (!success) {
    //   throw AudioPipelineStateException('Failed to start speech recognition');
    // }
    unawaited(_listen());
  }

  void _stopListening() async {
    await _speech.stop();
    _isListening = false;
  }

  Future<void> _listen() async {
    _isListening = true;
    try {
      await _speech.listen(
        onResult: (stt_result.SpeechRecognitionResult result) {
          if (_isPaused) {
            return;
          }
          if (_resultsController.isClosed) {
            return;
          }
          if (!result.finalResult && result.recognizedWords.trim().isEmpty) {
            return;
          }
          _sessionValue = result.recognizedWords;

          if (_sessionValue.isNotEmpty && _cacheValue.isNotEmpty) {
            _sessionValue = _toLowercaseFirst(_sessionValue);
          }

          final currentValue = '$_cacheValue$_sessionValue';

          _resultsController.add(
            SpeechRecognitionResult(
              text: currentValue,
              isFinal: result.finalResult,
            ),
          );
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        ),
        localeId: _normalizedLocale,
      );
    } catch (e) {
      _isListening = false;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isListening) {
      return;
    }
    await _speech.stop();
    _isListening = false;
    _cacheValue = '';
    _sessionValue = '';
  }

  @override
  Future<void> reset() async {
    await _speech.cancel();
    _cacheValue = '';
    _sessionValue = '';
    _isListening = false;
  }

  @override
  Future<void> dispose() async {
    if (_isListening) {
      await _speech.stop();
    }

    _cacheValue = '';
    _sessionValue = '';
    await _resultsController.close();
    _isListening = false;
    _isInitialized = false;
  }

  @override
  Future<void> pause() async {
    _isPaused = true;

    _stopListening();
    _cacheValue = '$_cacheValue $_sessionValue ';
    _sessionValue = '';
  }

  @override
  Future<void> resume() async {
    _isPaused = false;
    await _listen();
  }

  String _toLowercaseFirst(String value) {
    return value.isEmpty
        ? ''
        : value.substring(0, 1).toLowerCase() + value.substring(1);
  }
}
