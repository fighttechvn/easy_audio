import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecase/record_usecase.dart';

part 'language_event.dart';
part 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc(this._recordUsecase) : super(const LanguageInitial()) {
    on<LoadSupportedLanguagesEvent>(_onLoadSupportedLanguages);
    on<PrepareLanguageModelEvent>(_onPrepareLanguageModel);
    on<ResetLanguageEvent>(_onReset);
  }

  final RecordUsecase _recordUsecase;

  Future<void> _onLoadSupportedLanguages(
    LoadSupportedLanguagesEvent event,
    Emitter<LanguageState> emit,
  ) async {
    try {
      emit(LanguageLoading(state.stateUI));

      final result = await _recordUsecase.loadSupportedLanguages(
        currentLocale: event.currentLocale,
      );

      emit(
        LanguageLoaded(
          state.stateUI.copyWith(
            currentLocale: result.locale,
            currentLanguageLabel: result.label,
          ),
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[LanguageBloc] Failed to load supported languages: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      emit(LanguageLoadError(
        state.stateUI,
        'Failed to load supported languages',
        error,
      ));
    }
  }

  Future<void> _onPrepareLanguageModel(
    PrepareLanguageModelEvent event,
    Emitter<LanguageState> emit,
  ) async {
    if (state is LanguageModelPreparing) {
      // Already preparing, ignore duplicate requests
      return;
    }

    try {
      emit(LanguageModelPreparing(state.stateUI));

      final result = await _recordUsecase.prepareLanguageModel(event.locale);

      emit(
        LanguageModelPrepared(
          state.stateUI.copyWith(
            currentLocale: result.locale,
            currentLanguageLabel: result.label,
          ),
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[LanguageBloc] Failed to prepare language model: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      emit(LanguageModelError(
        state.stateUI,
        'Failed to prepare language model',
        error,
      ));
    }
  }

  void _onReset(
    ResetLanguageEvent event,
    Emitter<LanguageState> emit,
  ) {
    emit(const LanguageInitial());
  }
}
