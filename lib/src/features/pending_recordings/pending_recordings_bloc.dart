import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/pending_recordings_usecase.dart';
import 'ui_state/pending_recordings_ui_state.dart';

part 'pending_recordings_event.dart';
part 'pending_recordings_state.dart';

@injectable
class PendingRecordingsBloc
    extends Bloc<PendingRecordingsEvent, PendingRecordingsState> {
  PendingRecordingsBloc(this._usecase)
    : super(
        const PendingRecordingsInitial(uiState: PendingRecordingsUiState()),
      ) {
    on<PendingRecordingsInitRequested>(_onInit);
    on<PendingRecordingsRefreshRequested>(_onRefresh);
    on<PendingRecordingsDeleteRequested>(_onDeleteById);
  }

  final PendingRecordingsUsecase _usecase;

  Future<void> _onInit(
    PendingRecordingsInitRequested event,
    Emitter<PendingRecordingsState> emit,
  ) async {
    try {
      emit(PendingRecordingsLoading(uiState: state.uiState));

      await _usecase.init();
      await _usecase.refreshFileSizes();

      final items = _usecase.listForUser(null);
      emit(
        PendingRecordingsReady(uiState: state.uiState.copyWith(items: items)),
      );
      event.completer?.complete();
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
      emit(PendingRecordingsFailure(uiState: state.uiState, error: e));
      event.completer?.completeError(e, trace);
    }
  }

  void _onRefresh(
    PendingRecordingsRefreshRequested event,
    Emitter<PendingRecordingsState> emit,
  ) {
    try {
      final items = _usecase.listForUser(null);
      emit(
        PendingRecordingsReady(uiState: state.uiState.copyWith(items: items)),
      );
      event.completer?.complete();
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
      emit(PendingRecordingsFailure(uiState: state.uiState, error: e));
      event.completer?.completeError(e, trace);
    }
  }

  Future<void> _onDeleteById(
    PendingRecordingsDeleteRequested event,
    Emitter<PendingRecordingsState> emit,
  ) async {
    try {
      await _usecase.deleteById(event.id, deleteFile: event.deleteFile);
      final items = _usecase.listForUser(null);
      emit(
        PendingRecordingsReady(uiState: state.uiState.copyWith(items: items)),
      );
      event.completer?.complete();
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
      emit(PendingRecordingsFailure(uiState: state.uiState, error: e));
      event.completer?.completeError(e, trace);
    }
  }
}
