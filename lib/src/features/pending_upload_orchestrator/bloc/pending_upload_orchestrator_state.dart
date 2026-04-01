part of 'pending_upload_orchestrator_bloc.dart';

@immutable
sealed class PendingUploadOrchestratorState {
  const PendingUploadOrchestratorState({
    required this.uiState,
  });

  final PendingUploadOrchestratorUiState uiState;
}

final class PendingUploadOrchestratorInitial
    extends PendingUploadOrchestratorState {
  const PendingUploadOrchestratorInitial({
    required super.uiState,
  });
}
