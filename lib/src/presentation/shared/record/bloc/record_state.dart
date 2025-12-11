part of 'record_bloc.dart';

@immutable
abstract class RecordState<T, A> {
  final RecordStateUI<T, A> stateUI;
  const RecordState(this.stateUI);
}

class RecordInitial<T, A> extends RecordState<T, A> {
  const RecordInitial(super.stateUI);
}

class RecordLoaded<T, A> extends RecordState<T, A> {
  const RecordLoaded(super.stateUI);
}

class RecordLoadingLanguageModel<T, A> extends RecordState<T, A> {
  const RecordLoadingLanguageModel(super.stateUI);
}

class PrepareLanguageModelLoading<T, A> extends RecordState<T, A> {
  const PrepareLanguageModelLoading(super.stateUI);
}

class PrepareLanguageModelLoaded<T, A> extends RecordState<T, A> {
  const PrepareLanguageModelLoaded(super.stateUI);
}

class PrepareLanguageModelError<T, A> extends RecordState<T, A> {
  final String message;
  final dynamic error;
  const PrepareLanguageModelError(super.stateUI, this.message, this.error);
}

class RecordAudioError<T, A> extends RecordState<T, A> {
  final String message;
  final dynamic error;
  const RecordAudioError(super.stateUI, this.message, this.error);
}

class RecordingAudio<T, A> extends RecordState<T, A> {
  const RecordingAudio(super.stateUI);
}

class RecordAudioDone<T, A> extends RecordState<T, A> {
  const RecordAudioDone(super.stateUI);
}

// ============ Audio Player States ============

class AudioPlayerInitedState<T, A> extends RecordState<T, A> {
  const AudioPlayerInitedState(super.stateUI);
}

class AudioStateUpdated<T, A> extends RecordState<T, A> {
  const AudioStateUpdated(super.stateUI);
}

// ============ Audio List States ============

class AudioListUpdated<T, A> extends RecordState<T, A> {
  const AudioListUpdated(super.stateUI);
}
