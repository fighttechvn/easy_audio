import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// UseCase xử lý logic playback audio
class PlaybackUseCase {
  PlaybackUseCase() : _player = AudioPlayer();

  final AudioPlayer _player;

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  bool get isPlaying => _player.playing;
  ProcessingState get processingState => _player.processingState;

  /// Play audio từ file path
  Future<void> playFromFile(String filePath) async {
    await _player.stop();
    await _player.setFilePath(filePath);
    await _player.play();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Stop silently without throwing
  Future<void> stopSilently() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
    } catch (_) {}
  }

  /// Dispose player
  Future<void> dispose() async {
    await _player.dispose();
  }
}
