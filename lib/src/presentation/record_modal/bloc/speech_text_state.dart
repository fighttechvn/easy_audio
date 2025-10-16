part of 'speech_text_bloc.dart';

@immutable
sealed class SpeechTextState {
  final SpeechTextStateUI stateUI;

  const SpeechTextState(this.stateUI);
}

class SpeechTextInitial extends SpeechTextState {
  const SpeechTextInitial(super.stateUI);
}

class InitialingService extends SpeechTextState {
  const InitialingService(super.stateUI);
}

class InitFailed extends SpeechTextState {
  const InitFailed(super.stateUI);
}

class InitSucceeded extends SpeechTextState {
  const InitSucceeded(super.stateUI);
}

class Recording extends SpeechTextState {
  const Recording(super.stateUI);
}

class PausedRecording extends SpeechTextState {
  const PausedRecording(super.stateUI);
}

class RecordError extends SpeechTextState {
  final String message;
  final dynamic error;
  const RecordError(super.stateUI, this.message, this.error);
}

class StopingRecord extends SpeechTextState {
  const StopingRecord(super.stateUI);
}

class StoppedRecord extends SpeechTextState {
  final bool isSave;
  final String? filePath;
  final Duration recordedDuration;
  final bool recordingAvailable;

  const StoppedRecord(
    super.stateUI,
    this.isSave, {
    required this.recordedDuration,
    this.filePath,
    this.recordingAvailable = false,
  });
}
