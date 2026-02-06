import 'package:flutter/foundation.dart';

import '../../../domain/entities/upload_retry_policy.dart';
import 'pending_upload_orchestrator_effect.dart';

@immutable
class PendingUploadOrchestratorUiState {
  const PendingUploadOrchestratorUiState({
    this.queue = const <String>{},
    this.isPumping = false,
    this.retryPolicy = const UploadRetryPolicy(),
    this.effect,
    this.effectId = 0,
  });

  final Set<String> queue;
  final bool isPumping;
  final UploadRetryPolicy retryPolicy;
  final PendingUploadOrchestratorEffect? effect;
  final int effectId;

  PendingUploadOrchestratorUiState copyWith({
    Set<String>? queue,
    bool? isPumping,
    UploadRetryPolicy? retryPolicy,
    PendingUploadOrchestratorEffect? effect,
    int? effectId,
  }) {
    return PendingUploadOrchestratorUiState(
      queue: queue ?? this.queue,
      isPumping: isPumping ?? this.isPumping,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      effect: effect ?? this.effect,
      effectId: effectId ?? this.effectId,
    );
  }
}
