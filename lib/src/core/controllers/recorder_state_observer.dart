import 'dart:async';

import 'package:record/record.dart';

import '../../domain/entities/easy_audio_state.dart';

class RecorderStateObserver {
  RecorderStateObserver({
    required this.recorder,
    required this.getCurrentState,
    required this.isInitialized,
    required this.pauseRequestedByUser,
    required this.resumeRequestedByUser,
    required this.pauseOnInterruption,
    required this.autoResumeAfterInterruption,
    required this.onInterruptedPause,
    required this.onAutoResumeRequested,
  });

  final AudioRecorder recorder;
  final EasyAudioState Function() getCurrentState;
  final bool Function() isInitialized;

  final bool Function() pauseRequestedByUser;
  final bool Function() resumeRequestedByUser;

  final bool Function() pauseOnInterruption;
  final bool Function() autoResumeAfterInterruption;

  final Future<void> Function() onInterruptedPause;
  final Future<void> Function() onAutoResumeRequested;

  StreamSubscription<RecordState>? _sub;

  void attach() {
    detach();
    _sub = recorder.onStateChanged().listen(
      (state) {
        unawaited(_onRecorderStateChanged(state));
      },
      onError: (_) {
        // Best-effort: interruption detection is optional.
      },
    );
  }

  Future<void> detach() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _onRecorderStateChanged(RecordState state) async {
    if (!isInitialized()) {
      return;
    }

    if (state == RecordState.pause && pauseRequestedByUser()) {
      return;
    }
    if (state == RecordState.record && resumeRequestedByUser()) {
      return;
    }

    if (!pauseOnInterruption()) {
      return;
    }

    // Some platforms (notably iOS during phone call interruptions) may force
    // the recorder to stop instead of pausing. Treat this as an interruption
    // so the app can update UI and stop speech-to-text cleanly.
    if (state == RecordState.stop &&
        getCurrentState() == EasyAudioState.recording) {
      await onInterruptedPause();
      return;
    }

    if (state == RecordState.pause &&
        getCurrentState() == EasyAudioState.recording) {
      await onInterruptedPause();
      return;
    }

    if (state == RecordState.record &&
        getCurrentState() == EasyAudioState.paused &&
        autoResumeAfterInterruption()) {
      await onAutoResumeRequested();
    }
  }
}
