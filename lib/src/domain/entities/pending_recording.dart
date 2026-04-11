import 'package:flutter/foundation.dart';

import 'record_session.dart';

typedef NowFn = DateTime Function();

DateTime defaultNow() => DateTime.now();

enum PendingRecordingStatus { pending, uploading, failed }

@immutable
class PendingRecording {
  const PendingRecording({
    required this.id,
    required this.userId,
    required this.appointmentIdEmr,
    required this.appointmentId,
    this.clinicName,
    this.patientName,
    this.bookingDate,
    this.bookingTime,
    required this.locale,
    required this.content,
    required this.filePath,
    required this.fileSizeBytes,
    this.durationMs,
    required this.createdAt,
    required this.status,
    required this.retryCount,
    this.lastAttemptAt,
    this.lastError,
  });

  final String id;
  final int? userId;
  final String appointmentIdEmr;
  final int appointmentId;

  final String? clinicName;
  final String? patientName;
  final String? bookingDate;
  final String? bookingTime;

  final String locale;
  final String content;

  final String filePath;
  final int fileSizeBytes;

  /// Duration in milliseconds (may be null if unknown).
  final int? durationMs;

  final DateTime createdAt;
  final PendingRecordingStatus status;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String? lastError;

  String? get formattedDuration {
    final ms = durationMs;
    if (ms == null || ms <= 0) {
      return null;
    }

    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String? get bookingLine {
    final bookingParts = [bookingDate, bookingTime]
        .where((v) => (v ?? '').trim().isNotEmpty)
        .map((v) => v!.trim())
        .toList(growable: false);
    final bookingText = bookingParts.join(' ');
    return bookingText.isEmpty ? null : 'Booking: $bookingText';
  }

  String get infoRecord {
    final statusText = switch (status) {
      PendingRecordingStatus.pending => 'Pending',
      PendingRecordingStatus.uploading => 'Uploading',
      PendingRecordingStatus.failed => 'Failed',
    };

    final retrySuffix = retryCount > 0 ? ' (retry $retryCount/3)' : '';
    final statusLine = '$statusText$retrySuffix';

    return [
      if ((patientName ?? '').trim().isNotEmpty)
        'Patient: ${patientName!.trim()}',
      if ((clinicName ?? '').trim().isNotEmpty) 'Clinic: ${clinicName!.trim()}',
      if (bookingLine != null) bookingLine,
      appointmentIdEmr,
      statusLine,
    ].join('\n');
  }

  String get fileSizeText {
    return _formatFileSize(fileSizeBytes);
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '--';
    }
    if (bytes < 1024) {
      return '${bytes}B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  PendingRecording copyWith({
    int? userId,
    String? appointmentIdEmr,
    int? appointmentId,
    String? clinicName,
    String? patientName,
    String? bookingDate,
    String? bookingTime,
    String? locale,
    String? content,
    String? filePath,
    int? fileSizeBytes,
    int? durationMs,
    DateTime? createdAt,
    PendingRecordingStatus? status,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? lastError,
  }) {
    return PendingRecording(
      id: id,
      userId: userId ?? this.userId,
      appointmentIdEmr: appointmentIdEmr ?? this.appointmentIdEmr,
      appointmentId: appointmentId ?? this.appointmentId,
      clinicName: clinicName ?? this.clinicName,
      patientName: patientName ?? this.patientName,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      locale: locale ?? this.locale,
      content: content ?? this.content,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
    );
  }

  factory PendingRecording.fromRecordSession(
    RecordSession session, {
    required String id,
    required int? userId,
    required String locale,
    required String content,
    required String filePath,
    required int fileSizeBytes,
    required int durationMs,
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();

    return PendingRecording(
      id: id,
      userId: userId,
      appointmentIdEmr: session.appointmentIdEmr,
      appointmentId: session.appointmentId,
      clinicName: session.clinicName,
      patientName: session.patientName,
      bookingDate: session.bookingDate,
      bookingTime: session.bookingTime,
      locale: locale,
      content: content,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      durationMs: durationMs,
      createdAt: createdAt,
      status: PendingRecordingStatus.pending,
      retryCount: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'appointmentIdEmr': appointmentIdEmr,
      'appointmentId': appointmentId,
      'clinicName': clinicName,
      'patientName': patientName,
      'bookingDate': bookingDate,
      'bookingTime': bookingTime,
      'locale': locale,
      'content': content,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'durationMs': durationMs,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'retryCount': retryCount,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'lastError': lastError,
    };
  }

  factory PendingRecording.fromJson(Map<String, dynamic> json) {
    final statusName =
        (json['status'] ?? PendingRecordingStatus.pending.name).toString();

    final status = PendingRecordingStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => PendingRecordingStatus.pending,
    );

    return PendingRecording(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] as num?)?.toInt(),
      appointmentIdEmr: (json['appointmentIdEmr'] ?? '').toString(),
      appointmentId: (json['appointmentId'] as num?)?.toInt() ?? 0,
      clinicName: json['clinicName']?.toString(),
      patientName: json['patientName']?.toString(),
      bookingDate: json['bookingDate']?.toString(),
      bookingTime: json['bookingTime']?.toString(),
      locale: (json['locale'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      filePath: (json['filePath'] ?? '').toString(),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: status,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.tryParse(json['lastAttemptAt'].toString())
          : null,
      lastError: json['lastError']?.toString(),
    );
  }
}

extension PendingRecordingRetryX on PendingRecording {
  PendingRecording markFailed({
    required String error,
    required int retryCount,
    NowFn now = defaultNow,
  }) {
    return copyWith(
      status: PendingRecordingStatus.failed,
      lastAttemptAt: now(),
      lastError: error,
      retryCount: retryCount,
    );
  }

  PendingRecording markUploading({NowFn now = defaultNow}) {
    return copyWith(
      status: PendingRecordingStatus.uploading,
      lastAttemptAt: now(),
      lastError: null,
    );
  }

  PendingRecording markPendingAfterFailure({
    required String error,
    required int retryCount,
    required bool isLastAttempt,
    NowFn now = defaultNow,
  }) {
    return copyWith(
      status: isLastAttempt
          ? PendingRecordingStatus.failed
          : PendingRecordingStatus.pending,
      retryCount: retryCount,
      lastAttemptAt: now(),
      lastError: error,
    );
  }
}
