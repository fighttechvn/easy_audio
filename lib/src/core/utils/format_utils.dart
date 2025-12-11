class FormatUtils {
  /// Format duration as MM:SS (e.g., "02:35")
  static String formatDuration(Duration? duration) {
    if (duration == null) {
      return '00:00';
    }
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Format date as DD/MM/YYYY HH:MM (e.g., "10/12/2024 10:30")
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
