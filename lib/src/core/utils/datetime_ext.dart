import 'package:intl/intl.dart';

extension RecordAudioDateTimeExt on DateTime {
  /// Matches app_core's `showConfirmBooking` formatting.
  String get showConfirmBooking =>
      DateFormat('EEEE · MMMM dd, y · hh:mm a').format(this);

  /// Matches app_core's `formatMonthDayYearTime()` formatting.
  String formatMonthDayYearTime() {
    final dt = this;
    final m = dt.month;
    final d = dt.day;
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$m/$d/$y $hh:$mm';
  }
}
