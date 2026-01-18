import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/foundation.dart';

import '../../../../domain/entities/home_data.dart';

/// Data class cho Playback UI
@immutable
class PlaybackStateUi {
  const PlaybackStateUi({
    required this.selectedRecording,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.transcript,
  });

  factory PlaybackStateUi.initial() => const PlaybackStateUi(
    selectedRecording: null,
    isPlaying: false,
    position: Duration.zero,
    duration: Duration.zero,
    transcript: '',
  );

  final RecordingResult? selectedRecording;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final String transcript;

  bool get hasSelection => selectedRecording != null;
  bool get isAudioSelected => selectedRecording?.filePath != null;

  PlaybackStateUi copyWith({
    RecordingResult? selectedRecording,
    bool clearSelection = false,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    String? transcript,
  }) {
    return PlaybackStateUi(
      selectedRecording: clearSelection
          ? null
          : (selectedRecording ?? this.selectedRecording),
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      transcript: transcript ?? this.transcript,
    );
  }
}

// ============================================================================
// PLAYBACK STATES
// ============================================================================

@immutable
sealed class PlaybackState {
  const PlaybackState({required this.ui, this.snackBarMessage});

  final PlaybackStateUi ui;
  final HomeSnackBarMessage? snackBarMessage;
}

/// Idle state - no playback active
@immutable
class PlaybackIdleState extends PlaybackState {
  const PlaybackIdleState({required super.ui, super.snackBarMessage});
}

/// Playing/Paused state
@immutable
class PlaybackActiveState extends PlaybackState {
  const PlaybackActiveState({required super.ui, super.snackBarMessage});
}

/// Error state
@immutable
class PlaybackErrorState extends PlaybackState {
  const PlaybackErrorState({
    required super.ui,
    super.snackBarMessage,
    required this.message,
  });

  final String message;
}
