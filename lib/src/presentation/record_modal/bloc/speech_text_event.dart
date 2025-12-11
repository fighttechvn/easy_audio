part of 'speech_text_bloc.dart';

@immutable
sealed class SpeechTextEvent {}

class InitSpeechToTextEvent extends SpeechTextEvent {
  final int retryCount;

  InitSpeechToTextEvent({this.retryCount = 0});
}

class StartRecordEvent extends SpeechTextEvent {
  final void Function(String) callbackToText;

  StartRecordEvent({required this.callbackToText});
}

class StopRecordEvent extends SpeechTextEvent {
  final bool isSave;

  StopRecordEvent({required this.isSave});
}

class PauseRecordEvent extends SpeechTextEvent {}

class ResumeRecordEvent extends SpeechTextEvent {}

class _SpeechPipelineErrorEvent extends SpeechTextEvent {
  _SpeechPipelineErrorEvent(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
