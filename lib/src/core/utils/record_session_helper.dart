import 'dart:math';

import 'package:path/path.dart' as p;

class RecordSessionHelper {
  static String sanitizeForFilePrefix(String input) {
    final buffer = StringBuffer();
    for (final codeUnit in input.codeUnits) {
      final isAlphaNum = (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 65 && codeUnit <= 90) ||
          (codeUnit >= 97 && codeUnit <= 122);
      buffer.write(isAlphaNum ? String.fromCharCode(codeUnit) : '_');
    }
    return buffer.toString();
  }

  static String buildRecordingFilePrefix({
    required int userIdFallback,
    required String appointmentIdEmr,
    required int appointmentId,
    Random? random,
    DateTime? now,
  }) {
    final resolvedRandom = random ?? Random();
    final resolvedNow = now ?? DateTime.now();

    final appointmentKey = sanitizeForFilePrefix(appointmentIdEmr);
    final rand = resolvedRandom.nextInt(1 << 32);
    return 'record_${userIdFallback}_${appointmentId}_'
        '${appointmentKey}_${resolvedNow.millisecondsSinceEpoch}_${rand}_';
  }

  static String generatePendingRecordingId({Random? random, DateTime? now}) {
    final resolvedRandom = random ?? Random();
    final resolvedNow = now ?? DateTime.now();
    final idRand = resolvedRandom.nextInt(1 << 32);
    return 'pr_${resolvedNow.microsecondsSinceEpoch}_$idRand';
  }

  static ({int appointmentId, String appointmentIdEmr})?
      parsePendingInfoFromRecordingFileName(String filePath) {
    try {
      final base = p.basenameWithoutExtension(filePath);
      final parts = base.split('_');

      if (parts.length < 7) {
        return null;
      }

      if (parts.first != 'record') {
        return null;
      }

      final appointmentId = int.tryParse(parts[2]);
      if (appointmentId == null) {
        return null;
      }

      final appointmentIdEmr = parts.sublist(3, parts.length - 3).join('_');
      if (appointmentIdEmr.trim().isEmpty) {
        return null;
      }

      return (appointmentId: appointmentId, appointmentIdEmr: appointmentIdEmr);
    } catch (_) {
      return null;
    }
  }
}
