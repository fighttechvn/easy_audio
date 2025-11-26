part of 'language_bloc.dart';

@immutable
class LanguageStateUI {
  const LanguageStateUI({
    this.currentLocale = 'en-US',
    this.currentLanguageLabel = 'English (United States)',
    this.supportedLanguages = const {},
  });

  final String currentLocale;

  final String currentLanguageLabel;

  final Map<String, String> supportedLanguages;

  LanguageStateUI copyWith({
    String? currentLocale,
    String? currentLanguageLabel,
    Map<String, String>? supportedLanguages,
  }) {
    return LanguageStateUI(
      currentLocale: currentLocale ?? this.currentLocale,
      currentLanguageLabel: currentLanguageLabel ?? this.currentLanguageLabel,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
    );
  }
}

@immutable
abstract class LanguageState {
  const LanguageState(this.stateUI);

  final LanguageStateUI stateUI;
}

class LanguageInitial extends LanguageState {
  const LanguageInitial([super.stateUI = const LanguageStateUI()]);
}

class LanguageLoading extends LanguageState {
  const LanguageLoading(super.stateUI);
}

class LanguageLoaded extends LanguageState {
  const LanguageLoaded(super.stateUI);
}

class LanguageLoadError extends LanguageState {
  const LanguageLoadError(
    super.stateUI,
    this.message,
    this.error,
  );

  final String message;
  final dynamic error;
}

class LanguageModelPreparing extends LanguageState {
  const LanguageModelPreparing(super.stateUI);
}

class LanguageModelPrepared extends LanguageState {
  const LanguageModelPrepared(super.stateUI);
}

class LanguageModelError extends LanguageState {
  const LanguageModelError(
    super.stateUI,
    this.message,
    this.error,
  );

  final String message;
  final dynamic error;
}
