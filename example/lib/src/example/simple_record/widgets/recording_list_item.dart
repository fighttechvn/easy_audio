import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

class RecordingListItem extends StatelessWidget {
  const RecordingListItem({
    super.key,
    required this.index,
    required this.recording,
    required this.onDelete,
  });

  final int index;
  final RecordData recording;
  final VoidCallback onDelete;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              'Recording ${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Duration: ${_formatDuration(recording.totalTime)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ),
          if (recording.content?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Transcript:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recording.content!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          // Audio player
          SimpleAudioPlayer(
            url: recording.url,
            title: 'Recording ${index + 1}',
            expanded: false,
          ),
        ],
      ),
    );
  }
}
