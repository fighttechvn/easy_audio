import 'dart:math';

import 'package:path/path.dart' as p;

class RecordSessionHelper {
  static String sanitizeForFilePrefix(String input) {
    final buffer = StringBuffer();
    for (final codeUnit in input.codeUnits) {
      final isAlphaNum =
          (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 65 && codeUnit <= 90) ||
          (codeUnit >= 97 && codeUnit <= 122);
      buffer.write(isAlphaNum ? String.fromCharCode(codeUnit) : '_');
    }
    return buffer.toString();
  }

  static String buildRecordingFilePrefix({
    required int userIdFallback,
    required String contextId,
    Random? random,
    DateTime? now,
  }) {
    final resolvedRandom = random ?? Random();
    final resolvedNow = now ?? DateTime.now();

    final contextKey = sanitizeForFilePrefix(contextId);
    final rand = resolvedRandom.nextInt(1 << 32);
    return 'record_${userIdFallback}_ctx_${contextKey}_'
        '${resolvedNow.millisecondsSinceEpoch}_${rand}_';
  }

  static String generatePendingRecordingId({Random? random, DateTime? now}) {
    final resolvedRandom = random ?? Random();
    final resolvedNow = now ?? DateTime.now();
    final idRand = resolvedRandom.nextInt(1 << 32);
    return 'pr_${resolvedNow.microsecondsSinceEpoch}_$idRand';
  }

  static ({String dataId, int? legacyNumericId})?
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

      // New format: record_{userId}_ctx_{contextKey}_{millis}_{rand}_
      if (parts[2] == 'ctx') {
        final dataId = parts.sublist(3, parts.length - 3).join('_');
        if (dataId.trim().isEmpty) {
          return null;
        }
        return (dataId: dataId, legacyNumericId: null);
      }

      // Legacy format:
      // record_{userId}_{legacyNumericId}_{dataId}_{millis}_{rand}_
      final legacyNumericId = int.tryParse(parts[2]);
      if (legacyNumericId == null) {
        return null;
      }

      final dataId = parts.sublist(3, parts.length - 3).join('_');
      if (dataId.trim().isEmpty) {
        return null;
      }

      return (dataId: dataId, legacyNumericId: legacyNumericId);
    } catch (_) {
      return null;
    }
  }
}
