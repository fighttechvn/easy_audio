import 'dart:io';

import 'package:injectable/injectable.dart';

import '../entities/pending_recording.dart';
import '../entities/pending_upload_flow.dart';
import '../entities/upload_recoding_process_callback.dart';
import '../entities/upload_retry_policy.dart';
import 'pending_recordings_usecase.dart';

@injectable
class PendingUploadUsecase {
  const PendingUploadUsecase(this._pendingRecordingsUsecase);

  final PendingRecordingsUsecase _pendingRecordingsUsecase;

  Future<List<String>> listUploadCandidateIdsForUser(int? userId) async {
    await _pendingRecordingsUsecase.init();

    return _pendingRecordingsUsecase
        .listForUser(userId)
        .where((e) => e.status != PendingRecordingStatus.uploading)
        .map((e) => e.id)
        .toList(growable: false);
  }

  Future<PendingUploadStartResult> tryStartUpload(String id) async {
    await _pendingRecordingsUsecase.init();

    final current = _pendingRecordingsUsecase.getById(id);
    if (current == null) {
      return const PendingUploadStartResult.notFound();
    }

    final file = File(current.filePath);
    if (!await file.exists()) {
      await _pendingRecordingsUsecase.upsert(
        current.markFailed(
          error: 'File not found',
          retryCount: current.retryCount + 1,
        ),
      );

      return PendingUploadStartResult.fileMissing(
        error: const FileSystemException('File not found'),
        id: current.dataRecord.id.trim(),
      );
    }

    final uploading = current.markUploading();
    await _pendingRecordingsUsecase.upsert(uploading);

    return PendingUploadStartResult.ok(uploading);
  }

  Future<PendingUploadRunResult> runUploadRetries({
    required String pendingId,
    required UploadRetryPolicy retryPolicy,
    required UploadRecordingProgressCallback uploadRecordingProgress,
    required void Function(double progress) onProgress,
  }) async {
    await _pendingRecordingsUsecase.init();

    var latest = _pendingRecordingsUsecase.getById(pendingId);
    if (latest == null) {
      return PendingUploadRunResult.notFound(pendingId: pendingId);
    }

    var attempt = 0;

    while (attempt < retryPolicy.maxAttempts) {
      try {
        latest = _pendingRecordingsUsecase.getById(pendingId);
        if (latest == null) {
          return PendingUploadRunResult.notFound(pendingId: pendingId);
        }

        await _pendingRecordingsUsecase.upload(
          recording: latest,
          onProgress: onProgress,
          uploadRecordingProgress: uploadRecordingProgress,
        );

        await _pendingRecordingsUsecase.deleteById(pendingId, deleteFile: true);

        return PendingUploadRunResult.success(
          pendingId: pendingId,
          id: latest.dataRecord.id.trim(),
        );
      } catch (e) {
        attempt += 1;

        latest = _pendingRecordingsUsecase.getById(pendingId);
        if (latest == null) {
          return PendingUploadRunResult.notFound(pendingId: pendingId);
        }

        final isLast = attempt >= retryPolicy.maxAttempts;

        await _pendingRecordingsUsecase.upsert(
          latest.markPendingAfterFailure(
            error: e.toString(),
            retryCount: attempt,
            isLastAttempt: isLast,
          ),
        );

        if (isLast) {
          return PendingUploadRunResult.failure(
            pendingId: pendingId,
            error: e,
            id: latest.dataRecord.id.trim(),
          );
        }

        await Future<void>.delayed(retryPolicy.delay);
      }
    }

    return PendingUploadRunResult.failure(
      pendingId: pendingId,
      error: StateError('Upload attempts exhausted unexpectedly'),
      id: latest?.dataRecord.id.trim(),
    );
  }
}
