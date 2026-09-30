import 'package:flutter/foundation.dart';

import 'crash_recovery_effect.dart';

@immutable
class CrashRecoveryUiState {
  const CrashRecoveryUiState({
    this.isRunning = false,
    this.effect,
    this.effectId = 0,
  });

  final bool isRunning;
  final CrashRecoveryEffect? effect;
  final int effectId;

  CrashRecoveryUiState copyWith({
    bool? isRunning,
    CrashRecoveryEffect? effect,
    int? effectId,
  }) {
    return CrashRecoveryUiState(
      isRunning: isRunning ?? this.isRunning,
      effect: effect ?? this.effect,
      effectId: effectId ?? this.effectId,
    );
  }
}
