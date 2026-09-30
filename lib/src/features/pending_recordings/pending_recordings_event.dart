part of 'pending_recordings_bloc.dart';

@immutable
sealed class PendingRecordingsEvent {
  const PendingRecordingsEvent();
}

final class PendingRecordingsInitRequested extends PendingRecordingsEvent {
  const PendingRecordingsInitRequested({this.completer});

  final Completer<void>? completer;
}

final class PendingRecordingsRefreshRequested extends PendingRecordingsEvent {
  const PendingRecordingsRefreshRequested({this.completer});

  final Completer<void>? completer;
}

final class PendingRecordingsDeleteRequested extends PendingRecordingsEvent {
  const PendingRecordingsDeleteRequested({
    required this.id,
    required this.deleteFile,
    this.completer,
  });

  final String id;
  final bool deleteFile;
  final Completer<void>? completer;
}
