import 'package:easy_audio/easy_audio.dart';

import '../../domain/repositories/easy_audio_repository.dart';

class EasyAudioRepositoryImpl implements EasyAudioRepository {
  EasyAudioRepositoryImpl({required EasyAudioService service})
    : _service = service;

  final EasyAudioService _service;

  @override
  Stream<EasyAudioState> get stateStream => _service.stateStream;

  @override
  Stream<TranscriptResult> get transcriptStream => _service.transcriptStream;

  @override
  Stream<double> get amplitudeStream => _service.amplitudeStream;

  @override
  Future<List<SupportedLocale>> getSupportedLocales() =>
      _service.getSupportedLocales();

  @override
  Future<void> initialize(EasyAudioConfig config) =>
      _service.initialize(config);

  @override
  Future<void> updateConfig(EasyAudioConfig config) =>
      _service.updateConfig(config);

  @override
  Future<void> start() => _service.start();

  @override
  Future<RecordingResult> stop() => _service.stop();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> resume() => _service.resume();

  @override
  Future<void> cancel() => _service.cancel();

  @override
  Future<RecordingResult?> recoverLastRecording() =>
      _service.recoverLastRecording();

  @override
  Future<void> dispose() => _service.dispose();
}
