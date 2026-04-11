import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/foundation.dart';

import '../../../../domain/entities/home_data.dart';

/// Data class cho EasyAudioManage UI
@immutable
class EasyAudioManageStateUi {
  const EasyAudioManageStateUi({
    required this.selectedMode,
    required this.selectedLocale,
    required this.supportedLocales,
    required this.isLocalesLoading,
  });

  factory EasyAudioManageStateUi.initial() => const EasyAudioManageStateUi(
    selectedMode: EasyAudioMode.recordOnly,
    selectedLocale: null,
    supportedLocales: <SupportedLocale>[],
    isLocalesLoading: false,
  );

  final EasyAudioMode selectedMode;
  final String? selectedLocale;
  final List<SupportedLocale> supportedLocales;
  final bool isLocalesLoading;

  EasyAudioManageStateUi copyWith({
    EasyAudioMode? selectedMode,
    String? selectedLocale,
    List<SupportedLocale>? supportedLocales,
    bool? isLocalesLoading,
  }) {
    return EasyAudioManageStateUi(
      selectedMode: selectedMode ?? this.selectedMode,
      selectedLocale: selectedLocale ?? this.selectedLocale,
      supportedLocales: supportedLocales ?? this.supportedLocales,
      isLocalesLoading: isLocalesLoading ?? this.isLocalesLoading,
    );
  }
}

// ============================================================================
// EASY AUDIO MANAGE STATES
// ============================================================================

@immutable
sealed class EasyAudioManageState {
  const EasyAudioManageState({required this.ui, this.snackBarMessage});

  final EasyAudioManageStateUi ui;
  final HomeSnackBarMessage? snackBarMessage;
}

/// Initial state
@immutable
class EasyAudioManageInitialState extends EasyAudioManageState {
  const EasyAudioManageInitialState({required super.ui, super.snackBarMessage});
}

/// Initializing state
@immutable
class EasyAudioManageInitializingState extends EasyAudioManageState {
  const EasyAudioManageInitializingState({
    required super.ui,
    super.snackBarMessage,
  });
}

/// Ready state - initialized and ready to use
@immutable
class EasyAudioManageReadyState extends EasyAudioManageState {
  const EasyAudioManageReadyState({
    required super.ui,
    super.snackBarMessage,
    this.recoveredRecording,
  });

  final RecordingResult? recoveredRecording;
}

/// Changing mode state
@immutable
class EasyAudioManageChangingModeState extends EasyAudioManageState {
  const EasyAudioManageChangingModeState({
    required super.ui,
    super.snackBarMessage,
  });
}

/// Error state
@immutable
class EasyAudioManageErrorState extends EasyAudioManageState {
  const EasyAudioManageErrorState({
    required super.ui,
    super.snackBarMessage,
    required this.message,
    required this.errorType,
  });

  final String message;
  final HomeErrorType errorType;
}
