class RecordSession {
  const RecordSession({
    required this.appointmentIdEmr,
    required this.appointmentId,
    this.clinicName,
    this.patientName,
    this.bookingDate,
    this.bookingTime,
    required this.localeId,
    required this.startedAt,
  });

  final String appointmentIdEmr;
  final int appointmentId;

  final String? clinicName;
  final String? patientName;
  final String? bookingDate;
  final String? bookingTime;

  /// null means "Auto"
  final String? localeId;

  final DateTime startedAt;
}
