import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

import '../../domain/entities/process_player.dart';

abstract class EasyAudioInterface {
  Future<void> initPlayer([bool disposeWhenParentDisponse = true]);
  Future<void> play([String? urlAudio]);
  Future<void> stopPlayer();
  Future<void> pause();
  Future<void> resume();
  Future<void> record();
  Future<void> seek(Duration duration);
  Future<String?>? stopRecorder();
  void forceDispose();
  String get url;
  bool get isInited;
  bool get isOpenPlayer;
  bool get isPlaying;
  ValueNotifier<ProcessPlayer> get onProgress;
  int get timeRecord;
  bool get isRecording;

  AudioPlayer get audioPlayer;
}

class EasyAudioController extends ChangeNotifier implements EasyAudioInterface {
  EasyAudioController({int sampleRate = 16000, int numChannels = 1})
      : _simpleRecorder = SimpleAudioRecorder(
          sampleRate: sampleRate,
          numChannels: numChannels,
        );

  final AudioPlayer _audioPlayer = AudioPlayer();
  late final StreamSubscription<void> _playerStateChangedSubscription;
  late final StreamSubscription<Duration?> _durationChangedSubscription;
  late final StreamSubscription<Duration> _positionChangedSubscription;
  final ValueNotifier<ProcessPlayer> _process =
      ValueNotifier<ProcessPlayer>(const ProcessPlayer());

  final SimpleAudioRecorder _simpleRecorder;

  DateTime? _recordStartedAt;

  String _url = '';
  int _timeRecord = 0;
  bool _mPlayerIsInited = false;
  bool _disposeWhenParentDisponse = true;
  bool _isRecording = false;

  @override
  int get timeRecord => _timeRecord;
  @override
  bool get isRecording => _isRecording;
  @override
  String get url => _url;
  @override
  bool get isInited => _mPlayerIsInited;
  @override
  bool get isOpenPlayer => _url.isNotEmpty;
  @override
  bool get isPlaying => _audioPlayer.state == PlayerState.playing;
  @override
  ValueNotifier<ProcessPlayer> get onProgress => _process;

  @override
  void forceDispose() {
    _disposeAll();
  }

  @override
  Future<void> initPlayer([bool disposeWhenParentDisponse = true]) async {
    if (_mPlayerIsInited) {
      return;
    }

    _playerStateChangedSubscription =
        _audioPlayer.onPlayerComplete.listen((_) async {
      await stopPlayer();
      notifyListeners();
    });
    _positionChangedSubscription = _audioPlayer.onPositionChanged.listen(
      (position) {
        _process.value = _process.value.copyWith(position: position);
      },
    );
    _durationChangedSubscription = _audioPlayer.onDurationChanged.listen(
      (duration) {
        _process.value = _process.value.copyWith(duration: duration);
      },
    );

    _disposeWhenParentDisponse = disposeWhenParentDisponse;
    _mPlayerIsInited = true;
  }

  @override
  Future<void> play([String? urlAudio]) async {
    if (urlAudio?.isNotEmpty ?? false) {
      if (_url.isNotEmpty) {
        _url = '';
        notifyListeners();
        await _audioPlayer.stop();
      }

      _url = urlAudio!;
      notifyListeners();

      final Source audioSource =
          _url.contains('http') ? UrlSource(_url) : DeviceFileSource(_url);

      await _audioPlayer.play(audioSource);

      notifyListeners();
      return;
    }

    if (_mPlayerIsInited && _audioPlayer.state == PlayerState.playing) {
      await stopPlayer();
    }
  }

  @override
  Future<void> record() async {
    try {
      _recordStartedAt = DateTime.now();
      await _simpleRecorder.start();
      _isRecording = true;
      notifyListeners();
    } on MicrophonePermissionException catch (error) {
      debugPrint('[EasyAudioController] Microphone permission denied: $error');
      _recordStartedAt = null;
      _isRecording = false;
      rethrow;
    } on AudioPipelineStateException catch (error) {
      debugPrint('[EasyAudioController] Recorder state error: $error');
      _recordStartedAt = null;
      _isRecording = false;
      rethrow;
    } catch (error) {
      debugPrint('[EasyAudioController] Failed to start recording: $error');
      _recordStartedAt = null;
      _isRecording = false;
      rethrow;
    }
  }

  @override
  Future<void> stopPlayer() async {
    await _audioPlayer.stop();
    _url = '';
    notifyListeners();
  }

  @override
  Future<String?>? stopRecorder() async {
    final startedAt = _recordStartedAt;
    if (startedAt != null) {
      _timeRecord = DateTime.now().difference(startedAt).inMilliseconds;
    }

    final path = await _simpleRecorder.stop();
    _isRecording = false;
    notifyListeners();
    return path;
  }

  @override
  void dispose() {
    if (_disposeWhenParentDisponse) {
      _disposeAll();
    }
    super.dispose();
  }

  void _disposeAll() {
    _simpleRecorder.dispose();
    _playerStateChangedSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    _audioPlayer.dispose();
    _process.dispose();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
    notifyListeners();
  }

  @override
  Future<void> seek(Duration duration) async {
    await _audioPlayer.seek(duration);
    notifyListeners();
  }

  @override
  Future<void> resume() async {
    await _audioPlayer.resume();
    notifyListeners();
  }
  
  @override
  AudioPlayer get audioPlayer => _audioPlayer;
}
