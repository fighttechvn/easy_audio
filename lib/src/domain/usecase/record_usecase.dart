import 'package:flutter/foundation.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

import '../entities/record_language_result.dart';
import 'speech_to_text_usecase.dart';

class RecordUsecase {
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
}
