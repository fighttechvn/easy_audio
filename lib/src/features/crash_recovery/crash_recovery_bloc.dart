import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/pending_recording.dart';
import '../../domain/usecases/pending_recordings_usecase.dart';
import '../../domain/usecases/recording/crash_recovery_usecase.dart';
import '../pending_upload/pending_upload_bloc.dart';
import 'ui_state/crash_recovery_effect.dart';
import 'ui_state/crash_recovery_ui_state.dart';

export 'ui_state/crash_recovery_effect.dart';

part 'crash_recovery_event.dart';
part 'crash_recovery_state.dart';

@lazySingleton
class CrashRecoveryBloc extends Bloc<CrashRecoveryEvent, CrashRecoveryState> {
  CrashRecoveryBloc(
    this._crashRecoveryUsecase,
    this._pendingRecordingsUsecase,
    this._pendingUploadCubit,
  ) : super(const CrashRecoveryInitial(uiState: CrashRecoveryUiState())) {
    on<CrashRecoveryRunLoginRequested>(_onRunLoginCrashRecovery);
    on<CrashRecoveryDiscardRequested>(_onDiscard);
    on<CrashRecoveryUploadRequested>(_onUpload);
  }

  final CrashRecoveryUsecase _crashRecoveryUsecase;
  final PendingRecordingsUsecase _pendingRecordingsUsecase;
  final PendingUploadBloc _pendingUploadCubit;

  bool _inFlight = false;

  Future<void> _onRunLoginCrashRecovery(
    CrashRecoveryRunLoginRequested event,
    Emitter<CrashRecoveryState> emit,
  ) async {
    if (_inFlight) {
      event.completer?.complete();
      return;
    }

    _inFlight = true;
    emit(
      CrashRecoveryInitial(uiState: state.uiState.copyWith(isRunning: true)),
    );

    try {
      final unfinished = await _crashRecoveryUsecase.runLoginCrashRecovery(
        userId: event.userId,
        fallbackLocale: event.fallbackLocale,
      );

      if (unfinished != null) {
        _emitEffect(
          emit,
          CrashRecoveryEffect.showUnfinishedRecording(
            record: unfinished.record,
            languageDisplayName: unfinished.languageDisplayName,
          ),
        );
      }

      event.completer?.complete();
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
      event.completer?.completeError(e, trace);
    } finally {
      _inFlight = false;
      emit(
        CrashRecoveryInitial(uiState: state.uiState.copyWith(isRunning: false)),
      );
    }
  }

  Future<void> _onDiscard(
    CrashRecoveryDiscardRequested event,
    Emitter<CrashRecoveryState> emit,
  ) async {
    try {
      await _pendingRecordingsUsecase.deleteById(
        event.pendingId,
        deleteFile: event.deleteFile,
      );
      event.completer?.complete();
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
      event.completer?.completeError(e, trace);
    }
  }

  Future<void> _onUpload(
    CrashRecoveryUploadRequested event,
    Emitter<CrashRecoveryState> emit,
  ) async {
    try {
      final record = event.record;
      final appt = record.appointmentIdEmr.trim();
      if (appt.isEmpty || appt == 'recovered') {
        _emitEffect(
          emit,
          CrashRecoveryEffect.showToast(
            message: 'Recovered recording found, but missing appointment info.',
            type: RecordAudioToastType.warning,
          ),
        );
        event.completer?.complete();
        return;
      }

      await _pendingUploadCubit.enqueue(record.id);
      event.completer?.complete();
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
      event.completer?.completeError(e, trace);
    }
  }

  void _emitEffect(
    Emitter<CrashRecoveryState> emit,
    CrashRecoveryEffect effect,
  ) {
    emit(
      CrashRecoveryInitial(
        uiState: state.uiState.copyWith(
          effect: effect,
          effectId: state.uiState.effectId + 1,
        ),
      ),
    );
  }
}
