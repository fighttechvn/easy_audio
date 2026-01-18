import '../../../../domain/entities/easy_audio_config.dart';
import '../../../../domain/entities/easy_audio_state.dart';
import '../../../../domain/entities/recording_result.dart';
import '../../../../domain/entities/supported_locale.dart';
import '../../../../domain/entities/transcript_result.dart';

abstract class EasyAudioServiceInterface {
  // Streams
  Stream<EasyAudioState> get stateStream;
  Stream<TranscriptResult> get transcriptStream;
  Stream<double> get amplitudeStream;

  // State
  EasyAudioState get currentState;
  EasyAudioConfig get config;
  bool get isInitialized;
  bool get isRecording;
  String? get currentFilePath;
  bool get isSpeechAvailable;

  bool get wasPausedByInterruption;

  DateTime? get recordingStartTime;

  // Lifecycle/config
  Future<void> initialize([EasyAudioConfig? config]);
  Future<void> updateConfig(EasyAudioConfig config);

  // Permissions
  Future<bool> hasRecordPermission();
  Future<bool> hasSpeechPermission();
  Future<bool> requestPermissions();

  // Locales (speech_to_text)
  Future<List<SupportedLocale>> getSupportedLocales();

  // Recording
  Future<void> start();
  Future<void> pause();
  Future<void> resume();
  Future<RecordingResult> stop();
  Future<void> cancel();

  // Recovery
  Future<RecordingResult?> recoverLastRecording();

  // Dispose
  Future<void> dispose();
}
