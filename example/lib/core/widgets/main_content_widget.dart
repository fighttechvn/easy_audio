import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

import '../utils/format_duration.dart';
import 'transcript_section_widget.dart';
import 'visualizer_section_widget.dart';

class MainContentWidget extends StatelessWidget {
  const MainContentWidget({
    super.key,
    required this.selectedMode,
    required this.state,
    required this.recordingDuration,
    required this.amplitude,
    required this.pulseAnimation,
    required this.transcript,
    required this.liveTranscript,
    required this.isPlaybackMode,
    required this.forceShowTranscript,
    required this.hideTranscriptSection,
  });

  final EasyAudioMode selectedMode;
  final EasyAudioState state;
  final Duration recordingDuration;
  final double amplitude;
  final Animation<double> pulseAnimation;
  final String transcript;
  final String liveTranscript;
  final bool isPlaybackMode;
  final bool forceShowTranscript;
  final bool hideTranscriptSection;

  @override
  Widget build(BuildContext context) {
    final isRecording = state == EasyAudioState.recording;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!isPlaybackMode)
            Expanded(
              flex: 2,
              child: VisualizerSectionWidget(
                durationText: formatDuration(recordingDuration),
                amplitude: amplitude,
                isRecording: isRecording,
                pulseAnimation: pulseAnimation,
              ),
            ),
          if (!hideTranscriptSection &&
              (selectedMode != EasyAudioMode.recordOnly || forceShowTranscript))
            Expanded(
              flex: 3,
              child: TranscriptSectionWidget(
                transcript: transcript,
                liveTranscript: liveTranscript,
                isRecording: isRecording,
              ),
            ),
        ],
      ),
    );
  }
}
