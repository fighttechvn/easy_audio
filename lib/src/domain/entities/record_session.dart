import 'data_record.dart';

class RecordSession {
  const RecordSession({
    required this.data,
    this.clinicName,
    this.patientName,
    this.bookingDate,
    this.bookingTime,
    required this.localeId,
    required this.startedAt,
  });

  final DataRecord<Map<String, dynamic>> data;

  final String? clinicName;
  final String? patientName;
  final String? bookingDate;
  final String? bookingTime;

  /// null means "Auto"
  final String? localeId;

  final DateTime startedAt;
}
