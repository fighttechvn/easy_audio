import 'dart:io';

import 'package:injectable/injectable.dart';

import '../entities/pending_recording.dart';
import '../entities/record_session.dart';
import '../entities/upload_recoding_process_callback.dart';
import '../repository/pending_recording_repository.dart';

@injectable
class PendingRecordingsUsecase {
  const PendingRecordingsUsecase(this._repository);

  final PendingRecordingRepository _repository;

  Future<void> init() => _repository.init();

  String get baseDirectoryPath => _repository.baseDirectoryPath;

  File fileFor(String fileName) => _repository.fileFor(fileName);

  List<PendingRecording> listForUser(int? userId) {
    return _repository.listForUser(userId);
  }

  List<PendingRecording> listForDataId({
    required String dataId,
    required int? userId,
  }) {
    return _repository.listForDataId(dataId: dataId, userId: userId);
  }

  PendingRecording? getById(String id) => _repository.getById(id);

  Future<void> upsert(PendingRecording recording) =>
      _repository.upsert(recording);

  Future<void> deleteById(String id, {bool deleteFile = false}) =>
      _repository.deleteById(id, deleteFile: deleteFile);

  Future<void> pruneMissingFiles() => _repository.pruneMissingFiles();

  Future<void> refreshFileSizes() => _repository.refreshFileSizes();

  Future<void> upload({
    required PendingRecording recording,
    required void Function(double progress) onProgress,
    required UploadRecordingProgressCallback uploadRecordingProgress,
  }) {
    final recordFile = File(recording.filePath);

    return uploadRecordingProgress(
      data: recording.dataRecord,
      record: recordFile,
      locale: recording.locale,
      content: recording.content,
      onSendProgress: (sent, total) {
        if (total <= 0) {
          return;
        }
        onProgress((sent / total).clamp(0.0, 1.0));
      },
    );
  }

  Future<void> saveSessionToCache(RecordSession session) =>
      _repository.saveSessionToCache(session);
  Future<void> clearSessionCache() => _repository.clearSessionCache();
  Future<RecordSession?> loadSessionFromCache() =>
      _repository.loadSessionFromCache();
}
