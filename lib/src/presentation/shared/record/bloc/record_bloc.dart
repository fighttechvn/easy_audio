import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/easy_audio_controller.dart';
import '../../../../domain/usecase/record_usecase.dart';
import '../entities/record_state_ui.dart';

part 'record_event.dart';
part 'record_state.dart';

class RecordBloc<T, A> extends Bloc<RecordEvent, RecordState<T, A>> {
  final RecordUsecase _recordUsecase;

  /// Listener callback for audio controller
  VoidCallback? _audioListener;

  RecordBloc(
    this._recordUsecase,
  ) : super(RecordInitial<T, A>(RecordStateUI<T, A>())) {
    // Language events
    on<RecordLoadSupportedLanguagesEvent>(_onLoadSupportedLanguages);
    on<RecordPrepareLanguageModelEvent>(_onPrepareLanguageModel);
    on<RecordResetStateEvent>(_onResetState);

    // Audio player events
    on<InitAudioPlayerEvent>(_onInitAudioPlayer);
    on<DisposeAudioPlayerEvent>(_onDisposeAudioPlayer);
    on<PlayAudioEvent>(_onPlayAudio);
    on<StopAudioEvent>(_onStopAudio);
    on<AudioStateChangedEvent>(_onAudioStateChanged);

    // Recording events
    on<RecordingAudioEvent>(_onRecordingAudioEvent);
    on<RecordAudioDoneEvent>(_onRecordAudioDone);

    // Audio list events
    on<AddAudioItemEvent<A>>(_onAddAudioItem);
    on<MergeAudioItemsEvent<A>>(_onMergeAudioItems);
    on<ClearAudioListEvent>(_onClearAudioList);
  }

  /// Expose audio controller for widgets that need direct access (e.g., AudioRecordWidget)
  EasyAudioController get audioController => _recordUsecase.audioController;

  // ============ Audio Player Handlers ============

  Future<void> _onInitAudioPlayer(
    InitAudioPlayerEvent event,
    Emitter<RecordState<T, A>> emit,
  ) async {
    if (state.stateUI.isAudioPlayerInited) {
      return;
    }

    await _recordUsecase.initPlayer(disposeWhenParentDispose: false);

    // Add listener to sync audio state
    _audioListener = () {
      add(
        AudioStateChangedEvent(
          isPlaying: _recordUsecase.isPlaying,
          isOpenPlayer: _recordUsecase.isOpenPlayer,
          currentPlayingUrl: _recordUsecase.currentPlayingUrl,
        ),
      );
    };
    _recordUsecase.addAudioListener(_audioListener!);

    emit(
      AudioPlayerInitedState(
        state.stateUI.copyWith(isAudioPlayerInited: true),
      ),
    );
  }

  FutureOr<void> _onDisposeAudioPlayer(
    DisposeAudioPlayerEvent event,
    Emitter<RecordState<T, A>> emit,
  ) {
    if (_audioListener != null) {
      _recordUsecase.removeAudioListener(_audioListener!);
      _audioListener = null;
    }
    _recordUsecase.disposeAudioController();

    emit(
      RecordLoaded(
        state.stateUI.copyWith(
          isAudioPlayerInited: false,
          isPlaying: false,
          isOpenPlayer: false,
          currentPlayingUrl: null,
        ),
      ),
    );
  }

  Future<void> _onPlayAudio(
    PlayAudioEvent event,
    Emitter<RecordState<T, A>> emit,
  ) async {
    final url = event.url ?? '';
    await _recordUsecase.playAudio(url);
  }

  Future<void> _onStopAudio(
    StopAudioEvent event,
    Emitter<RecordState<T, A>> emit,
  ) async {
    await _recordUsecase.stopPlayer();
  }

  FutureOr<void> _onAudioStateChanged(
    AudioStateChangedEvent event,
    Emitter<RecordState<T, A>> emit,
  ) {
    emit(
      AudioStateUpdated(
        state.stateUI.updateAudioState(
          isPlaying: event.isPlaying,
          isOpenPlayer: event.isOpenPlayer,
          currentPlayingUrl: event.currentPlayingUrl,
        ),
      ),
    );
  }

  // ============ Language Handlers ============

  Future<void> _onLoadSupportedLanguages(
    RecordLoadSupportedLanguagesEvent event,
    Emitter<RecordState<T, A>> emit,
  ) async {
    try {
      emit(RecordLoadingLanguageModel(state.stateUI));

      final result = await _recordUsecase.loadSupportedLanguages(
        currentLocale: event.currentLocale,
      );
      emit(
        RecordLoaded(
          state.stateUI.copyWith(
            currentLocale: result.locale,
            currentLanguageLabel: result.label,
            recordAfterLoaded: event.recordAfterLoaded,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to load supported languages: $error');
      debugPrintStack(stackTrace: stackTrace);
      emit(
        RecordAudioError(
          state.stateUI,
          'Failed to load supported languages',
          error,
        ),
      );
    }
  }

  FutureOr<void> _onResetState(
    RecordResetStateEvent event,
    Emitter<RecordState<T, A>> emit,
  ) {
    emit(RecordLoaded(state.stateUI.resetRecordAfterLoaded()));
  }

  Future<void> _onPrepareLanguageModel(
    RecordPrepareLanguageModelEvent event,
    Emitter<RecordState<T, A>> emit,
  ) async {
    if (state is PrepareLanguageModelLoading) {
      return;
    }

    try {
      emit(PrepareLanguageModelLoading(state.stateUI));
      final result = await _recordUsecase.prepareLanguageModel(event.locale);
      emit(
        PrepareLanguageModelLoaded(
          state.stateUI.copyWith(
            currentLocale: result.locale,
            currentLanguageLabel: result.label,
          ),
        ),
      );
    } catch (error, stackTrace) {
      emit(
        PrepareLanguageModelError(
          state.stateUI,
          'Failed to prepare language model',
          error,
        ),
      );
      debugPrint('Failed to prepare language model: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============ Recording Handlers ============

  FutureOr<void> _onRecordingAudioEvent(
    RecordingAudioEvent event,
    Emitter<RecordState<T, A>> emit,
  ) {
    emit(RecordingAudio(state.stateUI));
  }

  FutureOr<void> _onRecordAudioDone(
    RecordAudioDoneEvent event,
    Emitter<RecordState<T, A>> emit,
  ) {
    emit(RecordAudioDone(state.stateUI));
  }

  // ============ Audio List Handlers ============

  FutureOr<void> _onAddAudioItem(
    AddAudioItemEvent<A> event,
    Emitter<RecordState<T, A>> emit,
  ) {
    final currentStateUI = state.stateUI;
    final newAudioList = [...currentStateUI.audioList, event.item];
    emit(AudioListUpdated(currentStateUI.copyWith(audioList: newAudioList)));
  }

  FutureOr<void> _onMergeAudioItems(
    MergeAudioItemsEvent<A> event,
    Emitter<RecordState<T, A>> emit,
  ) {
    final newStateUI = state.stateUI.mergeAudioItems(
      event.items,
      isDuplicate: event.isDuplicate,
    );
    emit(AudioListUpdated<T, A>(newStateUI));
  }

  FutureOr<void> _onClearAudioList(
    ClearAudioListEvent event,
    Emitter<RecordState<T, A>> emit,
  ) {
    emit(AudioListUpdated(state.stateUI.clearAudioList()));
  }

  @override
  Future<void> close() {
    // Clean up listener when bloc is closed
    if (_audioListener != null) {
      _recordUsecase.removeAudioListener(_audioListener!);
      _audioListener = null;
    }
    return super.close();
  }
}
