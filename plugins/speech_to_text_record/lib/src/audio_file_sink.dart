import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import 'exceptions.dart';

/// Persists PCM audio frames from a broadcast stream into a WAV file.
class AudioFileSink {
  AudioFileSink({
    required this.stream,
    this.sampleRate = 16000,
    this.numChannels = 1,
  });

  /// Broadcast stream that feeds PCM 16-bit audio frames.
  final Stream<Uint8List> stream;

  final int sampleRate;
  final int numChannels;

  static const _bytesPerSample = 2; // 16-bit PCM
  static const _wavHeaderSize = 44;

  StreamSubscription<Uint8List>? _subscription;
  RandomAccessFile? _outputFile;
  Future<void> _writeQueue = Future<void>.value();
  String? _outputPath;
  int _writtenBytes = 0;
  bool _isPaused = false;

  bool get isRecording => _subscription != null;
  bool get isPaused => _isPaused;

  /// Begin writing audio frames to [filePath].
  Future<void> start(String filePath) async {
    if (isRecording) {
      throw AudioPipelineStateException('Recording already started');
    }

    final file = await File(filePath).create(recursive: true);
    _outputFile = await file.open(mode: FileMode.write);
    _outputPath = filePath;
    _writtenBytes = 0;

    // Reserve WAV header space.
    await _outputFile!.writeFrom(_createHeaderPlaceholder());

    _subscription = stream.listen(
      (chunk) {
        if (!_isPaused) {
          final bytes = Uint8List.fromList(chunk);
          _writtenBytes += bytes.length;
          _writeQueue = _writeQueue.then(
            (_) => _outputFile?.writeFrom(bytes) ?? Future<void>.value(),
          );
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _writeQueue = _writeQueue.then((_) async {
          await stop(deleteOnCancel: true);
          Zone.current.handleUncaughtError(error, stackTrace);
        });
      },
      cancelOnError: true,
    );
  }

  /// Temporarily pause writing audio frames to disk.
  void pause() {
    if (_subscription == null) {
      return;
    }
    _isPaused = true;
  }

  /// Resume writing audio frames to disk after a pause.
  void resume() {
    if (_subscription == null) {
      return;
    }
    _isPaused = false;
  }

  /// Stop recording and seal the WAV header. Returns the output file path.
  Future<String?> stop({bool deleteOnCancel = false}) async {
    final subscription = _subscription;
    final output = _outputFile;

    _subscription = null;

    if (subscription == null || output == null) {
      return _outputPath;
    }

    await subscription.cancel();
    await _writeQueue;

    if (deleteOnCancel && _outputPath != null) {
      await output.close();
      try {
        await File(_outputPath!).delete();
      } catch (_) {
        // Ignored: best-effort cleanup.
      }
      _reset();
      return null;
    }

    await _finalizeHeader(output);
    await output.close();

    final pathValue = _outputPath;
    _reset();
    return pathValue;
  }

  Future<void> dispose() async {
    await stop();
  }

  void _reset() {
    _outputFile = null;
    _outputPath = null;
    _writeQueue = Future<void>.value();
    _writtenBytes = 0;
  }

  Future<void> _finalizeHeader(RandomAccessFile file) async {
    final dataSize = _writtenBytes;
    final headerBytes = _createWavHeader(dataSize);
    await file.setPosition(0);
    await file.writeFrom(headerBytes);
    await file.setPosition(dataSize + _wavHeaderSize);
  }

  Uint8List _createHeaderPlaceholder() => Uint8List(_wavHeaderSize);

  Uint8List _createWavHeader(int dataLength) {
    final totalSize = dataLength + _wavHeaderSize - 8;
    final byteRate = sampleRate * numChannels * _bytesPerSample;
    final blockAlign = numChannels * _bytesPerSample;

    final header = ByteData(_wavHeaderSize);
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, totalSize, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6d); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little); // PCM chunk size
    header.setUint16(20, 1, Endian.little); // audio format PCM
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, _bytesPerSample * 8, Endian.little);
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataLength, Endian.little);

    return header.buffer.asUint8List();
  }
}

/// Utility to compose file paths for recordings.
String defaultRecordingPath(String directory, {String? fileName}) {
  final safeName = fileName ??
      'recording_${DateTime.now().toIso8601String().replaceAll(':', '-')}.wav';
  return path.join(directory, safeName);
}
