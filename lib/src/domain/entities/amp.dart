import 'package:record/record.dart';

/// dBFS amplitude
class Amp {
  const Amp({required this.current, required this.max});

  /// Current max amplitude
  final double current;

  /// Top max amplitude
  final double max;
}

extension AmplitudeExt on Amplitude {
  Amp toAmp() => Amp(current: current, max: max);
}

extension StringExtCodec on String {
  AudioEncoder get getCodec {
    final extension = split('.').last;
    switch (extension) {
      case 'pcm':
        return AudioEncoder.pcm16bits;
      case 'aac':
        return AudioEncoder.aacLc;
      default:
        return AudioEncoder.pcm16bits;
    }
  }
}
