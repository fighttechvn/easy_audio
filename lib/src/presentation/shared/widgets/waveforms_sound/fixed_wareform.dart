import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
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
  bool shouldRepaint(WavePainter oldDelegate) {
    return waveColor != oldDelegate.waveColor ||
        waveCap != oldDelegate.waveCap ||
        waveThickness != oldDelegate.waveThickness ||
        waveSpace != oldDelegate.waveSpace ||
        form != oldDelegate.form ||
        animValue != oldDelegate.animValue ||
        !listEquals(oldDelegate.templates, templates);
  }

  void _drawFixedWave(Size size, Canvas canvas) {
    final coupleWidth = waveThickness + waveSpace;
    final waveAndSpaceCount = (size.width - waveThickness) ~/ coupleWidth;
    final remainingWidth =
        (size.width - waveThickness) - (waveAndSpaceCount * coupleWidth);
    final start = remainingWidth / 2 + waveThickness / 2;
    final templateCount = templates.length;
    final maxT = templates.reduce(max);

    // Tạo offset để di chuyển từ phải sang trái
    // Loop qua toàn bộ template: animValue từ 0 -> 1 = 1 chu kỳ đầy đủ
    final totalPatternWidth = coupleWidth * templateCount;
    final offset = (animValue % 1.0) * totalPatternWidth;

    // Vẽ thêm waves để đảm bảo luôn fill đầy màn hình khi di chuyển
    final extraWaves = templateCount + 2;
    for (var i = -extraWaves; i <= waveAndSpaceCount + extraWaves; i++) {
      // Sử dụng modulo để loop pattern mượt
      final templateIndex = i % templateCount;
      final t = templates[
          templateIndex < 0 ? templateCount + templateIndex : templateIndex];
      double waveHeight;
      final start0 = start + (coupleWidth * i) + offset;

      // Chỉ vẽ nếu wave nằm trong viewport (với buffer nhỏ)
      if (start0 < -waveThickness * 2 ||
          start0 > size.width + waveThickness * 2) {
        continue;
      }

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
  final Duration duration;
  final double jitter;
  final bool mirror;
  final double smoothing;
  final AnimatedWaveformController? controller;
  final bool showSlider;
  final Duration sliderDuration;

  const AnimatedWaveform({
    super.key,
    this.templates = kAudioTemplates,
    this.playing = true,
    this.form = WaveForm.contain,
    this.waveThickness = 4,
    this.divide = 1,
    this.duration = const Duration(milliseconds: 650),
    this.jitter = 0.35,
    this.mirror = true,
    this.smoothing = 0.25,
    this.controller,
    this.showSlider = false,
    this.sliderDuration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  late final CurvedAnimation animation;
  late final AnimationController sliderController;
  late final Animation<double> sliderAnimation;
  final Random _random = Random();

  late List<double> _baseTemplate;
  late List<double> _fromSamples;
  late List<double> _toSamples;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener(_handleStatus);
    animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    sliderController = AnimationController(
      vsync: this,
      duration: widget.sliderDuration,
    );
    // Đảo ngược: begin 0.0 (trái) -> end 1.0 (phải) để chạy từ phải sang trái
    sliderAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: sliderController,
        curve: Curves.linear,
      ),
    );

    _initialiseTemplates();
    if (widget.playing) {
      controller.forward();
    }

    if (widget.showSlider) {
      sliderController.repeat();
    }

    widget.controller?.pause = () {
      controller.stop();
      if (widget.showSlider) {
        sliderController.stop();
      }
    };
    widget.controller?.resume = () {
      controller.forward();
      if (widget.showSlider) {
        sliderController.repeat();
      }
    };
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform oldWidget) {
    if (widget.duration != oldWidget.duration) {
      controller.duration = widget.duration;
    }

    if (widget.sliderDuration != oldWidget.sliderDuration) {
      sliderController.duration = widget.sliderDuration;
    }

    if (!listEquals(widget.templates, oldWidget.templates) ||
        widget.divide != oldWidget.divide ||
        widget.mirror != oldWidget.mirror) {
      _initialiseTemplates(
        resetAnimation: widget.playing,
        notify: true,
      );
      if (widget.playing && !controller.isAnimating) {
        controller.forward(from: 0);
      }
    }

    if (widget.playing != oldWidget.playing) {
      if (widget.playing) {
        if (!controller.isAnimating) {
          controller.forward(
              from: controller.value == 1 ? 0 : controller.value);
        }
        if (widget.showSlider && !sliderController.isAnimating) {
          sliderController.repeat();
        }
      } else {
        controller.stop();
        if (widget.showSlider) {
          sliderController.stop();
        }
        setState(() {
          _fromSamples = List<double>.from(_baseTemplate);
          _toSamples = _fromSamples;
        });
      }
    }

    if (widget.showSlider != oldWidget.showSlider) {
      if (widget.showSlider) {
        sliderController.repeat();
      } else {
        sliderController.stop();
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    sliderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, sliderAnimation]),
      builder: (context, child) {
        final samples = _currentSamples(animation.value);
        final maxValue =
            samples.isEmpty ? widget.waveThickness : samples.reduce(max);

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
              templates: samples,
              waveThickness: widget.waveThickness,
              waveColor: Colors.black,
              form: widget.form,
              animValue: widget.showSlider ? sliderAnimation.value : 0,
            ),
          ),
        );
      },
    );
  }

  void _handleStatus(AnimationStatus status) {
    if (!widget.playing || !mounted) {
      return;
    }
    if (status == AnimationStatus.completed) {
      setState(() {
        _fromSamples = _toSamples;
        _toSamples = _generateSamples();
      });
      controller.forward(from: 0);
    }
  }

  void _initialiseTemplates({bool resetAnimation = true, bool notify = false}) {
    _baseTemplate = _buildBaseTemplate();
    _fromSamples = _smoothSamples(_baseTemplate);
    _toSamples = widget.playing ? _generateSamples() : _fromSamples;
    if (resetAnimation) {
      controller.value = 0;
    }
    if (notify && mounted) {
      setState(() {});
    }
  }

  List<double> _currentSamples(double t) {
    if (_fromSamples.isEmpty) {
      return const <double>[];
    }
    final double progress = widget.playing ? t : 0;
    return List<double>.generate(_fromSamples.length, (index) {
      final start = _fromSamples[index];
      final end = _toSamples[index];
      return lerpDouble(start, end, progress)!;
    });
  }

  List<double> _buildBaseTemplate() {
    if (widget.templates.isEmpty) {
      return const <double>[];
    }
    final scaled = widget.templates
        .map((value) => (max(0, value) * widget.divide).toDouble())
        .toList(growable: false);
    if (!widget.mirror || scaled.length < 2) {
      return scaled;
    }
    final mirrored = List<double>.from(scaled)
      ..addAll(scaled.sublist(0, scaled.length - 1).reversed);
    return mirrored;
  }

  List<double> _generateSamples() {
    if (_baseTemplate.isEmpty) {
      return const <double>[];
    }
    final jitter = widget.jitter.clamp(0.0, 1.0);
    const lowerClamp = 0.2;
    final upperMultiplier = 1 + (jitter * 1.4);

    final samples = List<double>.generate(_baseTemplate.length, (index) {
      final base = _baseTemplate[index];
      final noise = (_random.nextDouble() * 2 - 1) * jitter;
      final value = base * (1 + noise);
      final minValue = base * lowerClamp;
      final maxValue = base * upperMultiplier;
      return value.clamp(minValue, maxValue).toDouble();
    }, growable: false);

    return _smoothSamples(samples);
  }

  List<double> _smoothSamples(List<double> values) {
    final smoothing = widget.smoothing.clamp(0.0, 1.0);
    if (values.length < 3 || smoothing <= 0) {
      return List<double>.from(values);
    }
    final smoothed = List<double>.from(values);
    for (var i = 1; i < values.length - 1; i++) {
      final average = (values[i - 1] + values[i] + values[i + 1]) / 3;
      smoothed[i] = lerpDouble(values[i], average, smoothing)!;
    }
    return smoothed;
  }
}

class AnimatedWaveformController {
  Function? pause;
  Function? resume;
}
