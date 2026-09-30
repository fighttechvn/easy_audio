part of 'pending_upload_bloc.dart';

@immutable
sealed class PendingUploadEvent {
  const PendingUploadEvent();
}

final class PendingUploadSubscriptionRequested extends PendingUploadEvent {
  const PendingUploadSubscriptionRequested();
}

final class PendingUploadEnqueueRequested extends PendingUploadEvent {
  const PendingUploadEnqueueRequested({required this.id, this.completer});

  final String id;
  final Completer<void>? completer;
}

final class PendingUploadEnqueueManyRequested extends PendingUploadEvent {
  const PendingUploadEnqueueManyRequested({required this.ids, this.completer});

  final Iterable<String> ids;
  final Completer<void>? completer;
}

final class PendingUploadEnqueueAllPendingForUserRequested
    extends PendingUploadEvent {
  const PendingUploadEnqueueAllPendingForUserRequested({
    required this.userId,
    this.completer,
  });

  final int? userId;
  final Completer<void>? completer;
}

final class PendingUploadRetryRequested extends PendingUploadEvent {
  const PendingUploadRetryRequested({required this.id, this.completer});

  final String id;
  final Completer<void>? completer;
}

final class PendingUploadRetryPolicyUpdateRequested extends PendingUploadEvent {
  const PendingUploadRetryPolicyUpdateRequested({
    required this.retryPolicy,
    this.completer,
  });

  final UploadRetryPolicy retryPolicy;
  final Completer<void>? completer;
}

final class _PendingUploadOrchestratorEffectReceived
    extends PendingUploadEvent {
  const _PendingUploadOrchestratorEffectReceived(this.effect);

  final PendingUploadOrchestratorEffect effect;
}
