import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

import 'control_button_widget.dart';

class RecordingControlsWidget extends StatelessWidget {
  const RecordingControlsWidget({
    super.key,
    required this.state,
    required this.onToggleRecording,
    required this.onCancelRecording,
    required this.onPauseRecording,
  });

  final EasyAudioState state;
  final VoidCallback onToggleRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onPauseRecording;

  @override
  Widget build(BuildContext context) {
    final isRecording = state == EasyAudioState.recording;
    final isPaused = state == EasyAudioState.paused;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isRecording || isPaused) ...[
            ControlButtonWidget(
              icon: Icons.close,
              onPressed: onCancelRecording,
              color: Colors.grey,
              size: 52,
            ),
            const SizedBox(width: 20),
          ],
          ControlButtonWidget(
            icon: isRecording
                ? Icons.stop_rounded
                : isPaused
                ? Icons.play_arrow_rounded
                : Icons.fiber_manual_record,
            onPressed: onToggleRecording,
            color: isRecording
                ? const Color(0xFFE17055)
                : const Color(0xFF6C5CE7),
            size: 80,
            isPrimary: true,
          ),
          if (isRecording) ...[
            const SizedBox(width: 20),
            ControlButtonWidget(
              icon: Icons.pause_rounded,
              onPressed: onPauseRecording,
              color: Colors.amber,
              size: 52,
            ),
          ],
        ],
      ),
    );
  }
}
