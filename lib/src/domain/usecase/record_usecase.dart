import 'package:flutter/foundation.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

import '../../core/services/easy_audio_controller.dart';
import '../entities/record_language_result.dart';
import 'speech_to_text_usecase.dart';

class RecordUsecase {
  RecordUsecase() : _audioController = EasyAudioController.withBackgroundMode();

  final EasyAudioController _audioController;

  // Getters for audio controller state
  EasyAudioController get audioController => _audioController;
  bool get isPlaying => _audioController.isPlaying;
  bool get isOpenPlayer => _audioController.isOpenPlayer;
  bool get isPlayerInited => _audioController.isInited;
  String get currentPlayingUrl => _audioController.url;

  /// Initialize audio player
  Future<void> initPlayer({bool disposeWhenParentDispose = false}) async {
    await _audioController.initPlayer(disposeWhenParentDispose);
  }

  /// Add listener to audio controller
  void addAudioListener(VoidCallback listener) {
    _audioController.addListener(listener);
  }

  /// Remove listener from audio controller
  void removeAudioListener(VoidCallback listener) {
    _audioController.removeListener(listener);
  }

  /// Play audio by url. If url is empty, stop current audio.
  Future<void> playAudio(String url) async {
    await _audioController.play(url);
  }

  /// Stop audio player
  Future<void> stopPlayer() async {
    await _audioController.stopPlayer();
  }

  /// Dispose audio controller
  void disposeAudioController() {
    _audioController.forceDispose();
  }

  Future<RecordLanguageResult> loadSupportedLanguages({
    required String currentLocale,
  }) async {
    final languages = await RecordLanguage.ensureSystemLocalesLoaded();
    final labelLocale = RecordLanguage.languageLabelForLocale(currentLocale);
    final fallbackLocale =
        languages[RecordLanguage.defaultLang] ?? RecordLanguage.defaultLocale;
    final resolvedLocale = labelLocale == null ? fallbackLocale : currentLocale;
    final resolvedLabel =
        RecordLanguage.languageLabelForLocale(resolvedLocale) ??
            RecordLanguage.defaultLang;

    return RecordLanguageResult(locale: resolvedLocale, label: resolvedLabel);
  }

  Future<RecordLanguageResult> prepareLanguageModel(String locale) async {
    final usecase = SpeechToTextUsecase(local: locale);
    var resolvedLocale = locale;
    try {
      final loadedLocale = await usecase.initSpeechToText();
      if (loadedLocale != null && loadedLocale.isNotEmpty) {
        resolvedLocale = loadedLocale;
      }
    } finally {
      try {
        await usecase.dispose();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('[RecordUsecase] dispose error: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }

    return RecordLanguageResult(
      locale: resolvedLocale,
      label: RecordLanguage.languageLabelForLocale(resolvedLocale) ??
          RecordLanguage.defaultLang,
    );
  }

  /// Merge audio items into existing list, optionally filtering duplicates
  List<dynamic> mergeAudioItems(
    List<dynamic> currentList,
    List<dynamic> newItems, {
    bool Function(dynamic existing, dynamic newItem)? isDuplicate,
  }) {
    if (isDuplicate == null) {
      return [...currentList, ...newItems];
    }

    final mergedList = [...currentList];
    for (final item in newItems) {
      final exists = mergedList.any((existing) => isDuplicate(existing, item));
      if (!exists) {
        mergedList.add(item);
      }
    }
    return mergedList;
  }
}
