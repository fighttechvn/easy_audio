import 'package:flutter/material.dart';

import '../../../core/utils/format_utils.dart';

/// Simple audio preview widget for pending recordings.
class SimpleAudioPreview extends StatelessWidget {
  const SimpleAudioPreview({
    super.key,
    required this.filePath,
    required this.duration,
  });

  final String filePath;
  final Duration duration;

  String get _formattedDuration => FormatUtils.formatDuration(duration);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.audio_file,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Recording',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: $_formattedDuration',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
