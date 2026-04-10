import 'package:flutter/foundation.dart';

import '../../../domain/entities/upload_retry_policy.dart';

enum PendingUploadStatus { queued, uploading, success, failure }

@immutable
class PendingUploadItem {
  const PendingUploadItem({
    this.status,
    this.progress,
    this.error,
    this.updatedAt,
  });

  final PendingUploadStatus? status;
  final double? progress;
  final String? error;
  final DateTime? updatedAt;

  PendingUploadItem copyWith({
    PendingUploadStatus? status,
    double? progress,
    String? error,
    DateTime? updatedAt,
  }) {
    return PendingUploadItem(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class PendingUploadResult {
  const PendingUploadResult({
    required this.pendingId,
    required this.id,
    required this.success,
    required this.at,
  });

  final String pendingId;
  final String id;
  final bool success;
  final DateTime at;
}

@immutable
class PendingUploadUiState {
  const PendingUploadUiState({
    this.retryPolicy = const UploadRetryPolicy(),
    this.items = const <String, PendingUploadItem>{},
    this.activeUploadId,
    this.activeProgress = 0.0,
    this.lastResult,
  });

  final UploadRetryPolicy retryPolicy;
  final Map<String, PendingUploadItem> items;
  final String? activeUploadId;
  final double activeProgress;
  final PendingUploadResult? lastResult;

  PendingUploadUiState copyWith({
    UploadRetryPolicy? retryPolicy,
    Map<String, PendingUploadItem>? items,
    String? activeUploadId,
    double? activeProgress,
    PendingUploadResult? lastResult,
  }) {
    return PendingUploadUiState(
      retryPolicy: retryPolicy ?? this.retryPolicy,
      items: items ?? this.items,
      activeUploadId: activeUploadId,
      activeProgress: activeProgress ?? this.activeProgress,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}
