import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

class StateIndicatorWidget extends StatelessWidget {
  const StateIndicatorWidget({super.key, required this.state});

  final EasyAudioState state;

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (state) {
      case EasyAudioState.idle:
        color = Colors.grey;
        text = 'Ready';
        icon = Icons.radio_button_unchecked;
        break;
      case EasyAudioState.initializing:
        color = Colors.orange;
        text = 'Initializing';
        icon = Icons.hourglass_empty;
        break;
      case EasyAudioState.recording:
        color = Colors.red;
        text = 'Recording';
        icon = Icons.fiber_manual_record;
        break;
      case EasyAudioState.paused:
        color = Colors.amber;
        text = 'Paused';
        icon = Icons.pause_circle_filled;
        break;
      case EasyAudioState.processing:
        color = Colors.blue;
        text = 'Processing';
        icon = Icons.sync;
        break;
      case EasyAudioState.error:
        color = Colors.red;
        text = 'Error';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
