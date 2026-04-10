import 'package:flutter/material.dart';

import '../../domain/entities/pending_recording.dart';
import 'pending_record_card_widget.dart';

typedef ListForContextIdFn =
    List<PendingRecording> Function({
      required String contextId,
      required int? userId,
    });

class HeaderCustomerRecordWidget extends StatelessWidget {
  const HeaderCustomerRecordWidget({
    super.key,
    required this.contextId,
    required this.progressFor,
    required this.enqueueUpload,
    required this.deletePendingRecording,
    required this.listForContextId,
    required this.userId,
  });

  final String? contextId;
  final int? userId;
  final ProgressForFn progressFor;
  final EnqueueUploadFn enqueueUpload;
  final DeletePendingRecordingFn deletePendingRecording;
  final ListForContextIdFn listForContextId;

  @override
  Widget build(BuildContext context) {
    if (contextId == null || contextId!.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = listForContextId(contextId: contextId!, userId: userId);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Pending recordings',
              style: theme.textTheme.titleMedium,
            ),
          ),
          ...items.map((e) {
            return PendingRecordCardWidget(
              record: e,
              progressFor: progressFor,
              enqueueUpload: enqueueUpload,
              deletePendingRecording: deletePendingRecording,
            );
          }),
        ],
      ),
    );
  }
}
