import 'package:flutter/foundation.dart';

@immutable
sealed class PendingUploadOrchestratorEffect {
  const PendingUploadOrchestratorEffect();

  String get pendingId;
}

final class PendingUploadQueued extends PendingUploadOrchestratorEffect {
  const PendingUploadQueued(this.pendingId);

  @override
  final String pendingId;
}

final class PendingUploadActive extends PendingUploadOrchestratorEffect {
  const PendingUploadActive(this.pendingId);

  @override
  final String pendingId;
}

final class PendingUploadProgress extends PendingUploadOrchestratorEffect {
  const PendingUploadProgress(this.pendingId, this.progress);

  @override
  final String pendingId;

  final double progress;
}

final class PendingUploadSucceeded extends PendingUploadOrchestratorEffect {
  const PendingUploadSucceeded({required this.pendingId, required this.id});

  @override
  final String pendingId;

  final String id;
}

final class PendingUploadFailed extends PendingUploadOrchestratorEffect {
  const PendingUploadFailed({
    required this.pendingId,
    required this.error,
    this.id,
  });

  @override
  final String pendingId;

  final Object error;
  final String? id;
}

final class PendingUploadCleared extends PendingUploadOrchestratorEffect {
  const PendingUploadCleared(this.pendingId);

  @override
  final String pendingId;
}
