import 'package:easy_audio/easy_audio.dart';

abstract class EasyAudioRepository {
  Stream<EasyAudioState> get stateStream;
  Stream<TranscriptResult> get transcriptStream;
  Stream<double> get amplitudeStream;

  Future<List<SupportedLocale>> getSupportedLocales();

  Future<void> initialize(EasyAudioConfig config);
  Future<void> updateConfig(EasyAudioConfig config);

  Future<void> start();
  Future<RecordingResult> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> cancel();

  Future<RecordingResult?> recoverLastRecording();

  Future<void> dispose();
}
