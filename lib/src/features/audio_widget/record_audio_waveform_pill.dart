import 'package:flutter/material.dart';

import 'waveform_painter.dart';

class RecordAudioWaveformPill extends StatelessWidget {
  const RecordAudioWaveformPill({super.key, required this.samples});

  final List<double> samples;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(32),
      ),
      child: CustomPaint(
        painter: WaveformPainter(samples: samples, color: Colors.black87),
        child: const SizedBox.expand(),
      ),
    );
  }
}
