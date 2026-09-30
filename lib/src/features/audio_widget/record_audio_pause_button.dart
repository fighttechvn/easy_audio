import 'package:flutter/material.dart';

class RecordAudioPauseButton extends StatelessWidget {
  const RecordAudioPauseButton({
    super.key,
    required this.enabled,
    required this.isPaused,
    required this.onTap,
  });

  final bool enabled;
  final bool isPaused;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // Dark background
        borderRadius: BorderRadius.circular(35),
      ),
      child: Center(
        child: InkResponse(
          onTap: enabled ? onTap : null,
          radius: 30,
          child: Container(
            width: 100,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: enabled
                  ? isPaused
                        ? Colors.blueAccent
                        : const Color(0xFFE53935)
                  : const Color(0xFFE53935).withValues(alpha: 0.4),
            ),
            alignment: Alignment.center,
            child: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
              size: 35,
            ),
          ),
        ),
      ),
    );
  }
}
