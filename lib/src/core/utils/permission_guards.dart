import 'package:record/record.dart';

import '../../domain/entities/easy_audio_mode.dart';
import '../errors/easy_audio_exception.dart';

class PermissionGuards {
  PermissionGuards._();

  static Future<void> ensureCanStart({
    required EasyAudioMode mode,
    required AudioRecorder recorder,
    required bool speechAvailable,
  }) async {
    if (mode != EasyAudioMode.speechToTextOnly) {
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) {
        throw EasyAudioException.microphonePermissionDenied();
      }
    }

    if (mode != EasyAudioMode.recordOnly && !speechAvailable) {
      throw EasyAudioException.speechPermissionDenied();
    }
  }
}
