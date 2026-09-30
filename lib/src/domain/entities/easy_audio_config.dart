import 'android_service.dart';
import 'audio_encoder.dart';
import 'easy_audio_mode.dart';

class EasyAudioConfig {
  final EasyAudioMode mode;
  final AudioEncoder encoder;
  final int sampleRate;
  final int bitRate;
  final int numChannels;
  final String? locale;
  final Duration? maxDuration;
  final bool enableCrashRecovery;
  final bool pauseOnInterruption;
  final bool autoResumeAfterInterruption;
  final bool enableBackgroundRecording;
  final AndroidService? androidService;
  final String? outputDirectory;
  final String filePrefix;
  final String? fileExtension;

  const EasyAudioConfig({
    this.mode = EasyAudioMode.recordOnly,
    this.encoder = AudioEncoder.aacLc,
    this.sampleRate = 44100,
    this.bitRate = 128000,
    this.numChannels = 1,
    this.locale,
    this.maxDuration,
    this.enableCrashRecovery = true,
    this.pauseOnInterruption = true,
    this.autoResumeAfterInterruption = false,
    this.enableBackgroundRecording = false,
    this.androidService,
    this.outputDirectory,
    this.filePrefix = 'easy_audio_',
    this.fileExtension,
  });

  EasyAudioConfig copyWith({
    EasyAudioMode? mode,
    AudioEncoder? encoder,
    int? sampleRate,
    int? bitRate,
    int? numChannels,
    String? locale,
    Duration? maxDuration,
    bool? enableCrashRecovery,
    bool? pauseOnInterruption,
    bool? autoResumeAfterInterruption,
    bool? enableBackgroundRecording,
    AndroidService? androidService,
    String? outputDirectory,
    String? filePrefix,
    String? fileExtension,
  }) {
    return EasyAudioConfig(
      mode: mode ?? this.mode,
      encoder: encoder ?? this.encoder,
      sampleRate: sampleRate ?? this.sampleRate,
      bitRate: bitRate ?? this.bitRate,
      numChannels: numChannels ?? this.numChannels,
      locale: locale ?? this.locale,
      maxDuration: maxDuration ?? this.maxDuration,
      enableCrashRecovery: enableCrashRecovery ?? this.enableCrashRecovery,
      pauseOnInterruption: pauseOnInterruption ?? this.pauseOnInterruption,
      autoResumeAfterInterruption:
          autoResumeAfterInterruption ?? this.autoResumeAfterInterruption,
      enableBackgroundRecording:
          enableBackgroundRecording ?? this.enableBackgroundRecording,
      androidService: androidService ?? this.androidService,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      filePrefix: filePrefix ?? this.filePrefix,
      fileExtension: fileExtension ?? this.fileExtension,
    );
  }

  String get resolvedFileExtension {
    final raw = fileExtension?.trim();
    if (raw != null && raw.isNotEmpty) {
      final normalized = raw.startsWith('.') ? raw.substring(1) : raw;
      if (normalized.toLowerCase() == 'wav') {
        return 'wav';
      }
    }

    // SttRecord always outputs WAV PCM16.
    return 'wav';
  }

  @override
  String toString() {
    return 'EasyAudioConfig(mode: $mode, encoder: $encoder,'
        ' sampleRate: $sampleRate, '
        'bitRate: $bitRate, locale: $locale,'
        ' enableBackgroundRecording: $enableBackgroundRecording)';
  }
}
