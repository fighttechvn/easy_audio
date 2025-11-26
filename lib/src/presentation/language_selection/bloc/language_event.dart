part of 'language_bloc.dart';

@immutable
sealed class LanguageEvent {}

class LoadSupportedLanguagesEvent extends LanguageEvent {
  LoadSupportedLanguagesEvent({
    required this.currentLocale,
  });

  final String currentLocale;
}

class PrepareLanguageModelEvent extends LanguageEvent {
  PrepareLanguageModelEvent({
    required this.locale,
  });

  final String locale;
}

class ResetLanguageEvent extends LanguageEvent {}
