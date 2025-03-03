import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../record_audio_constants.dart';

class FixedWaveform extends StatelessWidget {
  final List<double> templates;
  final Size size;
  final double waveThickness;

  const FixedWaveform({
    super.key,
    this.templates = const [3, 6, 9, 12, 15, 17, 12, 10, 8, 6, 2],
    this.size = const Size(double.infinity, 24),
    this.waveThickness = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff5AA3F1),
            Color(0xff35C78B),
          ],
        ).createShader(bounds);
      },
      child: CustomPaint(
        size: size,
        painter: WavePainter(
          templates: templates,
          waveThickness: waveThickness,
          waveColor: Colors.white,
        ),
      ),
    );
  }
}

enum WaveForm { fit, contain }

class WavePainter extends CustomPainter {
  final List<double> templates;
  final double animValue;
  final Color? waveColor;
  final StrokeCap waveCap;
  final double waveThickness;
  final double waveSpace;
  final Shader? fixedWaveGradient;
  final WaveForm form;

  WavePainter({
    required this.templates,
    this.animValue = 0,
    this.waveSpace = 1.4,
    this.waveColor,
    this.waveCap = StrokeCap.round,
    this.waveThickness = 2.2,
    this.fixedWaveGradient,
    this.form = WaveForm.fit,
  }) : wavePaint = Paint()
          ..color = waveColor ?? Colors.black
          ..strokeWidth = waveThickness
          ..strokeCap = waveCap
          ..shader = fixedWaveGradient;

  Paint wavePaint;

  @override
  void paint(Canvas canvas, Size size) {
    // print('$runtimeType $templates');
    _drawFixedWave(size, canvas);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => false;

  void _drawFixedWave(Size size, Canvas canvas) {
    final coupleWidth = waveThickness + waveSpace;
    final waveAndSpaceCount = (size.width - waveThickness) ~/ coupleWidth;
    final remainingWidth =
        (size.width - waveThickness) - (waveAndSpaceCount * coupleWidth);
    final start = remainingWidth / 2 + waveThickness / 2;
    final templateCount = templates.length;
    final maxT = templates.reduce(max);
    for (var i = 0; i <= waveAndSpaceCount; i++) {
      final t = templates[i % templateCount];
      double waveHeight;
      final start0 = start + (coupleWidth * i);
      if (form == WaveForm.fit) {
        waveHeight = t / maxT * (size.height - waveThickness);
      } else {
        waveHeight = t - waveThickness;
      }
      canvas.drawLine(
        Offset(start0, size.height / 2 - waveHeight / 2),
        Offset(start0, size.height / 2 + waveHeight / 2),
        wavePaint,
      );
    }
  }
}

class AnimatedWaveform extends StatefulWidget {
  final List<double> templates;
  final bool playing;
  final WaveForm form;
  final double waveThickness;
  final int divide;

  const AnimatedWaveform({
    super.key,
    this.templates = kAudioTemplates,
    this.playing = true,
    this.form = WaveForm.contain,
    this.waveThickness = 4,
    this.divide = 1,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  AnimationStatus? last;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        if (controller.isCompleted) {
          last = AnimationStatus.reverse;
          controller.reverse();
        } else if (controller.isDismissed) {
          last = AnimationStatus.forward;
          controller.forward();
        }
      });
    if (widget.playing) {
      controller.forward();
    }
    animation = Tween(begin: 0.3, end: 0.7).animate(controller);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform oldWidget) {
    if (widget.playing) {
      if (last == null || last == AnimationStatus.forward) {
        controller.forward();
      } else {
        controller.reverse();
      }
    } else {
      controller.stop();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newList = widget.templates.map((e) => e * widget.divide).toList();
    final maxValue = newList.reduce(max);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xff5AA3F1),
                Color(0xff35C78B),
              ],
            ).createShader(bounds);
          },
          child: CustomPaint(
            size: Size(
              double.infinity,
              maxValue,
            ),
            painter: WavePainter(
              templates: [
                ...newList.asMap().entries.map((e) {
                  if (e.value < (maxValue / 2)) {
                    return e.value / animation.value;
                  } else {
                    return e.value * animation.value;
                  }
                }),
              ],
              waveThickness: widget.waveThickness,
              waveColor: Colors.white,
              form: widget.form,
            ),
          ),
        );
      },
    );
  }
}
