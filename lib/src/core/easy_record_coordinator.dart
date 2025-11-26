import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text_record/speech_to_text_record.dart';

import '../core/services/record_modal_service.dart';
import '../domain/entities/easy_record_configuration.dart';
import '../domain/entities/record_data.dart';
import '../domain/usecase/record_usecase.dart';
import '../presentation/language_selection/bloc/language_bloc.dart';
import 'dialog_coodinator.dart';

extension EasyRecordCoordinator on BuildContext {
  Future<RecordData?> startRecordWithLanguageSelection({
    EasyRecordConfiguration? config,
    String? defaultLocale,
    bool prepareLanguageModel = true,
  }) async {
    // Select language
    final selectedLocale = await startSelectLanguague(
      langDefault: defaultLocale ?? config?.defaultLocale ?? 'en-US',
    );

    if (selectedLocale == null || selectedLocale.isEmpty) {
      return null;
    }

    // Prepare language model if needed
    if (prepareLanguageModel) {
      try {
        final recordUsecase = RecordUsecase();
        await recordUsecase.prepareLanguageModel(selectedLocale);
      } catch (e, stackTrace) {
        debugPrint('[EasyRecordCoordinator] Failed to prepare language: $e');
        config?.onError?.call(e, stackTrace);
        // Continue anyway - speech might still work
      }
    }

    // Start recording
    return startEasyRecord(
      locale: selectedLocale,
      config: config,
    );
  }

  Future<RecordData?> startEasyRecord({
    required String locale,
    EasyRecordConfiguration? config,
    bool restoreFromSession = false,
  }) async {
    final effectiveConfig = (config ?? const EasyRecordConfiguration())
        .copyWith(defaultLocale: locale);

    return EasyRecordModalService.instance.openModal(
      context: this,
      config: effectiveConfig,
      restoreFromSession: restoreFromSession,
    );
  }

  /// Checks if there's an active recording session.
  bool get hasActiveRecordingSession {
    try {
      // Access through bloc if available
      final bloc = read<LanguageBloc>();
      return bloc.state is LanguageModelPrepared ||
          bloc.state is LanguageModelPreparing;
    } catch (_) {
      return EasyRecordModalService.instance.hasOpenModal;
    }
  }

  /// Gets the current language state if LanguageBloc is available.
  LanguageStateUI? get currentLanguageState {
    try {
      return read<LanguageBloc>().state.stateUI;
    } catch (_) {
      return null;
    }
  }

  Future<void> prepareLanguageModel(String locale) async {
    try {
      final bloc = read<LanguageBloc>();
      bloc.add(PrepareLanguageModelEvent(locale: locale));
    } catch (_) {
      // No bloc available, use usecase directly
      final recordUsecase = RecordUsecase();
      await recordUsecase.prepareLanguageModel(locale);
    }
  }

  Future<String> loadSupportedLanguages({
    String currentLocale = 'en-US',
  }) async {
    try {
      final bloc = read<LanguageBloc>();
      bloc.add(LoadSupportedLanguagesEvent(currentLocale: currentLocale));
      return currentLocale;
    } catch (_) {
      // No bloc available, use usecase directly
      final recordUsecase = RecordUsecase();
      final result = await recordUsecase.loadSupportedLanguages(
        currentLocale: currentLocale,
      );
      return result.locale;
    }
  }
}

extension EasyRecordLanguages on BuildContext {
  Map<String, String> get supportedRecordLanguages => RecordLanguage.supported;

  String? labelForLocale(String locale) {
    return RecordLanguage.languageLabelForLocale(locale);
  }

  String? localeForLabel(String label) {
    return RecordLanguage.supported[label];
  }
}
