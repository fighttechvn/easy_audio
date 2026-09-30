import 'dart:io';

import '../entities/pending_recording.dart';
import '../entities/record_session.dart';

abstract class PendingRecordingRepository {
  Future<void> init();
  String get baseDirectoryPath;

  File fileFor(String fileName);
  List<PendingRecording> listForUser(int? userId);
  List<PendingRecording> listForDataId({
    required String dataId,
    required int? userId,
  });
  PendingRecording? getById(String id);
  Future<void> upsert(PendingRecording recording);
  Future<void> deleteById(String id, {bool deleteFile = false});

  Future<void> pruneMissingFiles();

  Future<void> refreshFileSizes();

  Future<void> saveSessionToCache(RecordSession session);
  Future<void> clearSessionCache();
  Future<RecordSession?> loadSessionFromCache();
}
