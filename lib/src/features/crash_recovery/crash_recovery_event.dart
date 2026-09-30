part of 'crash_recovery_bloc.dart';

@immutable
sealed class CrashRecoveryEvent {
  const CrashRecoveryEvent();
}

final class CrashRecoveryRunLoginRequested extends CrashRecoveryEvent {
  const CrashRecoveryRunLoginRequested({
    required this.userId,
    required this.fallbackLocale,
    this.completer,
  });

  final int userId;
  final String fallbackLocale;
  final Completer<void>? completer;
}

final class CrashRecoveryDiscardRequested extends CrashRecoveryEvent {
  const CrashRecoveryDiscardRequested({
    required this.pendingId,
    required this.deleteFile,
    this.completer,
  });

  final String pendingId;
  final bool deleteFile;
  final Completer<void>? completer;
}

final class CrashRecoveryUploadRequested extends CrashRecoveryEvent {
  const CrashRecoveryUploadRequested({required this.record, this.completer});

  final PendingRecording record;
  final Completer<void>? completer;
}
