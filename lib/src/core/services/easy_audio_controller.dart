import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../domain/entities/amp.dart';
import '../../domain/entities/process_player.dart';

abstract class EasyAudioInterface {
  Future<void> initPlayer([bool disposeWhenParentDisponse = true]);
  Future<void> play([String? urlAudio]);
  Future<void> stopPlayer();
  Future<void> pause();
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
}

class EasyAudioController extends ChangeNotifier implements EasyAudioInterface {
  /// AudioPlayer
  final _audioPlayer = AudioPlayer();
  late StreamSubscription<void> _playerStateChangedSubscription;
  late StreamSubscription<Duration?> _durationChangedSubscription;
  late StreamSubscription<Duration> _positionChangedSubscription;
  final _process = ValueNotifier<ProcessPlayer>(ProcessPlayer());

  /// Audio Record
  final _audioRecorder = Record();
  final _amplitude = ValueNotifier<Amp?>(null);

  DateTime? _startRecord;
  StreamSubscription<Amplitude>? _amplitudeSub;

  var _url = '';
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
    if (_mPlayerIsInited == false) {
      /// Player Audio
      _playerStateChangedSubscription =
          _audioPlayer.onPlayerComplete.listen((state) async {
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

      /// Record Audio
      _disposeWhenParentDisponse = disposeWhenParentDisponse;

      _amplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 300))
          .listen((amp) {
        _amplitude.value = amp.toAmp();
      });
      _mPlayerIsInited = true;
    }
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

      final audioSource =
          _url.contains('http') ? UrlSource(_url) : DeviceFileSource(_url);

      await _audioPlayer.play(audioSource);

      notifyListeners();
    } else {
      if (_mPlayerIsInited && _audioPlayer.state == PlayerState.playing) {
        await stopPlayer();
      }
    }
  }

  @override
  Future<void> record() async {
    try {
      _startRecord = null;
      if (await _audioRecorder.hasPermission()) {
        _isRecording = true;
        final tempDir = await getTemporaryDirectory();
        final tempPath = tempDir.path;

        await _audioRecorder.start(
          path: '$tempPath/recor_${DateTime.now().millisecondsSinceEpoch}.m4a',
          encoder: AudioEncoder.aacLc,
        );

        _startRecord = DateTime.now();
        notifyListeners();
      }
    } catch (e) {
      ///
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
    final endTime = DateTime.now().difference(_startRecord!);
    _timeRecord = endTime.inMilliseconds;
    final urlRecord = await _audioRecorder.stop();
    _isRecording = false;

    notifyListeners();
    return urlRecord;
  }

  @override
  void dispose() {
    if (_disposeWhenParentDisponse) {
      _disposeAll();
    }
    super.dispose();
  }

  void _disposeAll() {
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    _playerStateChangedSubscription.cancel();
    _positionChangedSubscription.cancel();
    _durationChangedSubscription.cancel();
    _audioPlayer.dispose();
    _process.dispose();
    _amplitude.dispose();
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
}

extension StringExtCodec on String {
  AudioEncoder get getCodec {
    final extension = split('.').last;
    switch (extension) {
      case 'pcm':
        return AudioEncoder.pcm16bit;
      case 'aac':
        return AudioEncoder.aacLc;
      default:
        return AudioEncoder.pcm16bit;
    }
  }
}
