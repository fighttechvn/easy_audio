class DateTimeUtils {
  static String formatDateTime(DateTime dt) {
    final t = dt.toLocal();
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    return '$m/$d/$y $hh:$mm:$ss';
  }
}
