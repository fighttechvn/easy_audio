import 'package:easy_audio/easy_audio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/home_data.dart';
import '../../../../domain/usecases/easy_audio_usecase.dart';
import 'easy_audio_manage_event.dart';
import 'easy_audio_manage_state.dart';

export 'easy_audio_manage_event.dart';
export 'easy_audio_manage_state.dart';

class EasyAudioManageBloc
    extends Bloc<EasyAudioManageEvent, EasyAudioManageState> {
  EasyAudioManageBloc({required EasyAudioUseCase useCase})
    : _useCase = useCase,
      super(EasyAudioManageInitialState(ui: EasyAudioManageStateUi.initial())) {
    on<EasyAudioManageStarted>(_onStarted);
    on<EasyAudioManageModeSelected>(_onModeSelected);
    on<EasyAudioManageLocaleSelected>(_onLocaleSelected);
    on<EasyAudioManageLocalesRequested>(_onLocalesRequested);
    on<EasyAudioManageLocalesLoaded>(_onLocalesLoaded);
  }

  final EasyAudioUseCase _useCase;

  /// Callback when initialized - for RecordingBloc to setup subscriptions
  Function()? onInitialized;

  /// Callback when mode changed - for PlaybackBloc to stop playback
  Function()? onModeChanging;

  EasyAudioConfig _buildConfig({
    required EasyAudioMode mode,
    required String? locale,
  }) {
    return EasyAudioConfig(
      mode: mode,
      locale: locale,
      encoder: AudioEncoder.aacLc,
      enableCrashRecovery: true,
      enableBackgroundRecording: true,
    );
  }

  Future<void> _onStarted(
    EasyAudioManageStarted event,
    Emitter<EasyAudioManageState> emit,
  ) async {
    emit(EasyAudioManageInitializingState(ui: state.ui));

    try {
      await _useCase.initialize(
        _buildConfig(
          mode: state.ui.selectedMode,
          locale: state.ui.selectedLocale,
        ),
      );

      // Preload locales
      add(const EasyAudioManageLocalesRequested());

      // Notify RecordingBloc to setup subscriptions
      onInitialized?.call();

      // Try recover last recording
      final recovered = await _useCase.recoverLastRecording();

      emit(
        EasyAudioManageReadyState(
          ui: state.ui,
          recoveredRecording: recovered,
          snackBarMessage: recovered != null
              ? const HomeSnackBarMessage(
                  text: '🔄 Recovered recording from previous session!',
                  type: HomeSnackBarType.success,
                )
              : null,
        ),
      );
    } catch (e) {
      emit(
        EasyAudioManageErrorState(
          ui: state.ui,
          message: 'Failed to initialize: $e',
          errorType: HomeErrorType.initialization,
          snackBarMessage: HomeSnackBarMessage(
            text: 'Failed to initialize: $e',
            type: HomeSnackBarType.error,
          ),
        ),
      );
    }
  }

  Future<void> _onModeSelected(
    EasyAudioManageModeSelected event,
    Emitter<EasyAudioManageState> emit,
  ) async {
    // Notify PlaybackBloc to stop playback
    onModeChanging?.call();

    final nextUi = state.ui.copyWith(selectedMode: event.mode);

    emit(EasyAudioManageChangingModeState(ui: nextUi));

    try {
      await _useCase.updateConfig(
        _buildConfig(mode: event.mode, locale: state.ui.selectedLocale),
      );

      if (event.mode != EasyAudioMode.recordOnly) {
        add(const EasyAudioManageLocalesRequested());
      }

      emit(EasyAudioManageReadyState(ui: state.ui));
    } catch (e) {
      emit(
        EasyAudioManageErrorState(
          ui: state.ui,
          message: 'Failed to change mode: $e',
          errorType: HomeErrorType.modeChange,
          snackBarMessage: HomeSnackBarMessage(
            text: 'Failed to change mode: $e',
            type: HomeSnackBarType.error,
          ),
        ),
      );
    }
  }

  Future<void> _onLocaleSelected(
    EasyAudioManageLocaleSelected event,
    Emitter<EasyAudioManageState> emit,
  ) async {
    final nextUi = state.ui.copyWith(selectedLocale: event.locale);
    emit(EasyAudioManageChangingModeState(ui: nextUi));

    try {
      await _useCase.updateConfig(
        _buildConfig(mode: nextUi.selectedMode, locale: nextUi.selectedLocale),
      );

      emit(EasyAudioManageReadyState(ui: nextUi));
    } catch (e) {
      emit(
        EasyAudioManageErrorState(
          ui: state.ui,
          message: 'Failed to change language: $e',
          errorType: HomeErrorType.modeChange,
          snackBarMessage: HomeSnackBarMessage(
            text: 'Failed to change language: $e',
            type: HomeSnackBarType.error,
          ),
        ),
      );
    }
  }

  Future<void> _onLocalesRequested(
    EasyAudioManageLocalesRequested event,
    Emitter<EasyAudioManageState> emit,
  ) async {
    if (state.ui.isLocalesLoading) {
      return;
    }

    emit(
      EasyAudioManageReadyState(ui: state.ui.copyWith(isLocalesLoading: true)),
    );

    try {
      final locales = await _useCase.getSupportedLocales();
      add(EasyAudioManageLocalesLoaded(locales));
    } catch (e) {
      emit(
        EasyAudioManageReadyState(
          ui: state.ui.copyWith(isLocalesLoading: false),
          snackBarMessage: HomeSnackBarMessage(
            text: 'Failed to load languages: $e',
            type: HomeSnackBarType.error,
          ),
        ),
      );
    }
  }

  void _onLocalesLoaded(
    EasyAudioManageLocalesLoaded event,
    Emitter<EasyAudioManageState> emit,
  ) {
    emit(
      EasyAudioManageReadyState(
        ui: state.ui.copyWith(
          supportedLocales: event.locales,
          isLocalesLoading: false,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _useCase.dispose();
    return super.close();
  }
}
