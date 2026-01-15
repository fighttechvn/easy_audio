import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

import '../format_duration.dart';
import 'control_button_widget.dart';

class PlaybackControlsWidget extends StatelessWidget {
  const PlaybackControlsWidget({
    super.key,
    required this.selectedRecording,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onStop,
    required this.onSeek,
    required this.onClose,
  });

  final RecordingResult? selectedRecording;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final VoidCallback onStop;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final recording = selectedRecording;
    if (recording == null || recording.filePath == null) {
      return const SizedBox.shrink();
    }

    final safeDuration = duration.inMilliseconds > 0 ? duration : Duration.zero;
    final safePosition = position > safeDuration ? safeDuration : position;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.graphic_eq_rounded,
                  color: Color(0xFF6C5CE7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đang phát',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${formatDuration(safePosition)} / ${formatDuration(safeDuration)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF6C5CE7),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: Colors.white,
                overlayColor: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
              ),
              child: Slider(
                value: safeDuration.inMilliseconds == 0
                    ? 0
                    : safePosition.inMilliseconds.toDouble(),
                min: 0,
                max: safeDuration.inMilliseconds == 0
                    ? 1
                    : safeDuration.inMilliseconds.toDouble(),
                onChanged: safeDuration.inMilliseconds == 0
                    ? null
                    : (v) => onSeek(Duration(milliseconds: v.round())),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ControlButtonWidget(
                  icon: Icons.stop_rounded,
                  onPressed: onStop,
                  color: Colors.grey,
                  size: 48,
                ),
                const SizedBox(width: 16),
                ControlButtonWidget(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  onPressed: onToggle,
                  color: const Color(0xFF6C5CE7),
                  size: 56,
                  isPrimary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
