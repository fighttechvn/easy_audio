import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

class RecordingCardWidget extends StatelessWidget {
  const RecordingCardWidget({
    super.key,
    required this.recording,
    required this.isSelected,
    required this.isPlaying,
    required this.onPressed,
  });

  final RecordingResult recording;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderColor = recording.wasRecovered
        ? Colors.green.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: isSelected ? 0.35 : 0.1);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  recording.wasRecovered ? Icons.restore : Icons.audio_file,
                  color: recording.wasRecovered
                      ? Colors.green
                      : const Color(0xFF6C5CE7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recording.formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (recording.hasFile)
                  Icon(
                    isSelected
                        ? (isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded)
                        : Icons.play_circle_outline_rounded,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: 18,
                  ),
              ],
            ),
            if (recording.formattedFileSize != null) ...[
              const SizedBox(height: 4),
              Text(
                recording.formattedFileSize ?? 'N/A',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
            if (recording.hasTranscript)
              Text(
                recording.transcript!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
