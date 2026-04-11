part of 'pending_recordings_bloc.dart';

@immutable
sealed class PendingRecordingsState {
  const PendingRecordingsState({required this.uiState});

  final PendingRecordingsUiState uiState;
}

final class PendingRecordingsInitial extends PendingRecordingsState {
  const PendingRecordingsInitial({required super.uiState});
}

final class PendingRecordingsLoading extends PendingRecordingsState {
  const PendingRecordingsLoading({required super.uiState});
}

final class PendingRecordingsReady extends PendingRecordingsState {
  const PendingRecordingsReady({required super.uiState});
}

final class PendingRecordingsFailure extends PendingRecordingsState {
  const PendingRecordingsFailure({required super.uiState, required this.error});

  final Object error;
}
