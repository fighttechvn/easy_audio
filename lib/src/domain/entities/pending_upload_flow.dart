import 'pending_recording.dart';

enum PendingUploadStartStatus { ok, notFound, alreadyUploading, fileMissing }

class PendingUploadStartResult {
  const PendingUploadStartResult._({
    required this.status,
    this.recording,
    this.error,
    this.appointmentIdEmr,
  });

  const PendingUploadStartResult.ok(PendingRecording recording)
      : this._(status: PendingUploadStartStatus.ok, recording: recording);

  const PendingUploadStartResult.notFound()
      : this._(status: PendingUploadStartStatus.notFound);

  const PendingUploadStartResult.alreadyUploading()
      : this._(status: PendingUploadStartStatus.alreadyUploading);

  const PendingUploadStartResult.fileMissing({
    required Object error,
    required String appointmentIdEmr,
  }) : this._(
          status: PendingUploadStartStatus.fileMissing,
          error: error,
          appointmentIdEmr: appointmentIdEmr,
        );

  final PendingUploadStartStatus status;
  final PendingRecording? recording;
  final Object? error;
  final String? appointmentIdEmr;
}

enum PendingUploadRunStatus { success, failure, notFound }

class PendingUploadRunResult {
  const PendingUploadRunResult._({
    required this.status,
    required this.pendingId,
    this.appointmentIdEmr,
    this.error,
  });

  const PendingUploadRunResult.success({
    required String pendingId,
    required String appointmentIdEmr,
  }) : this._(
          status: PendingUploadRunStatus.success,
          pendingId: pendingId,
          appointmentIdEmr: appointmentIdEmr,
        );

  const PendingUploadRunResult.failure({
    required String pendingId,
    required Object error,
    String? appointmentIdEmr,
  }) : this._(
          status: PendingUploadRunStatus.failure,
          pendingId: pendingId,
          appointmentIdEmr: appointmentIdEmr,
          error: error,
        );

  const PendingUploadRunResult.notFound({required String pendingId})
      : this._(status: PendingUploadRunStatus.notFound, pendingId: pendingId);

  final PendingUploadRunStatus status;
  final String pendingId;
  final String? appointmentIdEmr;
  final Object? error;
}
