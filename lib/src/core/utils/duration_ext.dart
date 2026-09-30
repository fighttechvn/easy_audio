extension RecordAudioDurationExt on Duration {
  String formatElapsedMinutesSecondsCentiseconds() {
    final d = this;
    final centiseconds = d.inMilliseconds ~/ 10;
    final totalSeconds = centiseconds ~/ 100;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final cs = centiseconds % 100;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')},'
        '${cs.toString().padLeft(2, '0')}';
  }

  String get mmss {
    final totalSeconds = inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String formatDuration({bool includeHoursIfNonZero = true}) {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');

    if (includeHoursIfNonZero && inHours > 0) {
      final hours = inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
}
