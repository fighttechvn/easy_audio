import 'dart:async';
import 'dart:io';

import 'package:easy_audio/easy_audio.dart';

import '../../domain/entities/server_recording.dart';

/// Simulate a server-side store:
/// - Upload copies the local file into a dedicated "uploaded" folder.
/// - Listing reads those uploaded files back.
class FakeServerStore {
  FakeServerStore(this._pendingRecordingsUsecase);

  final PendingRecordingsUsecase _pendingRecordingsUsecase;

  Directory? _uploadedDir;

  Future<Directory> _ensureUploadedDir() async {
    await _pendingRecordingsUsecase.init();

    final baseDir = Directory(_pendingRecordingsUsecase.baseDirectoryPath);
    final uploadedDir = Directory('${baseDir.path}/uploaded');

    if (!await uploadedDir.exists()) {
      await uploadedDir.create(recursive: true);
    }

    _uploadedDir = uploadedDir;
    return uploadedDir;
  }

  Future<List<ServerRecording>> listForAppointment(
    String appointmentIdEmr,
  ) async {
    final dir = _uploadedDir ?? await _ensureUploadedDir();
    if (!await dir.exists()) {
      return const <ServerRecording>[];
    }

    final items = <ServerRecording>[];
    final key = appointmentIdEmr.trim();

    await for (final entity in dir.list()) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.isNotEmpty
          ? entity.uri.pathSegments.last
          : '';
      if (name.isEmpty || !name.contains(key)) {
        continue;
      }

      final stat = await entity.stat();
      items.add(
        ServerRecording(
          source: Uri.file(entity.path).toString(),
          createdAt: stat.modified,
          fileSizeBytes: stat.size,
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> uploadAndPersistCopy({
    required String appointmentIdEmr,
    String? content,
    required int appointmentId,
    required File record,
    required String locale,
    void Function(int sentBytes, int totalBytes)? onSendProgress,
  }) async {
    final totalBytes = await record.length();
    const steps = 20;

    for (var i = 1; i <= steps; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final sent = (totalBytes * i / steps).round();
      onSendProgress?.call(sent, totalBytes);
    }

    final dir = await _ensureUploadedDir();

    final originalName = record.uri.pathSegments.isNotEmpty
        ? record.uri.pathSegments.last
        : 'record.m4a';

    final safeEmr = appointmentIdEmr.trim().replaceAll(RegExp(r'\s+'), '_');

    final outPath =
        '${dir.path}/${safeEmr}_${DateTime.now().millisecondsSinceEpoch}_$originalName';

    await record.copy(outPath);
  }
}
