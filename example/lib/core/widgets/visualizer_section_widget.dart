import 'package:flutter/material.dart';

class VisualizerSectionWidget extends StatelessWidget {
  const VisualizerSectionWidget({
    super.key,
    required this.durationText,
    required this.amplitude,
    required this.isRecording,
    required this.pulseAnimation,
  });

  final String durationText;
  final double amplitude;
  final bool isRecording;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          durationText,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            letterSpacing: 8,
          ),
        ),
        Spacer(),
      ],
    );
  }
}
