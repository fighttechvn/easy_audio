import 'package:flutter/material.dart';

import '../../core/utils/datetime_ext.dart' show RecordAudioDateTimeExt;
import '../../domain/entities/pending_recording.dart';

typedef ProgressForFn = double? Function(String id);
typedef EnqueueUploadFn = void Function(String id);
typedef DeletePendingRecordingFn =
    Future<void> Function(String id, {bool deleteFile});

class PendingRecordCardWidget extends StatelessWidget {
  const PendingRecordCardWidget({
    required this.record,
    required this.progressFor,
    required this.enqueueUpload,
    required this.deletePendingRecording,
    super.key,
  });

  final PendingRecording record;
  final ProgressForFn progressFor;
  final EnqueueUploadFn enqueueUpload;
  final DeletePendingRecordingFn deletePendingRecording;
  @override
  Widget build(BuildContext context) {
    final progress = progressFor(record.id);

    final statusText = switch (record.status) {
      PendingRecordingStatus.pending => 'Pending',
      PendingRecordingStatus.uploading => 'Uploading',
      PendingRecordingStatus.failed => 'Failed',
    };

    final retrySuffix = record.retryCount > 0
        ? ' (retry ${record.retryCount}/3)'
        : '';
    final sizeLine = record.fileSizeText;
    final progressSuffix =
        record.status == PendingRecordingStatus.uploading && progress != null
        ? ' ${(progress * 100).round()}%'
        : '';
    final statusLine =
        '$statusText$progressSuffix$retrySuffix'
        '${sizeLine.isNotEmpty ? ' - $sizeLine' : ''}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text('Audio ${record.createdAt.showConfirmBooking}'),
        subtitle: Text(statusLine),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: record.status == PendingRecordingStatus.uploading
                  ? null
                  : () {
                      enqueueUpload(record.id);
                    },
              icon: const Icon(Icons.upload),
            ),
            IconButton(
              onPressed: () {
                deletePendingRecording(record.id, deleteFile: true);
              },
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }
}
