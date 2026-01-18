import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  WaveformPainter({required this.samples, required this.color});

  final List<double> samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, bgPaint);

    if (samples.isEmpty) {
      return;
    }

    final barCount = samples.length;
    final barWidth = (size.width / (barCount * 1.5)).clamp(2.0, 6.0);
    final gap = barWidth * 0.5;
    final maxBarHeight = size.height * 0.85;
    final centerY = size.height / 2;

    double x = (size.width - (barCount * (barWidth + gap) - gap)) / 2;
    for (final amp in samples) {
      final h = (amp * maxBarHeight).clamp(2.0, maxBarHeight);
      final top = centerY - h / 2;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, h),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(r, paint);
      x += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples || oldDelegate.color != color;
  }
}
