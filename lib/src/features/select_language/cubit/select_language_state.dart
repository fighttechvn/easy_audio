import '../../../domain/entities/supported_locale.dart';

class SelectLanguageState {
  const SelectLanguageState({
    required this.loading,
    required this.allLocales,
    required this.recentLocales,
    required this.filteredRecent,
    required this.filteredAll,
    required this.query,
    required this.selectedLocaleId,
  });

  factory SelectLanguageState.initial() {
    return const SelectLanguageState(
      loading: true,
      allLocales: <SupportedLocale>[],
      recentLocales: <SupportedLocale>[],
      filteredRecent: <SupportedLocale>[],
      filteredAll: <SupportedLocale>[],
      query: '',
      selectedLocaleId: null,
    );
  }

  final bool loading;
  final List<SupportedLocale> allLocales;
  final List<SupportedLocale> recentLocales;
  final List<SupportedLocale> filteredRecent;
  final List<SupportedLocale> filteredAll;
  final String query;
  final String? selectedLocaleId;

  bool get showRecent => filteredRecent.isNotEmpty;

  SelectLanguageState copyWith({
    bool? loading,
    List<SupportedLocale>? allLocales,
    List<SupportedLocale>? recentLocales,
    List<SupportedLocale>? filteredRecent,
    List<SupportedLocale>? filteredAll,
    String? query,
    String? selectedLocaleId,
  }) {
    return SelectLanguageState(
      loading: loading ?? this.loading,
      allLocales: allLocales ?? this.allLocales,
      recentLocales: recentLocales ?? this.recentLocales,
      filteredRecent: filteredRecent ?? this.filteredRecent,
      filteredAll: filteredAll ?? this.filteredAll,
      query: query ?? this.query,
      selectedLocaleId: selectedLocaleId ?? this.selectedLocaleId,
    );
  }
}
