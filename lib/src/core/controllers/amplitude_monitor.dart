import 'dart:async';

import 'package:record/record.dart';

class AmplitudeMonitor {
  AmplitudeMonitor({
    required this.recorder,
    required this.onAmplitude,
    this.interval = const Duration(milliseconds: 100),
  });

  final AudioRecorder recorder;
  final void Function(double normalized) onAmplitude;
  final Duration interval;

  Timer? _timer;

  void start() {
    stop();
    _timer = Timer.periodic(interval, (_) async {
      try {
        final amplitude = await recorder.getAmplitude();
        final normalized = ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
        onAmplitude(normalized);
      } catch (_) {
        // Best-effort.
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
