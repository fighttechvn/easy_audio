import 'pending_recording.dart';

enum PendingUploadStartStatus { ok, notFound, alreadyUploading, fileMissing }

class PendingUploadStartResult {
  const PendingUploadStartResult._({
    required this.status,
    this.recording,
    this.error,
    this.id,
  });

  const PendingUploadStartResult.ok(PendingRecording recording)
    : this._(status: PendingUploadStartStatus.ok, recording: recording);

  const PendingUploadStartResult.notFound()
    : this._(status: PendingUploadStartStatus.notFound);

  const PendingUploadStartResult.alreadyUploading()
    : this._(status: PendingUploadStartStatus.alreadyUploading);

  const PendingUploadStartResult.fileMissing({
    required Object error,
    required String id,
  }) : this._(
         status: PendingUploadStartStatus.fileMissing,
         error: error,
         id: id,
       );

  final PendingUploadStartStatus status;
  final PendingRecording? recording;
  final Object? error;
  final String? id;
}

enum PendingUploadRunStatus { success, failure, notFound }

class PendingUploadRunResult {
  const PendingUploadRunResult._({
    required this.status,
    required this.pendingId,
    this.id,
    this.error,
  });

  const PendingUploadRunResult.success({
    required String pendingId,
    required String id,
  }) : this._(
         status: PendingUploadRunStatus.success,
         pendingId: pendingId,
         id: id,
       );

  const PendingUploadRunResult.failure({
    required String pendingId,
    required Object error,
    String? id,
  }) : this._(
         status: PendingUploadRunStatus.failure,
         pendingId: pendingId,
         id: id,
         error: error,
       );

  const PendingUploadRunResult.notFound({required String pendingId})
    : this._(status: PendingUploadRunStatus.notFound, pendingId: pendingId);

  final PendingUploadRunStatus status;
  final String pendingId;
  final String? id;
  final Object? error;
}
