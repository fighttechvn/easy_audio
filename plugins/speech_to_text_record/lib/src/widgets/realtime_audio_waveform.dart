import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../microphone_audio_stream.dart';

/// A widget that displays real-time audio waveform visualization
/// by processing audio data from MicrophoneAudioStream
class RealtimeAudioWaveform extends StatefulWidget {
  const RealtimeAudioWaveform({
    super.key,
    this.microphoneStream,
    this.width = double.infinity,
    this.height = 150,
    this.barWidth = 3.0,
    this.barSpacing = 1.5,
    this.maxBars = 50,
    this.amplitudeMultiplier = 100.0,
    this.smoothingFactor = 0.7,
    this.minBarHeight = 4.0,
    this.colors = const [Color(0xff5AA3F1), Color(0xff35C78B)],
    this.isRecording = false,
  });

  /// The microphone audio stream to visualize
  final MicrophoneAudioStream? microphoneStream;

  /// Width of the waveform widget
  final double width;

  /// Height of the waveform widget
  final double height;

  /// Width of each frequency bar
  final double barWidth;

  /// Spacing between bars
  final double barSpacing;

  /// Maximum number of bars to display
  final int maxBars;

  /// Multiplier for amplitude scaling
  final double amplitudeMultiplier;

  /// Smoothing factor for amplitude changes (0.0 - 1.0)
  final double smoothingFactor;

  /// Minimum height for bars
  final double minBarHeight;

  /// Gradient colors for the waveform
  final List<Color> colors;

  /// Whether recording is active
  final bool isRecording;

  @override
  State<RealtimeAudioWaveform> createState() => _RealtimeAudioWaveformState();
}

class _RealtimeAudioWaveformState extends State<RealtimeAudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  StreamSubscription<Uint8List>? _audioSubscription;
  List<double> _amplitudes = [];
  List<double> _smoothedAmplitudes = [];
  Timer? _updateTimer;

  // Animation for idle state when not recording
  late Animation<double> _idleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAmplitudes();
    _setupAnimationController();
    _setupAudioStream();
  }

  @override
  void didUpdateWidget(RealtimeAudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.microphoneStream != oldWidget.microphoneStream) {
      _setupAudioStream();
    }

    if (widget.isRecording != oldWidget.isRecording) {
      _handleRecordingStateChange();
    }

    if (widget.maxBars != oldWidget.maxBars) {
      _initializeAmplitudes();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeAmplitudes() {
    _amplitudes = <double>[];
    _smoothedAmplitudes = <double>[];
  }

  void _setupAnimationController() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _idleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (!widget.isRecording) {
      _animationController.repeat(reverse: true);
    }
  }

  void _setupAudioStream() {
    _audioSubscription?.cancel();

    if (widget.microphoneStream != null && widget.isRecording) {
      debugPrint(
        'RealtimeAudioWaveform: Setting up audio stream, recording: ${widget.isRecording}',
      );
      _audioSubscription = widget.microphoneStream!.stream.listen(
        _processAudioData,
        onError: (error) {
          debugPrint('RealtimeAudioWaveform: Audio stream error: $error');
        },
      );
    } else {
      debugPrint(
        'RealtimeAudioWaveform: No audio stream setup - microphoneStream: ${widget.microphoneStream != null}, recording: ${widget.isRecording}',
      );
    }
  }

  void _handleRecordingStateChange() {
    if (!mounted) {
      return;
    }

    if (widget.isRecording) {
      _animationController.stop();
      _setupAudioStream();
      _startUpdateTimer();
    } else {
      _audioSubscription?.cancel();
      _updateTimer?.cancel();
      _animationController.repeat(reverse: true);
    }
  }

  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _processAudioData(Uint8List audioData) {
    if (!widget.isRecording || !mounted) return;

    // Convert bytes to 16-bit PCM samples
    final samples = _bytesToSamples(audioData);
    if (samples.isEmpty) return;

    // Calculate RMS (Root Mean Square) for amplitude
    final rms = _calculateRMS(samples);
    final amplitude = (rms * widget.amplitudeMultiplier).clamp(
      widget.minBarHeight,
      widget.height *
          0.95, // Tăng từ 0.8 lên 0.95 để sử dụng gần như toàn bộ chiều cao
    );

    // Shift amplitudes and add new one
    if (_amplitudes.length >= widget.maxBars) {
      _amplitudes.removeAt(0);
      _smoothedAmplitudes.removeAt(0);
    }
    _amplitudes.add(amplitude);
    _smoothedAmplitudes.add(amplitude); // Initialize with raw amplitude

    // Apply smoothing
    _smoothAmplitudes();
  }

  List<int> _bytesToSamples(Uint8List bytes) {
    final samples = <int>[];
    for (int i = 0; i < bytes.length - 1; i += 2) {
      // Convert little-endian 16-bit PCM to signed integer
      final sample = bytes[i] | (bytes[i + 1] << 8);
      // Convert unsigned to signed
      samples.add(sample > 32767 ? sample - 65536 : sample);
    }
    return samples;
  }

  double _calculateRMS(List<int> samples) {
    if (samples.isEmpty) return 0.0;

    double sum = 0.0;
    for (final sample in samples) {
      sum += sample * sample;
    }
    return sqrt(sum / samples.length) / 32768.0; // Normalize to 0-1
  }

  void _smoothAmplitudes() {
    // Apply smoothing to the last added amplitude only
    if (_smoothedAmplitudes.isNotEmpty && _amplitudes.isNotEmpty) {
      final lastIndex = _smoothedAmplitudes.length - 1;
      _smoothedAmplitudes[lastIndex] =
          (_smoothedAmplitudes[lastIndex] * widget.smoothingFactor) +
              (_amplitudes[lastIndex] * (1.0 - widget.smoothingFactor));
    }
  }

  List<double> _getIdleAmplitudes() {
    // Generate animated idle waveform
    final time = _idleAnimation.value * 2 * pi;
    return List.generate(widget.maxBars, (index) {
      final phase = (index / widget.maxBars) * 2 * pi;
      final amplitude = sin(time + phase) * 0.4 + 0.6; // Tăng biên độ dao động
      return widget.minBarHeight +
          (amplitude *
              (widget.height * 0.4 -
                  widget.minBarHeight)); // Tăng từ 0.2 lên 0.4
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _idleAnimation,
        builder: (context, child) {
          final displayAmplitudes =
              widget.isRecording ? _smoothedAmplitudes : _getIdleAmplitudes();

          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: WaveformPainter(
              amplitudes: displayAmplitudes,
              barWidth: widget.barWidth,
              barSpacing: widget.barSpacing,
              colors: widget.colors,
              isRecording: widget.isRecording,
            ),
          );
        },
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double barWidth;
  final double barSpacing;
  final List<Color> colors;
  final bool isRecording;

  WaveformPainter({
    required this.amplitudes,
    required this.barWidth,
    required this.barSpacing,
    required this.colors,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    // Create gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);

    final totalBarWidth = barWidth + barSpacing;
    final availableWidth = size.width;
    final startX = (availableWidth - (amplitudes.length * totalBarWidth)) / 2;

    for (int i = 0; i < amplitudes.length; i++) {
      final x = startX + (i * totalBarWidth) + (barWidth / 2);
      final amplitude = amplitudes[i];
      final barHeight = amplitude.clamp(barWidth, size.height * 0.9);

      final startY = (size.height - barHeight) / 2;
      final endY = startY + barHeight;

      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return !_listEquals(amplitudes, oldDelegate.amplitudes) ||
        barWidth != oldDelegate.barWidth ||
        barSpacing != oldDelegate.barSpacing ||
        !_listEquals(colors, oldDelegate.colors) ||
        isRecording != oldDelegate.isRecording;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
