import 'dart:async';

import 'package:flutter/material.dart';

import 'domain/entities/pending_recording.dart';
import 'features/audio_widget/record_audio_preview_widget.dart';
import 'features/audio_widget/unfinished_recording_dialog.dart';

extension RecordCoordinator on BuildContext {
  Future<bool> confirmCloseRecording({required bool isActiveSession}) async {
    if (!isActiveSession) {
      return true;
    }

    final result = await showDialog<bool>(
      context: this,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard recording?'),
          content: const Text(
            'Closing will stop the current recording and discard it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> showUnfinishedRecordingDialog({
    required PendingRecording record,
    required String languageDisplayName,
    required Future<void> Function() onDiscard,
    required Future<void> Function() onUpload,
  }) {
    return showDialog<void>(
      context: this,
      barrierDismissible: true,
      builder: (dialogContext) {
        return UnfinishedRecordingDialog(
          record: record,
          languageDisplayName: languageDisplayName,
          onLater: () => Navigator.of(dialogContext).maybePop(),
          onDiscard: () {
            Navigator.of(dialogContext).maybePop();
            unawaited(onDiscard());
          },
          onUpload: () {
            Navigator.of(dialogContext).maybePop();
            unawaited(onUpload());
          },
          canPreview: record.filePath.trim().isNotEmpty,
          onPreview: () {
            unawaited(showPendingRecordingPreviewDialog(record: record));
          },
        );
      },
    );
  }

  Future<void> showPendingRecordingPreviewDialog({
    required PendingRecording record,
  }) {
    final fileUri = Uri.file(record.filePath).toString();

    return showDialog<void>(
      context: this,
      barrierDismissible: true,
      builder: (previewContext) {
        final previewTheme = Theme.of(previewContext);
        final previewBg = previewTheme.dialogTheme.backgroundColor ??
            previewTheme.colorScheme.surface;
        final maxHeight = MediaQuery.of(previewContext).size.height * 0.55;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520, maxHeight: maxHeight),
            child: Stack(
              children: [
                Material(
                  color: previewBg,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    child: SingleChildScrollView(
                      child: RecordAudioPreviewWidget(
                        source: fileUri,
                        title: 'Preview',
                        createdAt: record.createdAt,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(previewContext).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
