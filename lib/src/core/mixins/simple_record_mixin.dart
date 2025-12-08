import 'package:flutter/material.dart';

import '../../domain/entities/record_data.dart';
import '../../presentation/simple_record/easy_audio.dart';

mixin SimpleRecordMixin<T extends StatefulWidget> on State<T> {
  Future<void> onRecordComplete(RecordData result);
  Future<bool> requestPermissions();

  /// Current locale for speech-to-text.
  ///
  /// Override to use a different locale than the default.
  /// Default: uses [EasyAudioConfig.defaultLocale].
  String get currentLocale => EasyAudio.instance.config.defaultLocale;

  /// Transcript label prefix.
  ///
  /// Override to customize the label shown during recording.
  /// Default: uses [EasyAudioConfig.defaultTranscriptLabel].
  String get transcriptLabel =>
      EasyAudio.instance.config.defaultTranscriptLabel;

  Future<void> startRecording() async {
    final granted = await requestPermissions();
    if (!granted) {
      if (mounted) {
        showPermissionDeniedError();
      }
      return;
    }

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final result = await EasyAudio.instance.openRecordModal(
      title: transcriptLabel,
      locale: currentLocale,
    );

    if (result != null && mounted) {
      await onRecordComplete(result);
    }
  }

  void showPermissionDeniedError() {
    if (!mounted) {
      return;
    }
    final message =
        EasyAudio.instance.config.localizations.permissionDeniedMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showRecordingError(Object error) {
    if (!mounted) {
      return;
    }
    final message =
        EasyAudio.instance.config.localizations.recordingFailedMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message: $error'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
