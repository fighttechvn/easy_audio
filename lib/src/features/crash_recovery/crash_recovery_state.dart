part of 'crash_recovery_bloc.dart';

@immutable
sealed class CrashRecoveryState {
  const CrashRecoveryState({required this.uiState});

  final CrashRecoveryUiState uiState;
}

final class CrashRecoveryInitial extends CrashRecoveryState {
  const CrashRecoveryInitial({required super.uiState});
}
