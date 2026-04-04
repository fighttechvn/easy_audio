import 'dart:async';

import 'package:stt_record/stt_record.dart';

import '../../../easy_audio.dart';
import '../../core/controllers/amplitude_monitor.dart';
import '../../core/controllers/recorder_state_observer.dart';
import '../../core/controllers/speech_recognition_controller.dart';

abstract class EasyAudioServiceContext {
  SttRecord? get sttRecord;
  set sttRecord(SttRecord? value);

  RecorderStateObserver? get recorderStateObserver;
  set recorderStateObserver(RecorderStateObserver? value);

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
