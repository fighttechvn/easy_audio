import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'exceptions.dart';

/// Provides a broadcast audio stream sourced from the device microphone.
class MicrophoneAudioStream {
  MicrophoneAudioStream({
    this.sampleRate = 16000,
    this.numChannels = 1,
    RecorderFactory? recordFactory,
    int? streamBufferSize,
  })  : _recordFactory = recordFactory ?? (() => AudioRecorder()),
        _streamBufferSize = streamBufferSize;

  final int sampleRate;
  final int numChannels;
  final AudioRecorder Function() _recordFactory;
  final int? _streamBufferSize;

  final _controller = StreamController<Uint8List>.broadcast();

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _recorderSubscription;
  bool _isStarted = false;
  bool get isStarted => _isStarted;

  /// Stream of PCM 16-bit little-endian audio frames.
  Stream<Uint8List> get stream => _controller.stream;

  /// Start capturing from the microphone.
  Future<void> start() async {
    if (_isStarted) {
      return;
    }

    final recorder = _recorder ??= _recordFactory();

    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      throw MicrophonePermissionException();
    }

    final config = RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      bitRate: sampleRate * numChannels * 16,
      sampleRate: sampleRate,
      numChannels: numChannels,
      streamBufferSize: _streamBufferSize,
    );

    final audioStream = await recorder.startStream(config);

    _recorderSubscription = audioStream.listen(
      (chunk) {
        if (!_controller.isClosed) {
          // Copy to detach from native buffer lifecycle.
          _controller.add(Uint8List.fromList(chunk));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
      cancelOnError: true,
    );

    _isStarted = true;
  }

  Future<void> pause() async {
    if (!_isStarted) {
      return;
    }
    await _recorder?.pause();
  }

  Future<void> resume() async {
    if (!_isStarted) {
      return;
    }
    await _recorder?.resume();
  }

  Future<void> stop() async {
    if (!_isStarted) {
      return;
    }

    await _recorderSubscription?.cancel();
    _recorderSubscription = null;
    await _recorder?.stop();

    _isStarted = false;
  }

  /// Release native resources.
  Future<void> dispose() async {
    await stop();
    await _recorder?.dispose();
    await _controller.close();
    _recorder = null;
  }
}

typedef RecorderFactory = AudioRecorder Function();
