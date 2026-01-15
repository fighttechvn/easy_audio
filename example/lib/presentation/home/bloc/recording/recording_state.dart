import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/foundation.dart';

import '../../../../domain/entities/home_data.dart';

/// Data class cho Recording UI
@immutable
class RecordingStateUi {
  const RecordingStateUi({
    required this.audioState,
    required this.transcript,
    required this.liveTranscript,
    required this.amplitude,
    required this.recordings,
  });

  factory RecordingStateUi.initial() => const RecordingStateUi(
    audioState: EasyAudioState.idle,
    transcript: '',
    liveTranscript: '',
    amplitude: 0.0,
    recordings: <RecordingResult>[],
  );

  final EasyAudioState audioState;
  final String transcript;
  final String liveTranscript;
  final double amplitude;
  final List<RecordingResult> recordings;

  bool get isRecording => audioState == EasyAudioState.recording;
  bool get isPaused => audioState == EasyAudioState.paused;
  bool get isIdle => audioState == EasyAudioState.idle;

  RecordingStateUi copyWith({
    EasyAudioState? audioState,
    String? transcript,
    String? liveTranscript,
    double? amplitude,
    List<RecordingResult>? recordings,
  }) {
    return RecordingStateUi(
      audioState: audioState ?? this.audioState,
      transcript: transcript ?? this.transcript,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      amplitude: amplitude ?? this.amplitude,
      recordings: recordings ?? this.recordings,
    );
  }
}

// ============================================================================
// RECORDING STATES
// ============================================================================

@immutable
sealed class RecordingState {
  const RecordingState({required this.ui, this.snackBarMessage});

  final RecordingStateUi ui;
  final HomeSnackBarMessage? snackBarMessage;

  RecordingState withUi(RecordingStateUi newUi);
}

/// Idle state - ready to record
@immutable
class RecordingIdleState extends RecordingState {
  const RecordingIdleState({required super.ui, super.snackBarMessage});

  @override
  RecordingIdleState withUi(RecordingStateUi newUi) =>
      RecordingIdleState(ui: newUi, snackBarMessage: snackBarMessage);
}

/// Loading state - starting/stopping/pausing/resuming
@immutable
class RecordingLoadingState extends RecordingState {
  const RecordingLoadingState({
    required super.ui,
    super.snackBarMessage,
    required this.operation,
  });

  final RecordingOperation operation;

  @override
  RecordingLoadingState withUi(RecordingStateUi newUi) => RecordingLoadingState(
    ui: newUi,
    snackBarMessage: snackBarMessage,
    operation: operation,
  );
}

/// Active state - recording or paused
@immutable
class RecordingActiveState extends RecordingState {
  const RecordingActiveState({required super.ui, super.snackBarMessage});

  @override
  RecordingActiveState withUi(RecordingStateUi newUi) =>
      RecordingActiveState(ui: newUi, snackBarMessage: snackBarMessage);
}

/// Error state
@immutable
class RecordingErrorState extends RecordingState {
  const RecordingErrorState({
    required super.ui,
    super.snackBarMessage,
    required this.message,
    required this.errorType,
  });

  final String message;
  final HomeErrorType errorType;

  @override
  RecordingErrorState withUi(RecordingStateUi newUi) => RecordingErrorState(
    ui: newUi,
    snackBarMessage: snackBarMessage,
    message: message,
    errorType: errorType,
  );
}

enum RecordingOperation { starting, stopping, pausing, resuming, canceling }
