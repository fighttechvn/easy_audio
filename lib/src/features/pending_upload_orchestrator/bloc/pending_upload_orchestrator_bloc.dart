import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/entities/pending_upload_flow.dart';
import '../../../domain/entities/upload_recoding_process_callback.dart';
import '../../../domain/entities/upload_retry_policy.dart';
import '../../../domain/usecases/pending_upload_usecase.dart';
import '../entities/pending_upload_orchestrator_effect.dart';
import '../entities/pending_upload_orchestrator_ui_state.dart';

part 'pending_upload_orchestrator_event.dart';
part 'pending_upload_orchestrator_state.dart';

@lazySingleton
class PendingUploadOrchestratorBloc extends Bloc<
    PendingUploadOrchestratorBlocEvent, PendingUploadOrchestratorState> {
  PendingUploadOrchestratorBloc(this._pendingUploadUsecase)
      : super(
          const PendingUploadOrchestratorInitial(
            uiState: PendingUploadOrchestratorUiState(),
          ),
        ) {
    on<PendingUploadOrchestratorEnqueueRequested>(_onEnqueueRequested);
    on<PendingUploadOrchestratorEnqueueManyRequested>(_onEnqueueManyRequested);
    on<PendingUploadOrchestratorEnqueueAllPendingForUserRequested>(
      _onEnqueueAllPendingForUserRequested,
    );
    on<PendingUploadOrchestratorRetryRequested>(_onRetryRequested);

    on<_PendingUploadOrchestratorEffectRaised>(_onEffectRaised);
    on<_PendingUploadOrchestratorSnapshotRequested>(_onSnapshotRequested);
    on<PendingUploadOrchestratorRetryPolicyUpdateRequested>(
      _onRetryPolicyUpdateRequested,
    );
  }

  final PendingUploadUsecase _pendingUploadUsecase;
  UploadRecordingProgressCallback? _uploadRecordingProgress;

  final Set<String> _queue = <String>{};
  bool _pumping = false;

  // ignore: use_setters_to_change_properties
  void setUploadRecordingProgressCallback(
    UploadRecordingProgressCallback callback,
  ) {
    _uploadRecordingProgress = callback;
  }

  Future<void> enqueue(String id) {
    final completer = Completer<void>();
    add(
      PendingUploadOrchestratorEnqueueRequested(id: id, completer: completer),
    );
    return completer.future;
  }

  Future<void> enqueueMany(Iterable<String> ids) {
    final completer = Completer<void>();
    add(
      PendingUploadOrchestratorEnqueueManyRequested(
        ids: ids,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> enqueueAllPendingForUser(int? userId) {
    final completer = Completer<void>();
    add(
      PendingUploadOrchestratorEnqueueAllPendingForUserRequested(
        userId: userId,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> retry(String id) {
    final completer = Completer<void>();
    add(PendingUploadOrchestratorRetryRequested(id: id, completer: completer));
    return completer.future;
  }

  void _onEnqueueRequested(
    PendingUploadOrchestratorEnqueueRequested event,
    Emitter<PendingUploadOrchestratorState> emit,
  ) {
    _queue.add(event.id);
    _emitEffect(emit, PendingUploadQueued(event.id));
    _startPumpIfNeeded();
    event.completer?.complete();
  }

  void _onEnqueueManyRequested(
    PendingUploadOrchestratorEnqueueManyRequested event,
    Emitter<PendingUploadOrchestratorState> emit,
  ) {
    for (final id in event.ids) {
      _queue.add(id);
      _emitEffect(emit, PendingUploadQueued(id));
    }
    _startPumpIfNeeded();
    event.completer?.complete();
  }

  Future<void> _onEnqueueAllPendingForUserRequested(
    PendingUploadOrchestratorEnqueueAllPendingForUserRequested event,
    Emitter<PendingUploadOrchestratorState> emit,
  ) async {
    try {
      final ids = await _pendingUploadUsecase.listUploadCandidateIdsForUser(
        event.userId,
      );
      for (final id in ids) {
        _queue.add(id);
        _emitEffect(emit, PendingUploadQueued(id));
      }
      _startPumpIfNeeded();
      event.completer?.complete();
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
      event.completer?.completeError(e, trace);
    }
  }

  void _onRetryRequested(
    PendingUploadOrchestratorRetryRequested event,
    Emitter<PendingUploadOrchestratorState> emit,
  ) {
    _queue.add(event.id);
    _emitEffect(emit, PendingUploadQueued(event.id));
    _startPumpIfNeeded();
    event.completer?.complete();
  }

  void _onEffectRaised(
    _PendingUploadOrchestratorEffectRaised event,
    Emitter<PendingUploadOrchestratorState> emit,
  ) {
    _emitEffect(emit, event.effect);
  }

  void _onSnapshotRequested(
    _PendingUploadOrchestratorSnapshotRequested event,
    Emitter<PendingUploadOrchestratorState> emit,
  ) {
    _emitSnapshot(emit);
  }

  void _onRetryPolicyUpdateRequested(
    PendingUploadOrchestratorRetryPolicyUpdateRequested event,
    Emitter<PendingUploadOrchestratorState> emit,
  ) {
    try {
      emit(
        PendingUploadOrchestratorInitial(
          uiState: state.uiState.copyWith(
            retryPolicy: event.retryPolicy,
            queue: Set<String>.unmodifiable(_queue),
            isPumping: _pumping,
          ),
        ),
      );
      event.completer?.complete();
    } catch (e, trace) {
      event.completer?.completeError(e, trace);
    }
  }

  void _emitEffect(
    Emitter<PendingUploadOrchestratorState> emit,
    PendingUploadOrchestratorEffect effect,
  ) {
    emit(
      PendingUploadOrchestratorInitial(
        uiState: state.uiState.copyWith(
          queue: Set<String>.unmodifiable(_queue),
          isPumping: _pumping,
          retryPolicy: state.uiState.retryPolicy,
          effect: effect,
          effectId: state.uiState.effectId + 1,
        ),
      ),
    );
  }

  void _emitSnapshot(Emitter<PendingUploadOrchestratorState> emit) {
    emit(
      PendingUploadOrchestratorInitial(
        uiState: state.uiState.copyWith(
          queue: Set<String>.unmodifiable(_queue),
          isPumping: _pumping,
          retryPolicy: state.uiState.retryPolicy,
        ),
      ),
    );
  }

  void _safeAddEffect(PendingUploadOrchestratorEffect effect) {
    if (isClosed) {
      return;
    }

    try {
      add(_PendingUploadOrchestratorEffectRaised(effect));
    } catch (_) {
      // Ignore events emitted after close.
    }
  }

  void _safeAddSnapshot() {
    if (isClosed) {
      return;
    }

    try {
      add(const _PendingUploadOrchestratorSnapshotRequested());
    } catch (_) {
      // Ignore events emitted after close.
    }
  }

  void _startPumpIfNeeded() {
    if (_pumping || isClosed) {
      return;
    }

    _pumping = true;
    _safeAddSnapshot();
    unawaited(_pump());
  }

  Future<void> _pump() async {
    try {
      while (!isClosed) {
        while (_queue.isNotEmpty) {
          final id = _queue.first;
          _queue.remove(id);

          try {
            await _processOne(id);
          } catch (e, trace) {
            if (kDebugMode) {
              print(e);
              print(trace);
            }

            _safeAddEffect(PendingUploadFailed(pendingId: id, error: e));
          }
        }

        await Future<void>.delayed(Duration.zero);
        if (_queue.isEmpty) {
          break;
        }
      }
    } finally {
      _pumping = false;
      _safeAddSnapshot();
    }
  }

  Future<void> _processOne(String id) async {
    final start = await _pendingUploadUsecase.tryStartUpload(id);

    switch (start.status) {
      case PendingUploadStartStatus.notFound:
        _safeAddEffect(PendingUploadCleared(id));
        return;
      case PendingUploadStartStatus.alreadyUploading:
        return;
      case PendingUploadStartStatus.fileMissing:
        _safeAddEffect(
          PendingUploadFailed(
            pendingId: id,
            error: start.error ?? StateError('File not found'),
            appointmentIdEmr: start.appointmentIdEmr,
          ),
        );
        return;
      case PendingUploadStartStatus.ok:
        break;
    }

    _safeAddEffect(PendingUploadActive(id));
    if (_uploadRecordingProgress == null) {
      throw StateError('UploadRecordingProgressCallback is not set');
    }

    final result = await _pendingUploadUsecase.runUploadRetries(
      id: id,
      retryPolicy: state.uiState.retryPolicy,
      onProgress: (p) {
        _safeAddEffect(PendingUploadProgress(id, p));
      },
      uploadRecordingProgress: _uploadRecordingProgress!,
    );

    switch (result.status) {
      case PendingUploadRunStatus.notFound:
        _safeAddEffect(PendingUploadCleared(id));
        return;
      case PendingUploadRunStatus.success:
        _safeAddEffect(
          PendingUploadSucceeded(
            pendingId: id,
            appointmentIdEmr: result.appointmentIdEmr!,
          ),
        );
        return;
      case PendingUploadRunStatus.failure:
        _safeAddEffect(
          PendingUploadFailed(
            pendingId: id,
            error: result.error ?? 'Unknown error',
            appointmentIdEmr: result.appointmentIdEmr,
          ),
        );
        return;
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    await close();
  }
}
