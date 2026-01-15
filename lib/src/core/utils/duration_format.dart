String formatDuration(Duration duration, {bool includeHoursIfNonZero = true}) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (includeHoursIfNonZero && duration.inHours > 0) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  return '$minutes:$seconds';
}
