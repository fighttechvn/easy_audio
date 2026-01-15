import 'package:easy_audio/easy_audio.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart' hide PlaybackEvent;

abstract class PlaybackEvent extends Equatable {
  const PlaybackEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped on a recording to play
class PlaybackRecordingSelected extends PlaybackEvent {
  const PlaybackRecordingSelected(this.recording);

  final RecordingResult recording;

  @override
  List<Object?> get props => [recording.filePath, recording.startTime];
}

/// Toggle play/pause
class PlaybackTogglePressed extends PlaybackEvent {
  const PlaybackTogglePressed();
}

/// Stop playback
class PlaybackStopPressed extends PlaybackEvent {
  const PlaybackStopPressed();
}

/// Close playback panel
class PlaybackClosed extends PlaybackEvent {
  const PlaybackClosed();
}

/// Seek to position
class PlaybackSeeked extends PlaybackEvent {
  const PlaybackSeeked(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

/// Internal: position changed from stream
class PlaybackPositionChanged extends PlaybackEvent {
  const PlaybackPositionChanged(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

/// Internal: duration changed from stream
class PlaybackDurationChanged extends PlaybackEvent {
  const PlaybackDurationChanged(this.duration);

  final Duration? duration;

  @override
  List<Object?> get props => [duration];
}

/// Internal: player state changed from stream
class PlaybackPlayerStateChanged extends PlaybackEvent {
  const PlaybackPlayerStateChanged(this.playerState);

  final PlayerState playerState;

  @override
  List<Object?> get props => [playerState.playing, playerState.processingState];
}
