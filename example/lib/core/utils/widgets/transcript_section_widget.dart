import 'package:flutter/material.dart';

class TranscriptSectionWidget extends StatelessWidget {
  const TranscriptSectionWidget({
    super.key,
    required this.transcript,
    required this.liveTranscript,
    required this.isRecording,
  });

  final String transcript;
  final String liveTranscript;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_snippet_outlined,
                color: Colors.white.withValues(alpha: 0.6),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Transcript',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                transcript.isNotEmpty
                    ? transcript
                    : liveTranscript.isNotEmpty
                    ? liveTranscript
                    : 'Start speaking to see the transcript...',
                style: TextStyle(
                  color: transcript.isNotEmpty || liveTranscript.isNotEmpty
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
