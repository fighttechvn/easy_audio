import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

import 'recording_card_widget.dart';

class RecordingsListWidget extends StatelessWidget {
  const RecordingsListWidget({
    super.key,
    required this.recordings,
    required this.selectedRecording,
    required this.isPlaying,
    required this.onRecordingPressed,
  });

  final List<RecordingResult> recordings;
  final RecordingResult? selectedRecording;
  final bool isPlaying;
  final ValueChanged<RecordingResult> onRecordingPressed;

  @override
  Widget build(BuildContext context) {
    if (recordings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Recent Recordings',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                final sr = selectedRecording;
                final isSelected =
                    sr != null &&
                    ((sr.filePath != null &&
                            sr.filePath == recording.filePath) ||
                        (sr.filePath == null &&
                            recording.filePath == null &&
                            sr.startTime == recording.startTime &&
                            sr.endTime == recording.endTime));

                return RecordingCardWidget(
                  recording: recording,
                  isSelected: isSelected,
                  isPlaying: isSelected && isPlaying,
                  onPressed: () => onRecordingPressed(recording),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
