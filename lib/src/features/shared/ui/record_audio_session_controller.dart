import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';

import '../../../domain/entities/easy_audio_config.dart';
import '../../../domain/entities/easy_audio_mode.dart';
import '../../../domain/entities/easy_audio_state.dart';
import '../../../domain/entities/transcript_result.dart';
import '../services/easy_audio/easy_audio_service.dart';

class RecordAudioSessionController {
  RecordAudioSessionController({
    required this.easyAudio,
    required this.localeId,
    required this.enableAndroidBackgroundRecording,
    required this.onStateChanged,
    required this.onAmplitude,
    required this.onTranscript,
    required this.onPermissionDenied,
    required this.onInitFailed,
  });

  final EasyAudioService easyAudio;
  final String? localeId;
  final bool enableAndroidBackgroundRecording;

  final void Function(EasyAudioState state) onStateChanged;
  final void Function(double amp) onAmplitude;
  final void Function(TranscriptResult result) onTranscript;

  final void Function() onPermissionDenied;
  final void Function() onInitFailed;

  StreamSubscription<double>? _ampSub;
  StreamSubscription<TranscriptResult>? _transcriptSub;
  StreamSubscription<EasyAudioState>? _stateSub;

  bool _started = false;

  Future<void> initAndStart() async {
    if (_started) {
      return;
    }
    _started = true;

    final initialState = easyAudio.currentState;
    final wasActiveBefore = initialState == EasyAudioState.recording ||
        initialState == EasyAudioState.paused ||
        initialState == EasyAudioState.processing;

    final isIOS = Platform.isIOS;
    final mode = isIOS ? EasyAudioMode.realtime : EasyAudioMode.recordOnly;
    final config = EasyAudioConfig(
      mode: mode,
      locale: localeId,
      enableBackgroundRecording: enableAndroidBackgroundRecording,
      androidService: enableAndroidBackgroundRecording
          ? const AndroidService(
              title: 'Recording in progress',
              content: 'Tap to return to the app',
            )
          : null,
    );

    try {
      if (!easyAudio.isInitialized) {
        await easyAudio.initialize(config);
      } else {
        final canUpdateConfig = initialState == EasyAudioState.idle ||
            initialState == EasyAudioState.error;
        if (canUpdateConfig) {
          await easyAudio.updateConfig(config);
        }
      }

      onStateChanged(easyAudio.currentState);

      await _stateSub?.cancel();
      _stateSub = easyAudio.stateStream.listen(onStateChanged);

      await _ampSub?.cancel();
      _ampSub = easyAudio.amplitudeStream.listen(onAmplitude);

      await _transcriptSub?.cancel();
      _transcriptSub = easyAudio.transcriptStream.listen(onTranscript);

      if (!wasActiveBefore) {
        final ok = await easyAudio.requestPermissions();
        if (!ok) {
          onPermissionDenied();
          return;
        }

        await easyAudio.start();
      }

      onStateChanged(easyAudio.currentState);
    } catch (_) {
      if (!wasActiveBefore) {
        onInitFailed();
      }
    }
  }

  Future<void> dispose() async {
    await _ampSub?.cancel();
    await _transcriptSub?.cancel();
    await _stateSub?.cancel();
  }
}
