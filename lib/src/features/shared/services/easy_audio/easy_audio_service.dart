import 'dart:async';
import 'dart:developer';

import 'package:audio_session/audio_session.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/controllers/amplitude_monitor.dart';
import '../../../../core/controllers/recorder_state_observer.dart';
import '../../../../core/controllers/speech_recognition_controller.dart';
import '../../../../core/errors/easy_audio_exception.dart';
import '../../../../core/utils/recording_recovery.dart';
import '../../../../domain/entities/easy_audio_config.dart';
import '../../../../domain/entities/easy_audio_mode.dart';
import '../../../../domain/entities/easy_audio_service_context.dart';
import '../../../../domain/entities/easy_audio_state.dart';
import '../../../../domain/entities/recording_result.dart';
import '../../../../domain/entities/supported_locale.dart';
import '../../../../domain/entities/transcript_result.dart';
import '../../../../domain/usecases/easy_audio_initialize_usecase.dart';
import '../../../../domain/usecases/easy_audio_permissions_usecase.dart';
import '../../../../domain/usecases/easy_audio_recording_usecase.dart';
import 'easy_audio_service_interface.dart';

class EasyAudioService
    implements EasyAudioServiceInterface, EasyAudioServiceContext {
  static EasyAudioService? _instance;
  factory EasyAudioService() => _instance ??= EasyAudioService._();
  EasyAudioService._();

  final EasyAudioInitializeUseCase _initializeUseCase =
      EasyAudioInitializeUseCase();
  final EasyAudioPermissionsUseCase _permissionsUseCase =
      EasyAudioPermissionsUseCase();
  final EasyAudioRecordingUseCase _recordingUseCase =
      EasyAudioRecordingUseCase();

  AudioRecorder? _recorder;
  SpeechToText? _speechToText;

  RecorderStateObserver? _recorderStateObserver;

  StreamSubscription<AudioInterruptionEvent>? _audioInterruptionSub;

  bool _pauseRequestedByUser = false;
  bool _resumeRequestedByUser = false;
  bool _pausedByInterruption = false;

  EasyAudioConfig _config = const EasyAudioConfig();
  Future<void> Function()? resetAmplitudeOnStateChange;

  EasyAudioState _currentState = EasyAudioState.idle;
  bool _isInitialized = false;
  bool _speechAvailable = false;

  DateTime? _recordingStartTime;
  String? _currentFilePath;
  final StringBuffer _transcriptBuffer = StringBuffer();

  final _stateController = StreamController<EasyAudioState>.broadcast();
  final _transcriptController = StreamController<TranscriptResult>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();

  AmplitudeMonitor? _amplitudeMonitor;
  Timer? _maxDurationTimer;

  SpeechRecognitionController? _speechRecognition;

  bool _speechRecoveryInProgress = false;
  // DateTime? _lastSpeechRecoveryAt;

  @override
  Stream<EasyAudioState> get stateStream => _stateController.stream;

  @override
  Stream<TranscriptResult> get transcriptStream => _transcriptController.stream;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  EasyAudioState get currentState => _currentState;

  @override
  EasyAudioConfig get config => _config;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isRecording =>
      _currentState == EasyAudioState.recording ||
      _currentState == EasyAudioState.paused;

  @override
  String? get currentFilePath => _currentFilePath;

  @override
  bool get isSpeechAvailable => _speechAvailable;

  @override
  bool get wasPausedByInterruption => _pausedByInterruption;

  @override
  DateTime? get recordingStartTime => _recordingStartTime;

  @override
  Future<void> initialize([EasyAudioConfig? config]) async {
    _initializeUseCase.resumeAfterInterruption = _recoverFromSpeechInterruption;
    _permissionsUseCase.initSpeechToText = _initSpeechToText;

    await _initializeUseCase.initialize(
      this,
      config: config,
      onAutoResume: resume,
    );
  }

  Future<void> _initSpeechToText() async {
    speechToText ??= SpeechToText();
    if (!speechAvailable) {
      await _initializeUseCase.initSpeechToText(this);
    }
  }

  Future<void> _recoverFromSpeechInterruption() async {
    if (!_isInitialized) {
      return;
    }

    if (_config.mode == EasyAudioMode.recordOnly) {
      return;
    }

    final curState = _currentState;
    if (curState != EasyAudioState.recording &&
        curState != EasyAudioState.paused) {
      return;
    }

    if (_speechRecoveryInProgress) {
      return;
    }

    _speechRecoveryInProgress = true;

    try {
      if (_currentState == EasyAudioState.recording) {
        await _pauseResumeCycleForRecovery();
      } else if (_currentState == EasyAudioState.paused) {
        await _resetSpeechToTextForRecovery();
      }
    } finally {
      _speechRecoveryInProgress = false;
      await resetAmplitudeOnStateChange?.call();
    }
  }

  Future<void> _pauseResumeCycleForRecovery() async {
    if (_currentState != EasyAudioState.recording) {
      return;
    }

    try {
      await pause();
    } catch (e) {
      log('Error: Failed to pause during speech interruption recovery: $e');
      try {
        await _speechRecognition?.stop();
      } catch (e) {
        log('Error: Failed to stop speech recognition during recovery: $e');
      }
      _amplitudeMonitor?.stop();
      updateState(EasyAudioState.paused);
    }

    if (_currentState != EasyAudioState.paused) {
      return;
    }

    await _resetSpeechToTextForRecovery();

    await Future.delayed(const Duration(milliseconds: 400));

    try {
      await resume();
    } catch (e) {
      log('Error: Failed to resume after speech interruption recovery: $e');
    }
  }

  Future<void> _resetSpeechToTextForRecovery() async {
    if (_config.mode == EasyAudioMode.recordOnly) {
      return;
    }

    try {
      await _speechRecognition?.stop();
    } catch (e) {
      log('Error: Failed to stop speech recognition during recovery: $e');
    }

    try {
      await _speechToText?.cancel();
    } catch (e) {
      log('Error: Failed to cancel speech to text during recovery: $e');
    }

    _speechRecognition = null;
    _speechToText = SpeechToText();

    try {
      await _initSpeechToText();
      _speechAvailable = true;
    } catch (e) {
      log('Error: Failed to initialize speech to text during recovery: $e');
      _speechAvailable = false;
    }
  }

  @override
  Future<void> updateConfig(EasyAudioConfig config) async {
    await _initializeUseCase.updateConfig(
      this,
      config,
      reinitialize: () => initialize(config),
    );
  }

  @override
  Future<bool> hasRecordPermission() async {
    return _permissionsUseCase.hasRecordPermission(this);
  }

  @override
  Future<bool> hasSpeechPermission() async {
    return _permissionsUseCase.hasSpeechPermission(this);
  }

  @override
  Future<bool> requestPermissions() async {
    return _permissionsUseCase.requestPermissions(this);
  }

  @override
  Future<List<SupportedLocale>> getSupportedLocales() async {
    return _permissionsUseCase.getSupportedLocales(this);
  }

  @override
  Future<void> start() async {
    await _recordingUseCase.start(this);
  }

  @override
  Future<void> pause() async {
    await _recordingUseCase.pause(this);
  }

  @override
  Future<void> resume() async {
    await _recordingUseCase.resume(this);
  }

  @override
  Future<RecordingResult> stop() async {
    return _recordingUseCase.stop(this);
  }

  @override
  Future<void> cancel() async {
    await _recordingUseCase.cancel(this);
  }

  @override
  Future<RecordingResult?> recoverLastRecording() async {
    ensureInitialized();
    return RecordingRecovery.recoverLastRecording();
  }

  @override
  Future<void> dispose() async {
    await cancel();
    await _stateController.close();
    await _transcriptController.close();
    await _amplitudeController.close();
    await _recorderStateObserver?.detach();
    _recorderStateObserver = null;
    await _audioInterruptionSub?.cancel();
    _audioInterruptionSub = null;
    await _recorder?.dispose();
    _recorder = null;

    try {
      await _speechToText?.cancel();
    } catch (_) {}
    _speechToText = null;
    _isInitialized = false;
    _instance = null;
  }

  @override
  void ensureInitialized() {
    if (!_isInitialized) {
      throw EasyAudioException.notInitialized();
    }
  }

  @override
  void updateState(EasyAudioState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  @override
  AudioRecorder? get recorder => _recorder;
  @override
  set recorder(AudioRecorder? value) => _recorder = value;

  @override
  SpeechToText? get speechToText => _speechToText;
  @override
  set speechToText(SpeechToText? value) => _speechToText = value;

  @override
  RecorderStateObserver? get recorderStateObserver => _recorderStateObserver;
  @override
  set recorderStateObserver(RecorderStateObserver? value) =>
      _recorderStateObserver = value;

  @override
  StreamSubscription<AudioInterruptionEvent>? get audioInterruptionSub =>
      _audioInterruptionSub;
  @override
  set audioInterruptionSub(StreamSubscription<AudioInterruptionEvent>? value) =>
      _audioInterruptionSub = value;

  @override
  bool get pauseRequestedByUser => _pauseRequestedByUser;
  @override
  set pauseRequestedByUser(bool value) => _pauseRequestedByUser = value;

  @override
  bool get resumeRequestedByUser => _resumeRequestedByUser;
  @override
  set resumeRequestedByUser(bool value) => _resumeRequestedByUser = value;

  @override
  bool get pausedByInterruption => _pausedByInterruption;
  @override
  set pausedByInterruption(bool value) => _pausedByInterruption = value;

  @override
  set config(EasyAudioConfig value) => _config = value;

  @override
  set isInitialized(bool value) => _isInitialized = value;

  @override
  bool get speechAvailable => _speechAvailable;
  @override
  set speechAvailable(bool value) => _speechAvailable = value;

  @override
  set recordingStartTime(DateTime? value) => _recordingStartTime = value;

  @override
  set currentFilePath(String? value) => _currentFilePath = value;

  @override
  StringBuffer get transcriptBuffer => _transcriptBuffer;

  @override
  StreamController<EasyAudioState> get stateController => _stateController;
  @override
  StreamController<TranscriptResult> get transcriptController =>
      _transcriptController;
  @override
  StreamController<double> get amplitudeController => _amplitudeController;

  @override
  AmplitudeMonitor? get amplitudeMonitor => _amplitudeMonitor;
  @override
  set amplitudeMonitor(AmplitudeMonitor? value) => _amplitudeMonitor = value;

  @override
  Timer? get maxDurationTimer => _maxDurationTimer;
  @override
  set maxDurationTimer(Timer? value) => _maxDurationTimer = value;

  @override
  SpeechRecognitionController? get speechRecognition => _speechRecognition;
  @override
  set speechRecognition(SpeechRecognitionController? value) =>
      _speechRecognition = value;
}
