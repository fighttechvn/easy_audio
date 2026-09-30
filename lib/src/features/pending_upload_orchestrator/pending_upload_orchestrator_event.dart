part of 'pending_upload_orchestrator_bloc.dart';

@immutable
sealed class PendingUploadOrchestratorBlocEvent {
  const PendingUploadOrchestratorBlocEvent();
}

final class PendingUploadOrchestratorEnqueueRequested
    extends PendingUploadOrchestratorBlocEvent {
  const PendingUploadOrchestratorEnqueueRequested({
    required this.id,
    this.completer,
  });

  final String id;
  final Completer<void>? completer;
}

final class PendingUploadOrchestratorEnqueueManyRequested
    extends PendingUploadOrchestratorBlocEvent {
  const PendingUploadOrchestratorEnqueueManyRequested({
    required this.ids,
    this.completer,
  });

  final Iterable<String> ids;
  final Completer<void>? completer;
}

final class PendingUploadOrchestratorEnqueueAllPendingForUserRequested
    extends PendingUploadOrchestratorBlocEvent {
  const PendingUploadOrchestratorEnqueueAllPendingForUserRequested({
    required this.userId,
    this.completer,
  });

  final int? userId;
  final Completer<void>? completer;
}

final class PendingUploadOrchestratorRetryRequested
    extends PendingUploadOrchestratorBlocEvent {
  const PendingUploadOrchestratorRetryRequested({
    required this.id,
    this.completer,
  });

  final String id;
  final Completer<void>? completer;
}

final class _PendingUploadOrchestratorEffectRaised
    extends PendingUploadOrchestratorBlocEvent {
  const _PendingUploadOrchestratorEffectRaised(this.effect);

  final PendingUploadOrchestratorEffect effect;
}

final class _PendingUploadOrchestratorSnapshotRequested
    extends PendingUploadOrchestratorBlocEvent {
  const _PendingUploadOrchestratorSnapshotRequested();
}

final class PendingUploadOrchestratorRetryPolicyUpdateRequested
    extends PendingUploadOrchestratorBlocEvent {
  const PendingUploadOrchestratorRetryPolicyUpdateRequested({
    required this.retryPolicy,
    this.completer,
  });

  final UploadRetryPolicy retryPolicy;
  final Completer<void>? completer;
}
