import 'package:easy_audio/easy_audio.dart';
import 'package:equatable/equatable.dart';

abstract class RecordingEvent extends Equatable {
  const RecordingEvent();

  @override
  List<Object?> get props => [];
}

/// Toggle recording (start/stop/resume)
class RecordingTogglePressed extends RecordingEvent {
  const RecordingTogglePressed();
}

/// Pause recording
class RecordingPausePressed extends RecordingEvent {
  const RecordingPausePressed();
}

/// Cancel recording
class RecordingCancelPressed extends RecordingEvent {
  const RecordingCancelPressed();
}

/// Internal: audio state changed from stream
class RecordingAudioStateChanged extends RecordingEvent {
  const RecordingAudioStateChanged(this.state);

  final EasyAudioState state;

  @override
  List<Object?> get props => [state];
}

/// Internal: transcript received from stream
class RecordingTranscriptReceived extends RecordingEvent {
  const RecordingTranscriptReceived(this.result);

  final TranscriptResult result;

  @override
  List<Object?> get props => [result];
}

/// Internal: amplitude changed from stream
class RecordingAmplitudeChanged extends RecordingEvent {
  const RecordingAmplitudeChanged(this.amplitude);

  final double amplitude;

  @override
  List<Object?> get props => [amplitude];
}

/// Add a new recording to the list
class RecordingAdded extends RecordingEvent {
  const RecordingAdded(this.recording);

  final RecordingResult recording;

  @override
  List<Object?> get props => [recording];
}
