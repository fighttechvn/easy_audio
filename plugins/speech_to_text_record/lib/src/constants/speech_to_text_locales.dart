/// Supported locale identifiers for the speech-to-text pipeline.
class SpeechToTextLocales {
  const SpeechToTextLocales._();

  /// Default locale when none is provided by the caller.
  static const String defaultLocale = 'en-US';

  /// Map of user-facing language labels to locale codes.
  static const Map<String, String> supported = <String, String>{
    'Arabic (Saudi Arabia)': 'ar-SA',
    'Cantonese (China mainland)': 'yue-CN',
    'Catalan (Spain)': 'ca-ES',
    'Chinese (China mainland)': 'zh-CN',
    'Chinese (Hong Kong)': 'zh-HK',
    'Chinese (Taiwan)': 'zh-TW',
    'Croatian (Croatia)': 'hr-HR',
    'Czech (Czechia)': 'cs-CZ',
    'Danish (Denmark)': 'da-DK',
    'Dutch (Belgium)': 'nl-BE',
    'Dutch (Netherlands)': 'nl-NL',
    'English (Australia)': 'en-AU',
    'English (Canada)': 'en-CA',
    'English (India)': 'en-IN',
    'English (Indonesia)': 'en-ID',
    'English (Ireland)': 'en-IE',
    'English (New Zealand)': 'en-NZ',
    'English (Philippines)': 'en-PH',
    'English (Saudi Arabia)': 'en-SA',
    'English (Singapore)': 'en-SG',
    'English (South Africa)': 'en-ZA',
    'English (United Arab Emirates)': 'en-AE',
    'English (United Kingdom)': 'en-GB',
    'English (United States)': 'en-US',
    'English (Vietnam)': 'en-VN',
    'Finnish (Finland)': 'fi-FI',
    'French (Belgium)': 'fr-BE',
    'French (Canada)': 'fr-CA',
    'French (France)': 'fr-FR',
    'French (Switzerland)': 'fr-CH',
    'German (Austria)': 'de-AT',
    'German (Germany)': 'de-DE',
    'German (Switzerland)': 'de-CH',
    'Greek (Greece)': 'el-GR',
    'Hebrew (Israel)': 'he-IL',
    'Hindi (India)': 'hi-IN',
    'Hindi (Latin)': 'hi-Latn',
    'Hungarian (Hungary)': 'hu-HU',
    'Indonesian (Indonesia)': 'id-ID',
    'Italian (Italy)': 'it-IT',
    'Italian (Switzerland)': 'it-CH',
    'Japanese (Japan)': 'ja-JP',
    'Korean (South Korea)': 'ko-KR',
    'Malay (Malaysia)': 'ms-MY',
    'Norwegian Bokmål (Norway)': 'nb-NO',
    'Polish (Poland)': 'pl-PL',
    'Portuguese (Brazil)': 'pt-BR',
    'Portuguese (Portugal)': 'pt-PT',
    'Romanian (Romania)': 'ro-RO',
    'Russian (Russia)': 'ru-RU',
    'Shanghainese (China mainland)': 'wuu-CN',
    'Slovak (Slovakia)': 'sk-SK',
    'Spanish (Chile)': 'es-CL',
    'Spanish (Colombia)': 'es-CO',
    'Spanish (Latin America)': 'es-419',
    'Spanish (Mexico)': 'es-MX',
    'Spanish (Spain)': 'es-ES',
    'Spanish (United States)': 'es-US',
    'Swedish (Sweden)': 'sv-SE',
    'Thai (Thailand)': 'th-TH',
    'Turkish (Türkiye)': 'tr-TR',
    'Ukrainian (Ukraine)': 'uk-UA',
    'Vietnamese (Vietnam)': 'vi-VN',
  };

  /// Human readable labels for the supported locales.
  static const Map<String, String> labels = <String, String>{
    'ar-SA': 'Arabic (Saudi Arabia)',
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
    'fi-FI': 'Finnish (Finland)',
    'fr-BE': 'French (Belgium)',
    'fr-CA': 'French (Canada)',
    'fr-FR': 'French (France)',
    'fr-CH': 'French (Switzerland)',
    'de-AT': 'German (Austria)',
    'de-DE': 'German (Germany)',
    'de-CH': 'German (Switzerland)',
    'el-GR': 'Greek (Greece)',
    'he-IL': 'Hebrew (Israel)',
    'hi-IN': 'Hindi (India)',
    'hi-Latn': 'Hindi (Latin)',
    'hu-HU': 'Hungarian (Hungary)',
    'id-ID': 'Indonesian (Indonesia)',
    'it-IT': 'Italian (Italy)',
    'it-CH': 'Italian (Switzerland)',
    'ja-JP': 'Japanese (Japan)',
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
    'th-TH': 'Thai (Thailand)',
    'tr-TR': 'Turkish (Türkiye)',
    'uk-UA': 'Ukrainian (Ukraine)',
    'vi-VN': 'Vietnamese (Vietnam)',
  };

  /// Default Vosk model URLs keyed by locale identifiers.
  /// Android builds preload the `en-US` and `vi-VN` entries by default; supply
  /// a custom `preloadLocales` list to override.
  static const Map<String, String> voskModelUrls = <String, String>{
    'ar': 'https://alphacephei.com/vosk/models/vosk-model-small-ar-0.22.zip',
    'ar-SA': 'https://alphacephei.com/vosk/models/vosk-model-small-ar-0.22.zip',
    'ar_SA': 'https://alphacephei.com/vosk/models/vosk-model-small-ar-0.22.zip',
    'ca': 'https://alphacephei.com/vosk/models/vosk-model-small-ca-0.4.zip',
    'ca-ES': 'https://alphacephei.com/vosk/models/vosk-model-small-ca-0.4.zip',
    'ca_ES': 'https://alphacephei.com/vosk/models/vosk-model-small-ca-0.4.zip',
    'cs':
        'https://alphacephei.com/vosk/models/vosk-model-small-cs-0.4-rhasspy.zip',
    'cs-CZ':
        'https://alphacephei.com/vosk/models/vosk-model-small-cs-0.4-rhasspy.zip',
    'cs_CZ':
        'https://alphacephei.com/vosk/models/vosk-model-small-cs-0.4-rhasspy.zip',
    'de': 'https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip',
    'de-DE': 'https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip',
    'de_DE': 'https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip',
    'de-AT': 'https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip',
    'de_AT': 'https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip',
    'de-CH': 'https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip',
    'de_CH': 'https://alphacephei.com/vosk/models/vosk-model-small-de-0.15.zip',
    'el': 'https://alphacephei.com/vosk/models/vosk-model-el-gr-0.7.zip',
    'el-GR': 'https://alphacephei.com/vosk/models/vosk-model-el-gr-0.7.zip',
    'el_GR': 'https://alphacephei.com/vosk/models/vosk-model-el-gr-0.7.zip',
    'en': 'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
    'en-US':
        'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
    'en_US':
        'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
    'es': 'https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip',
    'es-ES': 'https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip',
    'es_ES': 'https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip',
    'fr': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr-FR': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr_FR': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr-BE': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr_BE': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr-CA': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr_CA': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr-CH': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr_CH': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'hi': 'https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip',
    'hi-IN': 'https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip',
    'hi_IN': 'https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip',
    'id': 'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
    'it': 'https://alphacephei.com/vosk/models/vosk-model-small-it-0.22.zip',
    'it-IT': 'https://alphacephei.com/vosk/models/vosk-model-small-it-0.22.zip',
    'it_IT': 'https://alphacephei.com/vosk/models/vosk-model-small-it-0.22.zip',
    'it-CH': 'https://alphacephei.com/vosk/models/vosk-model-small-it-0.22.zip',
    'it_CH': 'https://alphacephei.com/vosk/models/vosk-model-small-it-0.22.zip',
    'ja': 'https://alphacephei.com/vosk/models/vosk-model-small-ja-0.22.zip',
    'ja-JP': 'https://alphacephei.com/vosk/models/vosk-model-small-ja-0.22.zip',
    'ja_JP': 'https://alphacephei.com/vosk/models/vosk-model-small-ja-0.22.zip',
    'ko': 'https://alphacephei.com/vosk/models/vosk-model-small-ko-0.22.zip',
    'ko-KR': 'https://alphacephei.com/vosk/models/vosk-model-small-ko-0.22.zip',
    'ko_KR': 'https://alphacephei.com/vosk/models/vosk-model-small-ko-0.22.zip',
    'nl': 'https://alphacephei.com/vosk/models/vosk-model-small-nl-0.22.zip',
    'nl-NL': 'https://alphacephei.com/vosk/models/vosk-model-small-nl-0.22.zip',
    'nl_NL': 'https://alphacephei.com/vosk/models/vosk-model-small-nl-0.22.zip',
    'nl-BE': 'https://alphacephei.com/vosk/models/vosk-model-small-nl-0.22.zip',
    'nl_BE': 'https://alphacephei.com/vosk/models/vosk-model-small-nl-0.22.zip',
    'pl': 'https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip',
    'pl-PL': 'https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip',
    'pl_PL': 'https://alphacephei.com/vosk/models/vosk-model-small-pl-0.22.zip',
    'pt': 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip',
    'pt-PT': 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip',
    'pt_PT': 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip',
    'pt-BR': 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip',
    'pt_BR': 'https://alphacephei.com/vosk/models/vosk-model-small-pt-0.3.zip',
    'ru': 'https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip',
    'ru-RU': 'https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip',
    'ru_RU': 'https://alphacephei.com/vosk/models/vosk-model-small-ru-0.22.zip',
    'sk':
        'https://alphacephei.com/vosk/models/vosk-model-small-cs-0.4-rhasspy.zip',
    'sk-SK':
        'https://alphacephei.com/vosk/models/vosk-model-small-cs-0.4-rhasspy.zip',
    'sk_SK':
        'https://alphacephei.com/vosk/models/vosk-model-small-cs-0.4-rhasspy.zip',
    'sv':
        'https://alphacephei.com/vosk/models/vosk-model-small-sv-rhasspy-0.15.zip',
    'sv-SE':
        'https://alphacephei.com/vosk/models/vosk-model-small-sv-rhasspy-0.15.zip',
    'sv_SE':
        'https://alphacephei.com/vosk/models/vosk-model-small-sv-rhasspy-0.15.zip',
    'tr': 'https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip',
    'tr-TR': 'https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip',
    'tr_TR': 'https://alphacephei.com/vosk/models/vosk-model-small-tr-0.3.zip',
    'uk':
        'https://alphacephei.com/vosk/models/vosk-model-small-uk-v3-small.zip',
    'uk-UA':
        'https://alphacephei.com/vosk/models/vosk-model-small-uk-v3-small.zip',
    'uk_UA':
        'https://alphacephei.com/vosk/models/vosk-model-small-uk-v3-small.zip',
    'vi': 'https://alphacephei.com/vosk/models/vosk-model-small-vn-0.4.zip',
    'vi-VN': 'https://alphacephei.com/vosk/models/vosk-model-small-vn-0.4.zip',
    'vi_VN': 'https://alphacephei.com/vosk/models/vosk-model-small-vn-0.4.zip',
    'wuu': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'wuu-CN':
        'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'wuu_CN':
        'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'yue': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'yue-CN':
        'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'yue_CN':
        'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'zh': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'zh-CN': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'zh_CN': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'zh-HK': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'zh_HK': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'zh-TW': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'zh_TW': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
  };

  /// Fallback mapping for locales without a dedicated Vosk model.
  static const Map<String, String> _voskFallbackLanguages = <String, String>{
    'da': 'sv',
    'fi': 'sv',
    'he': 'en',
    'hi-latn': 'hi',
    'hr': 'en',
    'hu': 'en',
    'id': 'en',
    'ms': 'id',
    'nb': 'sv',
    'ro': 'it',
    'th': 'en',
    'wuu': 'zh',
    'yue': 'zh',
  };

  /// Resolve a display label for [locale], falling back to the raw code.
  static String labelFor(String locale) => labels[locale] ?? locale;

  /// Resolve the default Vosk model URL for [locale], falling back to the
  /// language code when a region-specific entry is not available.
  static String? voskModelUrlFor(String locale) {
    if (locale.isEmpty) {
      return voskModelUrls[defaultLocale];
    }

    final trimmed = locale.trim();
    if (trimmed.isEmpty) {
      return voskModelUrls[defaultLocale];
    }

    final hyphenated = trimmed.replaceAll('_', '-');
    final underscored = trimmed.replaceAll('-', '_');
    final languageOnly = hyphenated.split('-').first.toLowerCase();

    final candidates = <String>{trimmed, hyphenated, underscored, languageOnly};

    for (final candidate in candidates) {
      final resolved = voskModelUrls[candidate];
      if (resolved != null) {
        return resolved;
      }
    }

    final fallbackLanguage =
        _voskFallbackLanguages[languageOnly] ??
        _voskFallbackLanguages[languageOnly.toLowerCase()];
    if (fallbackLanguage != null && fallbackLanguage != languageOnly) {
      return voskModelUrlFor(fallbackLanguage);
    }

    return voskModelUrls[defaultLocale];
  }
}
