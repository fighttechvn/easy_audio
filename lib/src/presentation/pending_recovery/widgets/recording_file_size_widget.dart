import 'package:flutter/material.dart';

import '../../../core/services/pending_recording_service.dart';
import '../../../core/utils/file_utils.dart';

class RecordingFileSizeWidget extends StatelessWidget {
  const RecordingFileSizeWidget({
    super.key,
    required this.recording,
    this.builder,
  });
  final PendingRecording recording;
  final Widget Function(int bytes, String sizeText)? builder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<int>(
      future: recording.fileSize,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) {
          return const SizedBox.shrink();
        }
        if (builder != null) {
          return builder!(
              snapshot.data!, FileUtils.getFileSize(snapshot.data!));
        }
        return Row(
          children: [
            Icon(
              Icons.storage_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'File size: ${FileUtils.getFileSize(snapshot.data!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
