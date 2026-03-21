import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/server_recording.dart';
import 'empty_hint.dart';
import 'section_header.dart';
import 'server_recording_tile.dart';

class CustomerRecordFlowBody extends StatelessWidget {
  const CustomerRecordFlowBody({
    super.key,
    required this.loadingServer,
    required this.serverItems,
    required this.allPendingCount,
    required this.pendingItems,
    required this.progressFor,
    required this.enqueueUpload,
    required this.deletePendingRecording,
  });

  final bool loadingServer;
  final List<ServerRecording> serverItems;
  final int allPendingCount;
  final List<PendingRecording> pendingItems;
  final double? Function(String) progressFor;
  final void Function(String id) enqueueUpload;
  final Future<void> Function(String id, {bool deleteFile})
  deletePendingRecording;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (loadingServer) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              if (allPendingCount > 0 && pendingItems.isEmpty)
                const EmptyHint(
                  text:
                      'Found pending recordings but all were filtered out by appointmentIdEmr/userId.',
                ),
              const SectionHeader(title: 'Uploaded (simulated server)'),
              if (serverItems.isEmpty)
                const EmptyHint(text: 'No uploaded recordings yet.'),
              for (final item in serverItems)
                ServerRecordingTile(recording: item),
              const SizedBox(height: 8),
              const SectionHeader(title: 'Drafts (pending local)'),
              if (pendingItems.isEmpty)
                const EmptyHint(text: 'No draft recordings yet.'),
              for (final record in pendingItems)
                PendingRecordCardWidget(
                  record: record,
                  progressFor: progressFor,
                  enqueueUpload: enqueueUpload,
                  deletePendingRecording: deletePendingRecording,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
