/// Supported locale identifiers for the speech-to-text pipeline.
class SpeechToTextLocales {
  const SpeechToTextLocales._();

  /// Default locale when none is provided by the caller.
  static const String defaultLocale = 'en-US';

  /// Map of internal language identifiers to locale codes.
  static const Map<String, String> supported = <String, String>{
    'languageEng': 'en-US',
    'langueCn': 'zh-CN',
    'langueFr': 'fr-FR',
    'langueEs': 'es-ES',
    'langueVn': 'vi_VN',
    'langueArabic': 'ar-SA',
    'langueIndia': 'hi-IN',
  };

  /// Human readable labels for the supported locales.
  static const Map<String, String> labels = <String, String>{
    'en-US': 'English (US)',
    'zh-CN': '中文 (普通话)',
    'fr-FR': 'Français',
    'es-ES': 'Español',
    'vi_VN': 'Tiếng Việt',
    'ar-SA': 'العربية',
    'hi-IN': 'हिन्दी',
  };

  /// Default Vosk model URLs keyed by locale identifiers.
  /// Android builds preload the `en-US` and `vi-VN` entries by default; supply
  /// a custom `preloadLocales` list to override.
  static const Map<String, String> voskModelUrls = <String, String>{
    'en': 'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
    'en-US':
        'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
    'en_US':
        'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip',
    'zh': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'zh-CN': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'zh_CN': 'https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip',
    'fr': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr-FR': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'fr_FR': 'https://alphacephei.com/vosk/models/vosk-model-small-fr-0.22.zip',
    'es': 'https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip',
    'es-ES': 'https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip',
    'es_ES': 'https://alphacephei.com/vosk/models/vosk-model-small-es-0.42.zip',
    'vi': 'https://alphacephei.com/vosk/models/vosk-model-small-vn-0.3.zip',
    'vi-VN': 'https://alphacephei.com/vosk/models/vosk-model-small-vn-0.3.zip',
    'vi_VN': 'https://alphacephei.com/vosk/models/vosk-model-small-vn-0.3.zip',
    'ar': 'https://alphacephei.com/vosk/models/vosk-model-small-ar-0.22.zip',
    'ar-SA': 'https://alphacephei.com/vosk/models/vosk-model-small-ar-0.22.zip',
    'ar_SA': 'https://alphacephei.com/vosk/models/vosk-model-small-ar-0.22.zip',
    'hi': 'https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip',
    'hi-IN': 'https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip',
    'hi_IN': 'https://alphacephei.com/vosk/models/vosk-model-small-hi-0.22.zip',
  };

  /// Resolve a display label for [locale], falling back to the raw code.
  static String labelFor(String locale) => labels[locale] ?? locale;

  /// Resolve the default Vosk model URL for [locale], falling back to the
  /// language code when a region-specific entry is not available.
  static String? voskModelUrlFor(String locale) {
    if (locale.isEmpty) {
      return voskModelUrls[defaultLocale];
    }
    final direct = voskModelUrls[locale];
    if (direct != null) {
      return direct;
    }
    final hyphenated = locale.replaceAll('_', '-');
    final fromHyphen = voskModelUrls[hyphenated];
    if (fromHyphen != null) {
      return fromHyphen;
    }
    final underscored = locale.replaceAll('-', '_');
    final fromUnderscore = voskModelUrls[underscored];
    if (fromUnderscore != null) {
      return fromUnderscore;
    }
    final languageOnly = hyphenated.split('-').first;
    return voskModelUrls[languageOnly];
  }
}
