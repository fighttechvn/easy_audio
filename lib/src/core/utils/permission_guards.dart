import 'package:stt_record/stt_record.dart';

import '../../domain/entities/easy_audio_mode.dart';
import '../errors/easy_audio_exception.dart';

class PermissionGuards {
  PermissionGuards._();

  static Future<void> ensureCanStart({
    required EasyAudioMode mode,
    required SttRecord sttRecord,
  }) async {
    final hasPermission = await sttRecord.hasPermission();
    if (!hasPermission) {
      throw EasyAudioException.microphonePermissionDenied();
    }
  }
}
