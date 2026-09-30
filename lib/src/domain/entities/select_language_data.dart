import 'supported_locale.dart';

class SelectLanguageData {
  const SelectLanguageData({
    required this.allLocales,
    required this.recentLocales,
    required this.selectedLocaleId,
  });

  final List<SupportedLocale> allLocales;
  final List<SupportedLocale> recentLocales;
  final String? selectedLocaleId;
}
