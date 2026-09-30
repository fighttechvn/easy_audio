import 'dart:async';

import 'package:stt_record/stt_record.dart';

class AmplitudeMonitor {
  AmplitudeMonitor({
    required this.sttRecord,
    required this.onAmplitude,
    this.interval = const Duration(milliseconds: 100),
  });

  final SttRecord sttRecord;
  final void Function(double normalized) onAmplitude;
  final Duration interval;

  Timer? _timer;

  void start() {
    stop();
    _timer = Timer.periodic(interval, (_) async {
      try {
        final normalized = (await sttRecord.getAmplitude()).clamp(0.0, 1.0);
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
