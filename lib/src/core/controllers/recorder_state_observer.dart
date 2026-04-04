import 'dart:async';

import 'package:stt_record/stt_record.dart';

import '../../domain/entities/easy_audio_state.dart';

class RecorderStateObserver {
  RecorderStateObserver({
    required this.sttRecord,
    required this.getCurrentState,
    required this.isInitialized,
    required this.pauseRequestedByUser,
    required this.resumeRequestedByUser,
    required this.autoResumeAfterInterruption,
    required this.onInterruptedPause,
    required this.onAutoResumeRequested,
  });

  final SttRecord sttRecord;
  final EasyAudioState Function() getCurrentState;
  final bool Function() isInitialized;

  final bool Function() pauseRequestedByUser;
  final bool Function() resumeRequestedByUser;

  final bool Function() autoResumeAfterInterruption;

  final Future<void> Function() onInterruptedPause;
  final Future<void> Function() onAutoResumeRequested;

  StreamSubscription<SttRecordSessionState>? _sub;

  void attach() {
    detach();
    _sub = sttRecord.sessionStates.listen(
      (state) {
        unawaited(_onSessionStateChanged(state));
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

  Future<void> _onSessionStateChanged(SttRecordSessionState state) async {
    if (!isInitialized()) {
      return;
    }

    if (state == SttRecordSessionState.paused && pauseRequestedByUser()) {
      return;
    }
    if (state == SttRecordSessionState.resumed && resumeRequestedByUser()) {
      return;
    }

    if (state == SttRecordSessionState.paused &&
        getCurrentState() == EasyAudioState.recording) {
      await onInterruptedPause();
      return;
    }

    if (state == SttRecordSessionState.resumed &&
        getCurrentState() == EasyAudioState.paused) {
      if (autoResumeAfterInterruption()) {
        await onAutoResumeRequested();
      } else {
        // Some native implementations may auto-resume after interruptions.
        // If the app has auto-resume disabled, best-effort keep the session
        // paused so UI and audio stay consistent.
        try {
          await sttRecord.pause();
        } catch (_) {
          // ignore
        }
      }
    }
  }
}
