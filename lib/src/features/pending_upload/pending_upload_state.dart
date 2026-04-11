part of 'pending_upload_bloc.dart';

@immutable
sealed class PendingUploadState {
  const PendingUploadState({required this.uiState});

  final PendingUploadUiState uiState;

  // Backward-compatible convenience accessors (old Cubit state fields).
  Map<String, PendingUploadItem> get items => uiState.items;
  String? get activeUploadId => uiState.activeUploadId;
  double get activeProgress => uiState.activeProgress;
  PendingUploadResult? get lastResult => uiState.lastResult;
}

final class PendingUploadInitial extends PendingUploadState {
  const PendingUploadInitial({required super.uiState});
}
