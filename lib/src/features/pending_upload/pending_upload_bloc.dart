import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/upload_retry_policy.dart';
import '../pending_upload_orchestrator/pending_upload_orchestrator_bloc.dart';
import '../pending_upload_orchestrator/ui_state/pending_upload_orchestrator_effect.dart';
import 'ui_state/pending_upload_ui_state.dart';

part 'pending_upload_event.dart';
part 'pending_upload_state.dart';

@lazySingleton
class PendingUploadBloc extends Bloc<PendingUploadEvent, PendingUploadState> {
  PendingUploadBloc(this._orchestrator)
      : super(
          PendingUploadInitial(
            uiState: PendingUploadUiState(
              retryPolicy: _orchestrator.state.uiState.retryPolicy,
            ),
          ),
        ) {
    on<PendingUploadSubscriptionRequested>(_onSubscriptionRequested);
    on<PendingUploadEnqueueRequested>(_onEnqueueRequested);
    on<PendingUploadEnqueueManyRequested>(_onEnqueueManyRequested);
    on<PendingUploadEnqueueAllPendingForUserRequested>(
      _onEnqueueAllPendingForUserRequested,
    );
    on<PendingUploadRetryRequested>(_onRetryRequested);
    on<PendingUploadRetryPolicyUpdateRequested>(_onRetryPolicyUpdateRequested);

    on<_PendingUploadOrchestratorEffectReceived>(_onOrchestratorEffectReceived);
  }

  final PendingUploadOrchestratorBloc _orchestrator;
  StreamSubscription<PendingUploadOrchestratorState>? _subscription;
  int _lastOrchestratorEventId = 0;

  double? progressFor(String id) => state.items[id]?.progress;

  bool get hasActiveUpload => state.activeUploadId != null;

  Future<void> enqueue(String id) {
    final completer = Completer<void>();
    add(PendingUploadEnqueueRequested(id: id, completer: completer));
    return completer.future;
  }

  Future<void> enqueueMany(Iterable<String> ids) {
    final completer = Completer<void>();
    add(PendingUploadEnqueueManyRequested(ids: ids, completer: completer));
    return completer.future;
  }

  Future<void> enqueueAllPendingForUser(int? userId) {
    final completer = Completer<void>();
    add(
      PendingUploadEnqueueAllPendingForUserRequested(
        userId: userId,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> retry(String id) {
    final completer = Completer<void>();
    add(PendingUploadRetryRequested(id: id, completer: completer));
    return completer.future;
  }

  void _ensureSubscribed() {
    if (_subscription != null) {
      return;
    }

    _subscription = _orchestrator.stream.listen(
      (orchestratorState) {
        final uiState = orchestratorState.uiState;
        if (uiState.effect == null ||
            uiState.effectId == _lastOrchestratorEventId) {
          return;
        }
        _lastOrchestratorEventId = uiState.effectId;
        add(_PendingUploadOrchestratorEffectReceived(uiState.effect!));
      },
      onError: (e, trace) {
        if (kDebugMode) {
          print(e);
          print(trace);
        }
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }

  void _onSubscriptionRequested(
    PendingUploadSubscriptionRequested event,
    Emitter<PendingUploadState> emit,
  ) {
    _ensureSubscribed();
  }

  Future<void> _onEnqueueRequested(
    PendingUploadEnqueueRequested event,
    Emitter<PendingUploadState> emit,
  ) async {
    try {
      _ensureSubscribed();
      await _orchestrator.enqueue(event.id);
      event.completer?.complete();
    } catch (e, trace) {
      event.completer?.completeError(e, trace);
    }
  }

  Future<void> _onEnqueueManyRequested(
    PendingUploadEnqueueManyRequested event,
    Emitter<PendingUploadState> emit,
  ) async {
    try {
      _ensureSubscribed();
      await _orchestrator.enqueueMany(event.ids);
      event.completer?.complete();
    } catch (e, trace) {
      event.completer?.completeError(e, trace);
    }
  }

  Future<void> _onEnqueueAllPendingForUserRequested(
    PendingUploadEnqueueAllPendingForUserRequested event,
    Emitter<PendingUploadState> emit,
  ) async {
    try {
      _ensureSubscribed();
      await _orchestrator.enqueueAllPendingForUser(event.userId);
      event.completer?.complete();
    } catch (e, trace) {
      event.completer?.completeError(e, trace);
    }
  }

  Future<void> _onRetryRequested(
    PendingUploadRetryRequested event,
    Emitter<PendingUploadState> emit,
  ) async {
    try {
      _ensureSubscribed();
      await _orchestrator.retry(event.id);
      event.completer?.complete();
    } catch (e, trace) {
      event.completer?.completeError(e, trace);
    }
  }

  Future<void> _onRetryPolicyUpdateRequested(
    PendingUploadRetryPolicyUpdateRequested event,
    Emitter<PendingUploadState> emit,
  ) async {
    try {
      _orchestrator.add(
        PendingUploadOrchestratorRetryPolicyUpdateRequested(
          retryPolicy: event.retryPolicy,
        ),
      );

      emit(
        PendingUploadInitial(
          uiState: state.uiState.copyWith(retryPolicy: event.retryPolicy),
        ),
      );

      event.completer?.complete();
    } catch (e, trace) {
      event.completer?.completeError(e, trace);
    }
  }

  void _onOrchestratorEffectReceived(
    _PendingUploadOrchestratorEffectReceived event,
    Emitter<PendingUploadState> emit,
  ) {
    final orchestratorEvent = event.effect;

    switch (orchestratorEvent) {
      case PendingUploadQueued(:final pendingId):
        emit(_reduceQueued(state, pendingId));
        return;
      case PendingUploadActive(:final pendingId):
        emit(_reduceActive(state, pendingId));
        return;
      case PendingUploadProgress(:final pendingId, :final progress):
        emit(_reduceProgress(state, pendingId, progress));
        return;
      case PendingUploadSucceeded(:final pendingId, :final appointmentIdEmr):
        emit(
          _reduceSuccess(state, pendingId, appointmentIdEmr: appointmentIdEmr),
        );
        return;
      case PendingUploadFailed(
          :final pendingId,
          :final error,
          :final appointmentIdEmr,
        ):
        emit(
          _reduceFailure(
            state,
            pendingId,
            error: error,
            appointmentIdEmr: appointmentIdEmr,
          ),
        );
        return;
      case PendingUploadCleared(:final pendingId):
        emit(_reduceCleared(state, pendingId));
        return;
    }
  }

  PendingUploadState _reduceQueued(PendingUploadState current, String id) {
    final next = Map<String, PendingUploadItem>.from(current.items);
    next[id] = (next[id] ?? const PendingUploadItem()).copyWith(
      status: PendingUploadStatus.queued,
    );
    return PendingUploadInitial(uiState: current.uiState.copyWith(items: next));
  }

  PendingUploadState _reduceActive(PendingUploadState current, String id) {
    final next = Map<String, PendingUploadItem>.from(current.items);
    next[id] = (next[id] ?? const PendingUploadItem()).copyWith(
      status: PendingUploadStatus.uploading,
      progress: 0.0,
      updatedAt: DateTime.now(),
    );

    return PendingUploadInitial(
      uiState: current.uiState.copyWith(
        items: next,
        activeUploadId: id,
        activeProgress: 0.0,
      ),
    );
  }

  PendingUploadState _reduceProgress(
    PendingUploadState current,
    String id,
    double value,
  ) {
    final next = Map<String, PendingUploadItem>.from(current.items);
    final clamped = value.clamp(0.0, 1.0);
    final isActive = current.activeUploadId == id;

    next[id] = (next[id] ?? const PendingUploadItem()).copyWith(
      status: PendingUploadStatus.uploading,
      progress: clamped,
      updatedAt: DateTime.now(),
    );

    return PendingUploadInitial(
      uiState: current.uiState.copyWith(
        items: next,
        activeUploadId: isActive ? id : current.activeUploadId,
        activeProgress: isActive ? clamped : current.activeProgress,
      ),
    );
  }

  PendingUploadState _reduceSuccess(
    PendingUploadState current,
    String id, {
    required String appointmentIdEmr,
  }) {
    final isActive = current.activeUploadId == id;
    final next = Map<String, PendingUploadItem>.from(current.items)..remove(id);

    return PendingUploadInitial(
      uiState: current.uiState.copyWith(
        items: next,
        activeUploadId: isActive ? null : current.activeUploadId,
        activeProgress: isActive ? 0.0 : current.activeProgress,
        lastResult: PendingUploadResult(
          pendingId: id,
          appointmentIdEmr: appointmentIdEmr,
          success: true,
          at: DateTime.now(),
        ),
      ),
    );
  }

  PendingUploadState _reduceFailure(
    PendingUploadState current,
    String id, {
    required Object error,
    String? appointmentIdEmr,
  }) {
    final isActive = current.activeUploadId == id;
    final next = Map<String, PendingUploadItem>.from(current.items);

    next[id] = (next[id] ?? const PendingUploadItem()).copyWith(
      status: PendingUploadStatus.failure,
      error: error.toString(),
      updatedAt: DateTime.now(),
    );

    return PendingUploadInitial(
      uiState: current.uiState.copyWith(
        items: next,
        activeUploadId: isActive ? null : current.activeUploadId,
        activeProgress: isActive ? 0.0 : current.activeProgress,
        lastResult: appointmentIdEmr == null
            ? current.lastResult
            : PendingUploadResult(
                pendingId: id,
                appointmentIdEmr: appointmentIdEmr,
                success: false,
                at: DateTime.now(),
              ),
      ),
    );
  }

  PendingUploadState _reduceCleared(PendingUploadState current, String id) {
    final next = Map<String, PendingUploadItem>.from(current.items)..remove(id);
    return PendingUploadInitial(uiState: current.uiState.copyWith(items: next));
  }
}
