import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import 'exceptions.dart';

/// Persists PCM audio frames from a broadcast stream into a WAV file.
///
/// This class now supports incremental WAV header updates to ensure
/// the audio file remains valid even if the app is terminated unexpectedly
/// (e.g., battery drain, crash, force close).
class AudioFileSink {
  AudioFileSink({
    required this.stream,
    this.sampleRate = 16000,
    this.numChannels = 1,
    this.headerSyncInterval = const Duration(seconds: 5),
  });

  /// Broadcast stream that feeds PCM 16-bit audio frames.
  final Stream<Uint8List> stream;

  final int sampleRate;
  final int numChannels;

  /// How often to sync the WAV header to disk.
  /// Default is 5 seconds to balance between safety and performance.
  final Duration headerSyncInterval;

  static const _bytesPerSample = 2; // 16-bit PCM
  static const _wavHeaderSize = 44;

  StreamSubscription<Uint8List>? _subscription;
  RandomAccessFile? _outputFile;
  Future<void> _writeQueue = Future<void>.value();
  String? _outputPath;
  int _writtenBytes = 0;
  bool _isPaused = false;
  Timer? _headerSyncTimer;
  int _lastSyncedBytes = 0;

  bool get isRecording => _subscription != null;
  bool get isPaused => _isPaused;

  /// Get the current recording file path
  String? get currentFilePath => _outputPath;

  /// Get the current written bytes count
  int get writtenBytes => _writtenBytes;

  /// Get the current recording duration based on written bytes
  Duration get currentDuration {
    if (_writtenBytes == 0) return Duration.zero;
    final bytesPerSecond = sampleRate * numChannels * _bytesPerSample;
    final seconds = _writtenBytes / bytesPerSecond;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  /// Begin writing audio frames to [filePath].
  Future<void> start(String filePath) async {
    if (isRecording) {
      throw AudioPipelineStateException('Recording already started');
    }

    final file = await File(filePath).create(recursive: true);
    _outputFile = await file.open(mode: FileMode.write);
    _outputPath = filePath;
    _writtenBytes = 0;
    _lastSyncedBytes = 0;

    // Write initial WAV header with zero data length.
    // This ensures the file is valid even if we crash immediately.
    await _outputFile!.writeFrom(_createWavHeader(0));

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

    // Start periodic header sync timer
    _startHeaderSyncTimer();
  }

  /// Start the timer that periodically syncs the WAV header to disk.
  void _startHeaderSyncTimer() {
    _headerSyncTimer?.cancel();
    _headerSyncTimer = Timer.periodic(headerSyncInterval, (_) {
      _syncHeaderToDisk();
    });
  }

  /// Sync the WAV header to disk with current data length.
  /// This is called periodically to ensure the file remains valid.
  Future<void> _syncHeaderToDisk() async {
    if (_outputFile == null || _writtenBytes == _lastSyncedBytes) {
      return;
    }

    // Queue the header update after current writes complete
    _writeQueue = _writeQueue.then((_) async {
      final output = _outputFile;
      if (output == null) return;

      try {
        // Save current position
        final currentPosition = await output.position();

        // Update header at beginning of file
        await output.setPosition(0);
        await output.writeFrom(_createWavHeader(_writtenBytes));

        // Restore position for continued writing
        await output.setPosition(currentPosition);

        // Flush to ensure data is written to disk
        await output.flush();

        _lastSyncedBytes = _writtenBytes;
      } catch (e) {
        // Ignore sync errors - best effort
      }
    });
  }

  /// Force sync the header immediately. Useful before app goes to background.
  Future<void> forceSyncHeader() async {
    await _syncHeaderToDisk();
    await _writeQueue;
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
    // Cancel header sync timer
    _headerSyncTimer?.cancel();
    _headerSyncTimer = null;

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
    _headerSyncTimer?.cancel();
    _headerSyncTimer = null;
    await stop();
  }

  void _reset() {
    _outputFile = null;
    _outputPath = null;
    _writeQueue = Future<void>.value();
    _writtenBytes = 0;
    _lastSyncedBytes = 0;
  }

  Future<void> _finalizeHeader(RandomAccessFile file) async {
    final dataSize = _writtenBytes;
    final headerBytes = _createWavHeader(dataSize);
    await file.setPosition(0);
    await file.writeFrom(headerBytes);
    await file.setPosition(dataSize + _wavHeaderSize);
  }

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
