import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/controllers/amplitude_monitor.dart';
import '../../core/controllers/recorder_state_observer.dart';
import '../../core/controllers/speech_recognition_controller.dart';
import 'easy_audio_config.dart';
import 'easy_audio_state.dart';
import 'transcript_result.dart';

abstract class EasyAudioServiceContext {
  AudioRecorder? get recorder;
  set recorder(AudioRecorder? value);

  SpeechToText? get speechToText;
  set speechToText(SpeechToText? value);

  RecorderStateObserver? get recorderStateObserver;
  set recorderStateObserver(RecorderStateObserver? value);

  StreamSubscription<AudioInterruptionEvent>? get audioInterruptionSub;
  set audioInterruptionSub(StreamSubscription<AudioInterruptionEvent>? value);

  bool get pauseRequestedByUser;
  set pauseRequestedByUser(bool value);

  bool get resumeRequestedByUser;
  set resumeRequestedByUser(bool value);

  bool get pausedByInterruption;
  set pausedByInterruption(bool value);

  EasyAudioConfig get config;
  set config(EasyAudioConfig value);

  EasyAudioState get currentState;

  bool get isInitialized;
  set isInitialized(bool value);

  bool get speechAvailable;
  set speechAvailable(bool value);

  DateTime? get recordingStartTime;
  set recordingStartTime(DateTime? value);

  String? get currentFilePath;
  set currentFilePath(String? value);

  StringBuffer get transcriptBuffer;

  StreamController<EasyAudioState> get stateController;
  StreamController<TranscriptResult> get transcriptController;
  StreamController<double> get amplitudeController;

  AmplitudeMonitor? get amplitudeMonitor;
  set amplitudeMonitor(AmplitudeMonitor? value);

  Timer? get maxDurationTimer;
  set maxDurationTimer(Timer? value);

  SpeechRecognitionController? get speechRecognition;
  set speechRecognition(SpeechRecognitionController? value);

  void ensureInitialized();

  void updateState(EasyAudioState state);
}
