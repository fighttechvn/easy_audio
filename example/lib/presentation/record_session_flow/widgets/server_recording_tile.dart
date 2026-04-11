import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/server_recording.dart';

class ServerRecordingTile extends StatelessWidget {
  const ServerRecordingTile({super.key, required this.recording});

  final ServerRecording recording;

  @override
  Widget build(BuildContext context) {
    final playback = AudioPlaybackManager.instance;

    return ValueListenableBuilder<AudioPlaybackSnapshot>(
      valueListenable: playback.snapshot,
      builder: (context, snap, _) {
        final isActive = snap.currentUrl == recording.source;
        final isPlaying = isActive && snap.isPlaying;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text('Audio ${formatDateTime(recording.createdAt)}'),
            subtitle: Text(formatBytes(recording.fileSizeBytes)),
            trailing: IconButton(
              onPressed: () async {
                await playback.toggleSource(recording.source);
              },
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            ),
          ),
        );
      },
    );
  }
}
