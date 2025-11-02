import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../audio_file_sink.dart';
import '../exceptions.dart';

/// Minimal wrapper around the `record` package to provide plug-and-play audio
/// recording into a WAV file.
class SimpleAudioRecorder {
  SimpleAudioRecorder({this.sampleRate = 16000, this.numChannels = 1})
      : _recorder = AudioRecorder();

  final int sampleRate;
  final int numChannels;
  final AudioRecorder _recorder;

  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;
  String? get activeFilePath => _currentPath;

  /// Start recording into [filePath]. If null, a path in the documents
  /// directory is generated.
  Future<String> start({String? filePath}) async {
    if (_isRecording) {
      throw AudioPipelineStateException('Recording already in progress');
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw MicrophonePermissionException();
    }

    final targetPath = filePath ?? await _defaultPath();
    final config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: sampleRate,
      numChannels: numChannels,
    );

    await _recorder.start(config, path: targetPath);
    _currentPath = targetPath;
    _isRecording = true;
    return targetPath;
  }

  /// Stop recording and return the saved file path. If [discard] is true the
  /// file is removed and null is returned.
  Future<String?> stop({bool discard = false}) async {
    if (!_isRecording) {
      return _currentPath;
    }

    final path = await _recorder.stop();
    _isRecording = false;

    if (discard && path != null) {
      try {
        await File(path).delete();
      } catch (_) {
        // Ignored: best-effort cleanup.
      }
      _currentPath = null;
      return null;
    }

    _currentPath = path ?? _currentPath;
    return _currentPath;
  }

  /// Cancel the current recording without saving.
  Future<void> cancel() async {
    if (_isRecording) {
      await _recorder.cancel();
      _isRecording = false;
      _currentPath = null;
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  Future<String> _defaultPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return defaultRecordingPath(directory.path);
  }
}
