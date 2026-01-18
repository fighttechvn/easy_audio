import 'package:easy_audio/easy_audio.dart';

import '../repositories/easy_audio_repository.dart';

/// Gom tất cả usecase của EasyAudio về 1 class duy nhất.
class EasyAudioUseCase {
  EasyAudioUseCase({required EasyAudioRepository repository})
    : _repository = repository;

  final EasyAudioRepository _repository;

  // Streams (để BLoC/UI subscribe khi cần)
  Stream<EasyAudioState> get stateStream => _repository.stateStream;
  Stream<TranscriptResult> get transcriptStream => _repository.transcriptStream;
  Stream<double> get amplitudeStream => _repository.amplitudeStream;

  Future<List<SupportedLocale>> getSupportedLocales() {
    return _repository.getSupportedLocales();
  }

  Future<void> initialize(EasyAudioConfig config) {
    return _repository.initialize(config);
  }

  Future<void> updateConfig(EasyAudioConfig config) {
    return _repository.updateConfig(config);
  }

  Future<void> start() {
    return _repository.start();
  }

  Future<RecordingResult> stop() {
    return _repository.stop();
  }

  Future<void> pause() {
    return _repository.pause();
  }

  Future<void> resume() {
    return _repository.resume();
  }

  Future<void> cancel() {
    return _repository.cancel();
  }

  Future<RecordingResult?> recoverLastRecording() {
    return _repository.recoverLastRecording();
  }

  Future<void> dispose() {
    return _repository.dispose();
  }
}
