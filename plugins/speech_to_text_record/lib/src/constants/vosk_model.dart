import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Supported locale identifiers for the speech-to-text pipeline with Vosk models.
class RecordLanguage {
  const RecordLanguage._();

  /// Default locale when none is provided by the caller.
  static const String defaultLocale = 'en-US';
  static const String defaultLang = 'English (United States)';
  static const Map<String, String> _androidSupportedLanguages = {
    'Arabic (Saudi Arabia)': 'ar-SA',
    'Arabic (Tunisia)': 'ar-TN',
    'Catalan (Spain)': 'ca-ES',
    'Chinese (China mainland)': 'zh-CN',
    'Czech (Czechia)': 'cs-CZ',
    'Dutch (Netherlands)': 'nl-NL',
    'English (India)': 'en-IN',
    'English (United Kingdom)': 'en-GB',
    'English (United States)': 'en-US',
    'Esperanto': 'eo',
    'Farsi (Iran)': 'fa',
    'Filipino (Philippines)': 'tl-PH',
    'French (France)': 'fr-FR',
    'German (Germany)': 'de-DE',
    'Gujarati (India)': 'gu',
    'Hindi (India)': 'hi-IN',
    'Italian (Italy)': 'it-IT',
    'Japanese (Japan)': 'ja-JP',
    'Kazakh (Kazakhstan)': 'kz',
    'Korean (South Korea)': 'ko-KR',
    'Polish (Poland)': 'pl-PL',
    'Portuguese (Brazil)': 'pt-BR',
    'Russian (Russia)': 'ru-RU',
    'Spanish (Spain)': 'es-ES',
    'Swedish (Sweden)': 'sv-SE',
    'Tajik (Tajikistan)': 'tg',
    'Telugu (India)': 'te',
    'Turkish (Türkiye)': 'tr-TR',
    'Ukrainian (Ukraine)': 'uk-UA',
    'Uzbek (Uzbekistan)': 'uz',
    'Vietnamese (Vietnam)': 'vi-VN',
  };

  /// Map of user-facing language labels to locale codes.
  static Map<String, String> supported = Platform.isIOS
      ? <String, String>{defaultLang: defaultLocale}
      : <String, String>{..._androidSupportedLanguages};

  static bool _iosLocalesLoaded = !Platform.isIOS;
  static bool _isLoadingIosLocales = false;

  /// Ensures the iOS supported language map is refreshed from the system via
  /// speech-to-text. Returns the updated map when a refresh was attempted or
  /// the cached map otherwise.
  static Future<Map<String, String>> ensureSystemLocalesLoaded({
    bool forceReload = false,
  }) async {
    if (!Platform.isIOS) {
      return supported;
    }
    if (_iosLocalesLoaded && !forceReload) {
      return supported;
    }
    if (_isLoadingIosLocales) {
      // Wait for the current load to finish.
      while (_isLoadingIosLocales) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return supported;
    }

    _isLoadingIosLocales = true;
    try {
      final stt.SpeechToText speech = stt.SpeechToText();
      final bool available = await speech.initialize();
      if (!available) {
        if (kDebugMode) {
          debugPrint(
            '[RecordLanguage] SpeechToText unavailable when loading locales',
          );
        }
        _iosLocalesLoaded = true;
        return supported;
      }

      final locales = await speech.locales();
      if (locales.isEmpty) {
        if (kDebugMode) {
          debugPrint('[RecordLanguage] No locales returned by SpeechToText');
        }
        _iosLocalesLoaded = true;
        return supported;
      }

      final SplayTreeMap<String, String> systemLocales =
          SplayTreeMap<String, String>();
      for (final locale in locales) {
        final String normalizedId = locale.localeId.replaceAll('_', '-');
        final String label = labels[normalizedId] ?? locale.name;
        systemLocales[label] = normalizedId;
      }

      // Always ensure default language is present.
      systemLocales.putIfAbsent(defaultLang, () => defaultLocale);

      supported = Map<String, String>.fromEntries(systemLocales.entries);
      _iosLocalesLoaded = true;
    } catch (error, stackTrace) {
      _iosLocalesLoaded = false;
      if (kDebugMode) {
        debugPrint('[RecordLanguage] Failed to load system locales: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    } finally {
      _isLoadingIosLocales = false;
    }

    return supported;
  }

  /// Human readable labels for the supported locales.
  static const Map<String, String> labels = <String, String>{
    'ar-SA': 'Arabic (Saudi Arabia)',
    'ar-TN': 'Arabic (Tunisia)',
    'yue-CN': 'Cantonese (China mainland)',
    'ca-ES': 'Catalan (Spain)',
    'zh-CN': 'Chinese (China mainland)',
    'zh-HK': 'Chinese (Hong Kong)',
    'zh-TW': 'Chinese (Taiwan)',
    'hr-HR': 'Croatian (Croatia)',
    'cs-CZ': 'Czech (Czechia)',
    'da-DK': 'Danish (Denmark)',
    'nl-BE': 'Dutch (Belgium)',
    'nl-NL': 'Dutch (Netherlands)',
    'en-AU': 'English (Australia)',
    'en-CA': 'English (Canada)',
    'en-IN': 'English (India)',
    'en-ID': 'English (Indonesia)',
    'en-IE': 'English (Ireland)',
    'en-NZ': 'English (New Zealand)',
    'en-PH': 'English (Philippines)',
    'en-SA': 'English (Saudi Arabia)',
    'en-SG': 'English (Singapore)',
    'en-ZA': 'English (South Africa)',
    'en-AE': 'English (United Arab Emirates)',
    'en-GB': 'English (United Kingdom)',
    'en-US': 'English (United States)',
    'en-VN': 'English (Vietnam)',
    'eo': 'Esperanto',
    'fa': 'Farsi (Iran)',
    'tl-PH': 'Filipino (Philippines)',
    'fi-FI': 'Finnish (Finland)',
    'fr-BE': 'French (Belgium)',
    'fr-CA': 'French (Canada)',
    'fr-FR': 'French (France)',
    'fr-CH': 'French (Switzerland)',
    'de-AT': 'German (Austria)',
    'de-DE': 'German (Germany)',
    'de-CH': 'German (Switzerland)',
    'el-GR': 'Greek (Greece)',
    'gu': 'Gujarati (India)',
    'he-IL': 'Hebrew (Israel)',
    'hi-IN': 'Hindi (India)',
    'hi-Latn': 'Hindi (Latin)',
    'hu-HU': 'Hungarian (Hungary)',
    'id-ID': 'Indonesian (Indonesia)',
    'it-IT': 'Italian (Italy)',
    'it-CH': 'Italian (Switzerland)',
    'ja-JP': 'Japanese (Japan)',
    'kz': 'Kazakh (Kazakhstan)',
    'ko-KR': 'Korean (South Korea)',
    'ms-MY': 'Malay (Malaysia)',
    'nb-NO': 'Norwegian Bokmål (Norway)',
    'pl-PL': 'Polish (Poland)',
    'pt-BR': 'Portuguese (Brazil)',
    'pt-PT': 'Portuguese (Portugal)',
    'ro-RO': 'Romanian (Romania)',
    'ru-RU': 'Russian (Russia)',
    'wuu-CN': 'Shanghainese (China mainland)',
    'sk-SK': 'Slovak (Slovakia)',
    'es-CL': 'Spanish (Chile)',
    'es-CO': 'Spanish (Colombia)',
    'es-419': 'Spanish (Latin America)',
    'es-MX': 'Spanish (Mexico)',
    'es-ES': 'Spanish (Spain)',
    'es-US': 'Spanish (United States)',
    'sv-SE': 'Swedish (Sweden)',
    'tg': 'Tajik (Tajikistan)',
    'te': 'Telugu (India)',
    'th-TH': 'Thai (Thailand)',
    'tr-TR': 'Turkish (Türkiye)',
    'uk-UA': 'Ukrainian (Ukraine)',
    'uz': 'Uzbek (Uzbekistan)',
    'vi-VN': 'Vietnamese (Vietnam)',
  };

  /// RecordLanguage data - filtered to keep only the highest version for each language
  static const List<Map<String, dynamic>> models = [
    // Arabic
    {
      "lang": "ar",
      "lang_text": "Arabic",
      "md5": "0eb578c0779f85ef039b7ee5bc1b64ed",
      "name": "vosk-model-small-ar-0.3",
      "obsolete": "false",
      "size": 104351896,
      "size_text": "99.5MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-ar-0.3.zip",
      "version": "0.3"
    },
    // Arabic Tunisian
    {
      "lang": "ar-tn",
      "lang_text": "Arabic Tunisian",
      "md5": "67bbe16beaa17e6cf14f8c295ee5ddd1",
      "name": "vosk-model-small-ar-tn-0.1-linto",
      "obsolete": "false",
      "size": 165703754,
      "size_text": "158.0MiB",
      "type": "small",
      "url":
          "https://alphacephei.com/vosk/models/vosk-model-small-ar-tn-0.1-linto.zip",
      "version": "0.1-linto"
    },
    // Catalan
    {
      "lang": "ca",
      "lang_text": "Catalan",
      "md5": "5dc7901815fef3dc8b784b31f309385c",
      "name": "vosk-model-small-ca-0.4",
      "obsolete": "false",
      "size": 43405881,
      "size_text": "41.4MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-ca-0.4.zip",
      "version": "0.4"
    },
    // Chinese - Version cao nhất (0.22)
    {
      "lang": "cn",
      "lang_text": "Chinese",
      "md5": "d1a8e82933dcc7632667c036b0bb3dbb",
      "name": "vosk-model-small-cn-0.22",
      "obsolete": "false",
      "size": 43898754,
      "size_text": "41.9MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip",
      "version": "0.22"
    },
    // Czech
    {
      "lang": "cs",
      "lang_text": "Czech",
      "md5": "df5ddac5ee8632f6b46a6fc751953286",
      "name": "vosk-model-small-cs-0.4-rhasspy",
      "obsolete": "false",
      "size": 46088666,
      "size_text": "44.0MiB",
      "type": "small",
      "url":
          "https://alphacephei.com/vosk/models/vosk-model-small-cs-0.4-rhasspy.zip",
      "version": "0.4-rhasspy"
    },
    // German - Version cao nhất (0.15)
    {
      "lang": "de",
      "lang_text": "German",
      "md5": "4f21f92c0897b48287ef8839420608eb",
      "name": "vosk-model-small-de-0.15",
      "obsolete": "false",
      "size": 46499967,
      "size_text": "44.3MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip",
      "version": "0.15"
    },
    // UK English
    {
      "lang": "en-gb",
      "lang_text": "UK English",
      "md5": "6afd611b04b2b47c129c3615dc502383",
      "name": "vosk-model-small-en-gb-0.15",
      "obsolete": "false",
      "size": 42757500,
      "size_text": "40.8MiB",
      "type": "small",
      "url":
          "https://alphacephei.com/vosk/models/vosk-model-small-en-gb-0.15.zip",
      "version": "0.15"
    },
    // Indian English
    {
      "lang": "en-in",
      "lang_text": "Indian English",
      "md5": "62fd085f33c8c5fc01a235030e2a1fe3",
      "name": "vosk-model-small-en-in-0.4",
      "obsolete": "false",
      "size": 37573330,
      "size_text": "35.8MiB",
      "type": "small",
      "url":
          "https://alphacephei.com/vosk/models/vosk-model-small-en-in-0.4.zip",
      "version": "0.4"
    },
    // US English - Version cao nhất (0.22-lgraph)
    {
      "lang": "en-us",
      "lang_text": "US English",
      "md5": "2df36985f8ed8eb7b78476cadcdab48f",
      "name": "vosk-model-en-us-0.22-lgraph",
      "obsolete": "false",
      "size": 130557655,
      "size_text": "124.5MiB",
      "type": "big-lgraph",
      "url":
          "https://alphacephei.com/vosk/models/vosk-model-en-us-0.22-lgraph.zip",
      "version": "0.22-lgraph"
    },
    // Esperanto - Version cao nhất (0.42)
    {
      "lang": "eo",
      "lang_text": "Esperanto",
      "md5": "3e9319ca789fa06fd3efa68d51c85d6b",
      "name": "vosk-model-small-eo-0.42",
      "obsolete": "false",
      "size": 43839401,
      "size_text": "41.8MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-eo-0.42.zip",
      "version": "0.42"
    },
    // Spanish - Version cao nhất (0.42)
    {
      "lang": "es",
      "lang_text": "Spanish",
      "md5": "2d5c94f9859a84881a0ef744738ebd31",
      "name": "vosk-model-small-es-0.42",
      "obsolete": "false",
      "size": 39817833,
      "size_text": "38.0MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip",
      "version": "0.42"
    },
    // Farsi - Version cao nhất (0.42)
    {
      "lang": "fa",
      "lang_text": "Farsi",
      "md5": "cc2b18af256ffab2c44055f6a02ecb3d",
      "name": "vosk-model-small-fa-0.42",
      "obsolete": "false",
      "size": 53431220,
      "size_text": "51.0MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-fa-0.42.zip",
      "version": "0.42"
    },
    // French - Version cao nhất (0.22)
    {
      "lang": "fr",
      "lang_text": "French",
      "md5": "8873b1234503f6edd55f54bfff31cf3e",
      "name": "vosk-model-small-fr-0.22",
      "obsolete": "false",
      "size": 42233323,
      "size_text": "40.3MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip",
      "version": "0.22"
    },
    // Gujarati
    {
      "lang": "gu",
      "lang_text": "Gujarati",
      "md5": "4595a6f0cc0c88fee6eec7d80496fc10",
      "name": "vosk-model-small-gu-0.42",
      "obsolete": "false",
      "size": 108054987,
      "size_text": "103.0MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-gu-0.42.zip",
      "version": "0.42"
    },
    // Hindi
    {
      "lang": "hi",
      "lang_text": "Hindi",
      "md5": "80f1265262c9a8a515f2707498e1b485",
      "name": "vosk-model-small-hi-0.22",
      "obsolete": "false",
      "size": 44458845,
      "size_text": "42.4MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip",
      "version": "0.22"
    },
    // Italian - Version cao nhất (0.22)
    {
      "lang": "it",
      "lang_text": "Italian",
      "md5": "fbd8f9c72cbb8c3dfa3e4581bd3585f4",
      "name": "vosk-model-small-it-0.22",
      "obsolete": "false",
      "size": 49665141,
      "size_text": "47.4MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-it-0.22.zip",
      "version": "0.22"
    },
    // Japanese
    {
      "lang": "ja",
      "lang_text": "Japanese",
      "md5": "0e3163dd62dfb0d823353718ac3cbf79",
      "name": "vosk-model-small-ja-0.22",
      "obsolete": "false",
      "size": 49704573,
      "size_text": "47.4MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-ja-0.22.zip",
      "version": "0.22"
    },
    // Korean
    {
      "lang": "ko",
      "lang_text": "Korean",
      "md5": "fa8029a173787a159e0e72fe6135f890",
      "name": "vosk-model-small-ko-0.22",
      "obsolete": "false",
      "size": 86914329,
      "size_text": "82.9MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-ko-0.22.zip",
      "version": "0.22"
    },
    // Kazakh
    {
      "lang": "kz",
      "lang_text": "Kazakh",
      "md5": "e55d95d1ffbafc0dfeb6fef044d5759b",
      "name": "vosk-model-small-kz-0.15",
      "obsolete": "false",
      "size": 43739114,
      "size_text": "41.7MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-kz-0.15.zip",
      "version": "0.15"
    },
    // Dutch
    {
      "lang": "nl",
      "lang_text": "Dutch",
      "md5": "50c025bca2ebeb1dba54b3687632d92f",
      "name": "vosk-model-nl-spraakherkenning-0.6-lgraph",
      "obsolete": "false",
      "size": 105951663,
      "size_text": "101.0MiB",
      "type": "big-lgraph",
      "url":
          "https://alphacephei.com/vosk/models/vosk-model-nl-spraakherkenning-0.6-lgraph.zip",
      "version": "spraakherkenning-0.6-lgraph"
    },
    // Polish
    {
      "lang": "pl",
      "lang_text": "Polish",
      "md5": "91cbbd6231320467da672be31827b6ac",
      "name": "vosk-model-small-pl-0.22",
      "obsolete": "false",
      "size": 52979372,
      "size_text": "50.5MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip",
      "version": "0.22"
    },
    // Portuguese
    {
      "lang": "pt",
      "lang_text": "Portuguese",
      "md5": "458c69371c5a0b9ab6ee8fa417bf89da",
      "name": "vosk-model-small-pt-0.3",
      "obsolete": "false",
      "size": 32453112,
      "size_text": "30.9MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip",
      "version": "0.3"
    },
    // Russian - Version cao nhất cho speech recognition (0.22)
    {
      "lang": "ru",
      "lang_text": "Russian",
      "md5": "d1759dc83eb8fd87850129afbd9f4b7b",
      "name": "vosk-model-small-ru-0.22",
      "obsolete": "false",
      "size": 46236750,
      "size_text": "44.1MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip",
      "version": "0.22"
    },
    // Swedish
    {
      "lang": "sv",
      "lang_text": "Swedish",
      "md5": "5ae431c65fe8636692118792daa22ecc",
      "name": "vosk-model-small-sv-rhasspy-0.15",
      "obsolete": "false",
      "size": 303504931,
      "size_text": "289.4MiB",
      "type": "small",
      "url":
          "https://alphacephei.com/vosk/models/vosk-model-small-sv-rhasspy-0.15.zip",
      "version": "rhasspy-0.15"
    },
    // Telugu
    {
      "lang": "te",
      "lang_text": "Telugu",
      "md5": "ae3c093fd7dd883d462983b15900ca61",
      "name": "vosk-model-small-te-0.42",
      "obsolete": "false",
      "size": 60544249,
      "size_text": "57.7MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-te-0.42.zip",
      "version": "0.42"
    },
    // Tajik
    {
      "lang": "tg",
      "lang_text": "Tajik",
      "md5": "44aef3049d0cba96d2bffda308ef0859",
      "name": "vosk-model-tg-0.22",
      "obsolete": "false",
      "size": 335635924,
      "size_text": "320.1MiB",
      "type": "big",
      "url": "https://alphacephei.com/vosk/models/vosk-model-tg-0.22.zip",
      "version": "0.22"
    },
    // Filipino
    {
      "lang": "tl-ph",
      "lang_text": "Fillipino",
      "md5": "90b3dd8115dabdb4845972c2eb22797b",
      "name": "vosk-model-tl-ph-generic-0.6",
      "obsolete": "false",
      "size": 329169068,
      "size_text": "313.9MiB",
      "type": "big",
      "url":
          "https://alphacephei.com/vosk/models/vosk-model-tl-ph-generic-0.6.zip",
      "version": "generic-0.6"
    },
    // Turkish
    {
      "lang": "tr",
      "lang_text": "Turkish",
      "md5": "198511631860597639a0ebf779263fcf",
      "name": "vosk-model-small-tr-0.3",
      "obsolete": "false",
      "size": 36855784,
      "size_text": "35.1MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip",
      "version": "0.3"
    },
    // Ukrainian - Version cao nhất (v3-lgraph)
    {
      "lang": "ua",
      "lang_text": "Ukrainian",
      "md5": "dc44144856364743c83555bc48aa3792",
      "name": "vosk-model-uk-v3-lgraph",
      "obsolete": "false",
      "size": 340762018,
      "size_text": "325.0MiB",
      "type": "big-lgraph",
      "url": "https://alphacephei.com/vosk/models/vosk-model-uk-v3-lgraph.zip",
      "version": "v3-lgraph"
    },
    // Uzbek
    {
      "lang": "uz",
      "lang_text": "Uzbek",
      "md5": "4d75acfef76fe919c8fb68cd1179c182",
      "name": "vosk-model-small-uz-0.22",
      "obsolete": "false",
      "size": 51061189,
      "size_text": "48.7MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-uz-0.22.zip",
      "version": "0.22"
    },
    // Vietnamese - Version cao nhất (0.4)
    {
      "lang": "vn",
      "lang_text": "Vietnamese",
      "md5": "b31b474a1ef75488c5fa575f8e2a1269",
      "name": "vosk-model-small-vn-0.4",
      "obsolete": "false",
      "size": 33656337,
      "size_text": "32.1MiB",
      "type": "small",
      "url": "https://alphacephei.com/vosk/models/vosk-model-small-vn-0.4.zip",
      "version": "0.4"
    },
    // All Languages - Version cao nhất (0.4)
    {
      "lang": "all",
      "lang_text": "All",
      "md5": "63b868d866a756c30f048b007541fd25",
      "name": "vosk-model-spk-0.4",
      "obsolete": "false",
      "size": 13869103,
      "size_text": "13.2MiB",
      "type": "spk",
      "url": "https://alphacephei.com/vosk/models/vosk-model-spk-0.4.zip",
      "version": "0.4"
    },
  ];

  /// List of supported languages with their locale codes (languages that have Vosk models)
  static const List<String> supportedLanguages = [
    'Arabic (Saudi Arabia)',
    'Arabic (Tunisia)',
    'Catalan (Spain)',
    'Chinese (China mainland)',
    'Czech (Czechia)',
    'Dutch (Netherlands)',
    'English (India)',
    'English (United Kingdom)',
    'English (United States)',
    'Esperanto',
    'Farsi (Iran)',
    'Filipino (Philippines)',
    'French (France)',
    'German (Germany)',
    'Gujarati (India)',
    'Hindi (India)',
    'Italian (Italy)',
    'Japanese (Japan)',
    'Kazakh (Kazakhstan)',
    'Korean (South Korea)',
    'Polish (Poland)',
    'Portuguese (Brazil)',
    'Russian (Russia)',
    'Spanish (Spain)',
    'Swedish (Sweden)',
    'Tajik (Tajikistan)',
    'Telugu (India)',
    'Turkish (Türkiye)',
    'Ukrainian (Ukraine)',
    'Uzbek (Uzbekistan)',
    'Vietnamese (Vietnam)',
  ];

  /// List of unsupported languages (languages that don't have dedicated Vosk models)
  static const List<String> unsupportedLanguages = [
    'Cantonese (China mainland)',
    'Croatian (Croatia)',
    'Danish (Denmark)',
    'English (Indonesia)',
    'Finnish (Finland)',
    'Greek (Greece)',
    'Hebrew (Israel)',
    'Hindi (Latin)',
    'Hungarian (Hungary)',
    'Indonesian (Indonesia)',
    'Malay (Malaysia)',
    'Norwegian Bokmål (Norway)',
    'Romanian (Romania)',
    'Shanghainese (China mainland)',
    'Slovak (Slovakia)',
    'Thai (Thailand)',
  ];

  /// Fallback mapping for locales without a dedicated Vosk model.
  static const Map<String, String> _voskFallbackLanguages = <String, String>{
    'da': 'sv',
    'fi': 'sv',
    'he': 'en-us',
    'hi-latn': 'hi',
    'hr': 'en-us',
    'hu': 'en-us',
    'id': 'en-us',
    'ms': 'id',
    'nb': 'sv',
    'ro': 'it',
    'th': 'en-us',
    'wuu': 'cn',
    'yue': 'cn',
  };

  /// Resolve a display label for [locale], falling back to the raw code.
  static String labelFor(String locale) => labels[locale] ?? locale;

  /// Resolve the default Vosk model URL for [locale], falling back to the
  /// language code when a region-specific entry is not available.
  static String? voskModelUrlFor(String locale) {
    if (locale.isEmpty) {
      return _getUrlFromVoskModels(defaultLocale);
    }

    final trimmed = locale.trim();
    if (trimmed.isEmpty) {
      return _getUrlFromVoskModels(defaultLocale);
    }

    final hyphenated = trimmed.replaceAll('_', '-');
    final underscored = trimmed.replaceAll('-', '_');
    final languageOnly = hyphenated.split('-').first.toLowerCase();

    final candidates = <String>{trimmed, hyphenated, underscored, languageOnly};

    for (final candidate in candidates) {
      final resolved = _getUrlFromVoskModels(candidate);
      if (resolved != null) {
        return resolved;
      }
    }

    final fallbackLanguage = _voskFallbackLanguages[languageOnly] ??
        _voskFallbackLanguages[languageOnly.toLowerCase()];
    if (fallbackLanguage != null && fallbackLanguage != languageOnly) {
      return voskModelUrlFor(fallbackLanguage);
    }

    return _getUrlFromVoskModels(defaultLocale);
  }

  /// Helper function to get URL from models array based on locale
  static String? _getUrlFromVoskModels(String locale) {
    final normalizedLocale = _normalizeLocale(locale);

    // Try to find exact match first
    for (final model in models) {
      final modelLang = model['lang'] as String;
      if (_normalizeLocale(modelLang) == normalizedLocale) {
        return model['url'] as String;
      }
    }

    // Try to find language-only match (e.g., 'en' for 'en-US')
    final languageOnly = normalizedLocale.split('-').first.toLowerCase();
    for (final model in models) {
      final modelLang = model['lang'] as String;
      if (_normalizeLocale(modelLang) == languageOnly) {
        return model['url'] as String;
      }
    }

    return null;
  }

  /// Normalize locale string for comparison
  static String _normalizeLocale(String locale) {
    return locale.toLowerCase().replaceAll('_', '-');
  }

  /// Get language title from language code
  static String getLanguageTitle(String langCode) {
    // Map from lang code in models to human readable title
    const languageTitleMapping = {
      "ar": "Arabic (Saudi Arabia)",
      "ar-tn": "Arabic (Tunisia)",
      "ca": "Catalan (Spain)",
      "cn": "Chinese (China mainland)",
      "cs": "Czech (Czechia)",
      "de": "German (Germany)",
      "en-gb": "English (United Kingdom)",
      "en-in": "English (India)",
      "en-us": "English (United States)",
      "eo": "Esperanto",
      "es": "Spanish (Spain)",
      "fa": "Farsi (Iran)",
      "fr": "French (France)",
      "gu": "Gujarati (India)",
      "hi": "Hindi (India)",
      "it": "Italian (Italy)",
      "ja": "Japanese (Japan)",
      "ko": "Korean (South Korea)",
      "kz": "Kazakh (Kazakhstan)",
      "nl": "Dutch (Netherlands)",
      "pl": "Polish (Poland)",
      "pt": "Portuguese (Brazil)",
      "ru": "Russian (Russia)",
      "sv": "Swedish (Sweden)",
      "te": "Telugu (India)",
      "tg": "Tajik (Tajikistan)",
      "tr": "Turkish (Türkiye)",
      "ua": "Ukrainian (Ukraine)",
      "uz": "Uzbek (Uzbekistan)",
      "vn": "Vietnamese (Vietnam)",
      "tl-ph": "Filipino (Philippines)",
    };
    return languageTitleMapping[langCode] ?? "Unknown Language";
  }

  /// Get models with title added
  static List<Map<String, dynamic>> getModelsWithTitle() {
    return models.map((model) {
      final Map<String, dynamic> modelWithTitle = Map.from(model);
      modelWithTitle['title'] = getLanguageTitle(model['lang'] as String);
      return modelWithTitle;
    }).toList();
  }

  /// Check if a language is supported (has a dedicated Vosk model)
  static bool isLanguageSupported(String languageName) {
    return supportedLanguages.contains(languageName);
  }

  /// Check if a language is unsupported (doesn't have a dedicated Vosk model)
  static bool isLanguageUnsupported(String languageName) {
    return unsupportedLanguages.contains(languageName);
  }

  /// Check if a locale has a Vosk model available
  static bool hasModelForLocale(String locale) {
    return voskModelUrlFor(locale) != null;
  }

  /// Get all supported language names
  static List<String> getAllSupportedLanguages() {
    return List.from(supportedLanguages);
  }

  /// Get all unsupported language names
  static List<String> getAllUnsupportedLanguages() {
    return List.from(unsupportedLanguages);
  }

  /// Get all available languages (both supported and unsupported)
  static List<String> getAllLanguages() {
    return [...supportedLanguages, ...unsupportedLanguages];
  }

  static String? languageLabelForLocale(String locale) {
    return RecordLanguage.supported.entries
        .firstWhereOrNull(
          (entry) => entry.value == locale,
        )
        ?.key;
  }
}
