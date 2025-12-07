import 'dart:io' show Platform;

/// Utility class for Record Modal
class RecordModalUtils {
  /// Detect if the platform supports pause/resume recording.
  /// Android requires SDK >= 24.
  static bool get supportsPauseResume {
    try {
      if (Platform.isAndroid) {
        final v = Platform.operatingSystemVersion; // e.g. 'Android 13 (SDK 33)'
        final sdkMatch = RegExp(r'SDK\s*(\d+)').firstMatch(v);
        if (sdkMatch != null) {
          final sdk = int.tryParse(sdkMatch.group(1) ?? '') ?? 0;
          return sdk >= 24;
        }
        // If cannot parse, be conservative and disable
        return false;
      }
      // iOS/macOS/web: allow by default
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Format duration as MM:SS,ms for display.
  static String formatElapsedForDisplay(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hundredths =
        (value.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    if (hours > 0) {
      final hoursText = hours.toString().padLeft(2, '0');
      return '$hoursText:$minutes:$seconds,$hundredths';
    }
    return '$minutes:$seconds,$hundredths';
  }

  /// Format time as HH:MM.
  static String formatClockTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
