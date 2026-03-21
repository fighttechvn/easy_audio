import 'dart:async';

import 'package:easy_audio/easy_audio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/home_data.dart';
import '../../../../domain/usecases/easy_audio_usecase.dart';
import 'recording_event.dart';
import 'recording_state.dart';

export 'recording_event.dart';
export 'recording_state.dart';

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  RecordingBloc({required EasyAudioUseCase useCase})
    : _useCase = useCase,
      super(RecordingIdleState(ui: RecordingStateUi.initial())) {
    on<RecordingTogglePressed>(_onTogglePressed);
    on<RecordingPausePressed>(_onPausePressed);
    on<RecordingCancelPressed>(_onCancelPressed);
    on<RecordingAudioStateChanged>(_onAudioStateChanged);
    on<RecordingTranscriptReceived>(_onTranscriptReceived);
    on<RecordingAmplitudeChanged>(_onAmplitudeChanged);
    on<RecordingAdded>(_onRecordingAdded);
  }

  final EasyAudioUseCase _useCase;

  StreamSubscription<EasyAudioState>? _stateSubscription;
  StreamSubscription<TranscriptResult>? _transcriptSubscription;
  StreamSubscription<double>? _amplitudeSubscription;

  /// Setup subscriptions - called after EasyAudio is initialized
  Future<void> setupSubscriptions() async {
    await _stateSubscription?.cancel();
    _stateSubscription = _useCase.stateStream.listen(
      (audioState) => add(RecordingAudioStateChanged(audioState)),
    );

    await _transcriptSubscription?.cancel();
    _transcriptSubscription = _useCase.transcriptStream.listen(
      (result) => add(RecordingTranscriptReceived(result)),
    );

    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _useCase.amplitudeStream.listen(
      (amp) => add(RecordingAmplitudeChanged(amp)),
    );
  }

  Future<void> _onTogglePressed(
    RecordingTogglePressed event,
    Emitter<RecordingState> emit,
  ) async {
    final audioState = state.ui.audioState;

    switch (audioState) {
      case EasyAudioState.recording:
        await _stopRecording(emit);
      case EasyAudioState.paused:
        await _resumeRecording(emit);
      case EasyAudioState.idle:
        await _startRecording(emit);
      case EasyAudioState.initializing:
      case EasyAudioState.processing:
      case EasyAudioState.error:
        break;
    }
  }

  Future<void> _startRecording(Emitter<RecordingState> emit) async {
    emit(
      RecordingLoadingState(
        ui: state.ui.copyWith(transcript: '', liveTranscript: ''),
        operation: RecordingOperation.starting,
      ),
    );

    try {
      await _useCase.start();
      emit(RecordingActiveState(ui: state.ui));
    } catch (e) {
      _emitError(emit, 'Error starting recording: $e', HomeErrorType.start);
    }
  }

  Future<void> _stopRecording(Emitter<RecordingState> emit) async {
    emit(
      RecordingLoadingState(
        ui: state.ui,
        operation: RecordingOperation.stopping,
      ),
    );

    try {
      final result = await _useCase.stop();
      emit(
        RecordingIdleState(
          ui: state.ui.copyWith(
            recordings: [result, ...state.ui.recordings],
            transcript: '',
            liveTranscript: '',
          ),
        ),
      );
    } catch (e) {
      _emitError(emit, 'Error stopping recording: $e', HomeErrorType.stop);
    }
  }

  Future<void> _resumeRecording(Emitter<RecordingState> emit) async {
    emit(
      RecordingLoadingState(
        ui: state.ui,
        operation: RecordingOperation.resuming,
      ),
    );

    try {
      await _useCase.resume();
      emit(RecordingActiveState(ui: state.ui));
    } catch (e) {
      _emitError(emit, 'Error resuming recording: $e', HomeErrorType.resume);
    }
  }

  Future<void> _onPausePressed(
    RecordingPausePressed event,
    Emitter<RecordingState> emit,
  ) async {
    if (state.ui.audioState != EasyAudioState.recording) {
      return;
    }

    emit(
      RecordingLoadingState(
        ui: state.ui,
        operation: RecordingOperation.pausing,
      ),
    );

    try {
      await _useCase.pause();
      emit(RecordingActiveState(ui: state.ui));
    } catch (e) {
      _emitError(emit, 'Error pausing recording: $e', HomeErrorType.pause);
    }
  }

  Future<void> _onCancelPressed(
    RecordingCancelPressed event,
    Emitter<RecordingState> emit,
  ) async {
    emit(
      RecordingLoadingState(
        ui: state.ui,
        operation: RecordingOperation.canceling,
      ),
    );

    try {
      await _useCase.cancel();
      emit(
        RecordingIdleState(
          ui: state.ui.copyWith(transcript: '', liveTranscript: ''),
        ),
      );
    } catch (e) {
      _emitError(emit, 'Error canceling recording: $e', HomeErrorType.cancel);
    }
  }

  void _onAudioStateChanged(
    RecordingAudioStateChanged event,
    Emitter<RecordingState> emit,
  ) {
    emit(state.withUi(state.ui.copyWith(audioState: event.state)));
  }

  void _onTranscriptReceived(
    RecordingTranscriptReceived event,
    Emitter<RecordingState> emit,
  ) {
    final result = event.result;
    final newLiveTranscript = result.text;
    var newTranscript = state.ui.transcript;

    if (result.isFinal && result.text.isNotEmpty) {
      newTranscript += (newTranscript.isEmpty ? '' : ' ') + result.text;
    }

    emit(
      state.withUi(
        state.ui.copyWith(
          liveTranscript: newLiveTranscript,
          transcript: newTranscript,
        ),
      ),
    );
  }

  void _onAmplitudeChanged(
    RecordingAmplitudeChanged event,
    Emitter<RecordingState> emit,
  ) {
    emit(state.withUi(state.ui.copyWith(amplitude: event.amplitude)));
  }

  void _onRecordingAdded(RecordingAdded event, Emitter<RecordingState> emit) {
    emit(
      RecordingIdleState(
        ui: state.ui.copyWith(
          recordings: [event.recording, ...state.ui.recordings],
        ),
      ),
    );
  }

  void _emitError(
    Emitter<RecordingState> emit,
    String message,
    HomeErrorType type,
  ) {
    emit(
      RecordingErrorState(
        ui: state.ui,
        message: message,
        errorType: type,
        snackBarMessage: HomeSnackBarMessage(
          text: message,
          type: HomeSnackBarType.error,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _stateSubscription?.cancel();
    await _transcriptSubscription?.cancel();
    await _amplitudeSubscription?.cancel();
    return super.close();
  }
}
