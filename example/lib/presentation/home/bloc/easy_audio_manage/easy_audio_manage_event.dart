import 'package:easy_audio/easy_audio.dart';
import 'package:equatable/equatable.dart';

abstract class EasyAudioManageEvent extends Equatable {
  const EasyAudioManageEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize EasyAudio service
class EasyAudioManageStarted extends EasyAudioManageEvent {
  const EasyAudioManageStarted();
}

/// Select recording mode
class EasyAudioManageModeSelected extends EasyAudioManageEvent {
  const EasyAudioManageModeSelected(this.mode);

  final EasyAudioMode mode;

  @override
  List<Object?> get props => [mode];
}

/// Select locale
class EasyAudioManageLocaleSelected extends EasyAudioManageEvent {
  const EasyAudioManageLocaleSelected(this.locale);

  final String? locale;

  @override
  List<Object?> get props => [locale];
}

/// Request supported locales
class EasyAudioManageLocalesRequested extends EasyAudioManageEvent {
  const EasyAudioManageLocalesRequested();
}

/// Internal: locales loaded
class EasyAudioManageLocalesLoaded extends EasyAudioManageEvent {
  const EasyAudioManageLocalesLoaded(this.locales);

  final List<SupportedLocale> locales;

  @override
  List<Object?> get props => [locales.length];
}
