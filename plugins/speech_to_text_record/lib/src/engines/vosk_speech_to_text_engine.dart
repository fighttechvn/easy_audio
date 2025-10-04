import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:vosk_flutter/vosk_flutter.dart';

import '../constants/vosk_model.dart';
import '../exceptions.dart';
import '../models/speech_recognition_result.dart';
import 'speech_to_text_engine.dart';

/// Points to the platforms where Vosk currently provides bindings.
bool get _voskPlatformSupported =>
    Platform.isAndroid || Platform.isLinux || Platform.isWindows;

/// Handles streaming speech-to-text transcription using the Vosk SDK.
class VoskSpeechToTextEngine extends SpeechToTextEngine {
  VoskSpeechToTextEngine({
    required this.sampleRate,
    ModelLoader? modelLoader,
    Iterable<String> preloadLocales = const <String>[],
  })  : _modelLoader = modelLoader ?? ModelLoader(),
        _preloadLocales = preloadLocales
            .map((locale) => locale.trim())
            .where((locale) => locale.isNotEmpty)
            .toSet() {
    if (_preloadLocales.isNotEmpty) {
      _scheduleWarmup();
    }
  }

  static bool get isPlatformSupported => _voskPlatformSupported;

  final int sampleRate;
  final ModelLoader _modelLoader;

  final StreamController<SpeechRecognitionResult> _resultsController =
      StreamController<SpeechRecognitionResult>.broadcast();

  StreamSubscription<Uint8List>? _subscription;
  Future<void> _processingQueue = Future<void>.value();
  Recognizer? _recognizer;
  Model? _model;
  String? _activeLocale;
  String? _customModelPath;
  String? _customAssetPath;
  String? _customModelUrl;
  bool _isListening = false;

  final Set<String> _preloadLocales;

  static final Map<String, Future<String>> _preloadedModelFutures =
      <String, Future<String>>{};

  @override
  Stream<SpeechRecognitionResult> get results => _resultsController.stream;

  @override
  bool get isSupported => isPlatformSupported;

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

    if (modelPath != null) {
      _customModelPath = modelPath;
      _customAssetPath = null;
      _customModelUrl = null;
    } else if (assetPath != null) {
      _customAssetPath = assetPath;
      _customModelPath = null;
      _customModelUrl = null;
    } else if (modelUrl != null) {
      _customModelUrl = modelUrl;
      _customModelPath = null;
      _customAssetPath = null;
    }

    if (forceReload) {
      await _disposeRecognizer();
      _activeLocale = null;
    }

    final String targetLocale = (localeId == null || localeId.isEmpty)
        ? (_activeLocale ?? RecordLanguage.defaultLocale)
        : localeId;

    await _ensureRecognizerForLocale(targetLocale, forceReload: forceReload);
  }

  @override
  Future<void> start(Stream<Uint8List> audioStream, {String? localeId}) async {
    final String targetLocale =
        localeId ?? _activeLocale ?? RecordLanguage.defaultLocale;

    await _ensureRecognizerForLocale(targetLocale);

    if (_recognizer == null) {
      throw AudioPipelineStateException(
        'Speech recognizer is unavailable. Ensure prepareModel completes successfully before starting.',
      );
    }
    if (_isListening) {
      return;
    }

    _subscription = audioStream.listen(
      (chunk) {
        final data = Uint8List.fromList(chunk);
        _processingQueue = _processingQueue
            .then((_) => _handleChunk(data))
            .catchError((Object error, StackTrace stackTrace) {
          if (!_resultsController.isClosed) {
            _resultsController.addError(error, stackTrace);
          }
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_resultsController.isClosed) {
          _resultsController.addError(error, stackTrace);
        }
      },
      cancelOnError: false,
    );

    _isListening = true;
  }

  @override
  Future<void> stop() async {
    if (!_isListening) {
      return;
    }
    await _subscription?.cancel();
    _subscription = null;
    await _processingQueue;

    final recognizer = _recognizer;
    if (recognizer != null) {
      final finalResult = await recognizer.getFinalResult();
      final parsed = _parseResult(finalResult, isFinal: true);
      if (parsed != null && !_resultsController.isClosed) {
        _resultsController.add(parsed);
      }
    }
    _isListening = false;
  }

  @override
  Future<void> reset() async {
    await _recognizer?.reset();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _processingQueue;
    await _resultsController.close();
    await _disposeRecognizer();
    _activeLocale = null;
  }

  Future<void> _ensureRecognizerForLocale(
    String locale, {
    bool forceReload = false,
  }) async {
    final String normalized = _canonicalizeLocale(locale);
    if (!forceReload && _recognizer != null && _activeLocale == normalized) {
      return;
    }

    if (_isListening) {
      await stop();
    }
    await _processingQueue;
    await _disposeRecognizer();

    final resolvedPath = await _resolveModelPath(
      normalized,
      forceReload: forceReload,
    );

    final plugin = VoskFlutterPlugin.instance();
    final model = await plugin.createModel(resolvedPath);
    _model = model;
    _recognizer = await plugin.createRecognizer(
      model: model,
      sampleRate: sampleRate,
    );
    _activeLocale = normalized;
  }

  String _canonicalizeLocale(String locale) {
    final cleaned = locale.trim();
    if (cleaned.isEmpty) {
      return RecordLanguage.defaultLocale;
    }
    final hyphenated = cleaned.replaceAll('_', '-');
    final parts =
        hyphenated.split('-').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return RecordLanguage.defaultLocale;
    }
    final language = parts.first.toLowerCase();
    if (parts.length == 1) {
      return language;
    }
    final region = parts[1].toUpperCase();
    return '$language-$region';
  }

  Future<String> _resolveModelPath(
    String locale, {
    bool forceReload = false,
  }) async {
    if (_customModelPath != null) {
      return _customModelPath!;
    }
    if (_customAssetPath != null) {
      return _modelLoader.loadFromAssets(
        _customAssetPath!,
        forceReload: forceReload,
      );
    }
    final String? url =
        _customModelUrl ?? RecordLanguage.voskModelUrlFor(locale);
    if (url == null) {
      throw SpeechToTextNotSupportedException(
        'No Vosk model configured for locale $locale. Provide a custom modelPath, assetPath, or modelUrl.',
      );
    }
    if (!forceReload) {
      final Future<String>? warmup = _preloadedModelFutures[url];
      if (warmup != null) {
        try {
          return await warmup;
        } catch (error, stackTrace) {
          if (identical(_preloadedModelFutures[url], warmup)) {
            _preloadedModelFutures.remove(url);
          }
          developer.log(
            'Warmup for $url failed, retrying download during prepare',
            name: 'VoskSpeechToTextEngine',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }
    return _modelLoader.loadFromNetwork(url, forceReload: forceReload);
  }

  void _scheduleWarmup() {
    for (final String locale in _preloadLocales) {
      final String normalized = _canonicalizeLocale(locale);
      final String? url = RecordLanguage.voskModelUrlFor(normalized);
      if (url == null) {
        developer.log(
          'Ignoring preload for $locale (no Vosk model configured).',
          name: 'VoskSpeechToTextEngine',
        );
        continue;
      }
      if (_preloadedModelFutures.containsKey(url)) {
        continue;
      }
      late Future<String> future;
      future = _warmupModel(url).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        if (identical(_preloadedModelFutures[url], future)) {
          _preloadedModelFutures.remove(url);
        }
        developer.log(
          'Failed to preload Vosk model from $url',
          name: 'VoskSpeechToTextEngine',
          error: error,
          stackTrace: stackTrace,
        );
        Error.throwWithStackTrace(error, stackTrace);
      });
      _preloadedModelFutures[url] = future;
    }
  }

  Future<String> _warmupModel(String url) async {
    final String modelName = _modelNameFromUrl(url);
    if (await _modelLoader.isModelAlreadyLoaded(modelName)) {
      return _modelLoader.modelPath(modelName);
    }
    return _modelLoader.loadFromNetwork(url);
  }

  String _modelNameFromUrl(String url) {
    final String filename = url.split('/').last;
    return p.basenameWithoutExtension(filename);
  }

  Future<void> _disposeRecognizer() async {
    await _recognizer?.dispose();
    _recognizer = null;
    _model?.dispose();
    _model = null;
  }

  Future<void> _handleChunk(Uint8List chunk) async {
    final recognizer = _recognizer;
    if (recognizer == null) {
      return;
    }

    final isFinal = await recognizer.acceptWaveformBytes(chunk);
    final raw = isFinal
        ? await recognizer.getResult()
        : await recognizer.getPartialResult();

    final parsed = _parseResult(raw, isFinal: isFinal);
    if (parsed != null && !_resultsController.isClosed) {
      _resultsController.add(parsed);
    }
  }

  SpeechRecognitionResult? _parseResult(String raw, {required bool isFinal}) {
    if (raw.isEmpty) {
      return null;
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    if (isFinal) {
      final text = (decoded['text'] as String? ?? '').trim();
      if (text.isEmpty) {
        return null;
      }
      final words = (decoded['result'] as List<dynamic>?)
          ?.map<SpeechWord?>((dynamic word) {
            if (word is! Map<String, dynamic>) {
              return null;
            }
            final token = (word['word'] as String? ?? '').trim();
            if (token.isEmpty) {
              return null;
            }
            return SpeechWord(
              word: token,
              start: (word['start'] as num?)?.toDouble() ?? 0,
              end: (word['end'] as num?)?.toDouble() ?? 0,
              confidence: (word['conf'] as num?)?.toDouble(),
            );
          })
          .whereType<SpeechWord>()
          .toList();

      return SpeechRecognitionResult(
        text: text,
        isFinal: true,
        words: words?.isEmpty ?? true ? null : words,
      );
    }

    final partial = (decoded['partial'] as String? ?? '').trim();
    if (partial.isEmpty) {
      return null;
    }
    return SpeechRecognitionResult(text: partial, isFinal: false);
  }
}
