import 'dart:io';

import 'data_record.dart';

typedef UploadRecordingProgressCallback =
    Future<void> Function({
      required DataRecord<Map<String, dynamic>> data,
      String? content,
      required File record,
      required String locale,
      void Function(int sentBytes, int totalBytes)? onSendProgress,
    });
