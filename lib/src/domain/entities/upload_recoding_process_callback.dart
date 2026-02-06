import 'dart:io';

typedef UploadRecordingProgressCallback = Future<void> Function({
  required String appointmentIdEmr,
  String? content,
  required int appointmentId,
  required File record,
  required String locale,
  void Function(int sentBytes, int totalBytes)? onSendProgress,
});
