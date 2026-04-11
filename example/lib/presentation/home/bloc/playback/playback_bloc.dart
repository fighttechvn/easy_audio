import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlaybackEvent;

import '../../../../domain/entities/home_data.dart';
import '../../../../domain/usecases/playback_usecase.dart';
import 'playback_event.dart';
import 'playback_state.dart';

export 'playback_event.dart';
export 'playback_state.dart';

class PlaybackBloc extends Bloc<PlaybackEvent, PlaybackState> {
  PlaybackBloc({required PlaybackUseCase useCase})
    : _useCase = useCase,
      super(PlaybackIdleState(ui: PlaybackStateUi.initial())) {
    on<PlaybackRecordingSelected>(_onRecordingSelected);
    on<PlaybackTogglePressed>(_onTogglePressed);
    on<PlaybackStopPressed>(_onStopPressed);
    on<PlaybackClosed>(_onClosed);
    on<PlaybackSeeked>(_onSeeked);
    on<PlaybackPositionChanged>(_onPositionChanged);
    on<PlaybackDurationChanged>(_onDurationChanged);
    on<PlaybackPlayerStateChanged>(_onPlayerStateChanged);

    _initSubscriptions();
  }

  final PlaybackUseCase _useCase;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  void _initSubscriptions() {
    _positionSubscription = _useCase.positionStream.listen(
      (pos) => add(PlaybackPositionChanged(pos)),
    );
    _durationSubscription = _useCase.durationStream.listen(
      (dur) => add(PlaybackDurationChanged(dur)),
    );
    _playerStateSubscription = _useCase.playerStateStream.listen(
      (s) => add(PlaybackPlayerStateChanged(s)),
    );
  }

  Future<void> _onRecordingSelected(
    PlaybackRecordingSelected event,
    Emitter<PlaybackState> emit,
  ) async {
    final recording = event.recording;
    final filePath = recording.filePath;
    final transcript = recording.transcript ?? '';

    // Transcript-only recordings
    if (filePath == null || filePath.isEmpty) {
      if (transcript.trim().isNotEmpty) {
        emit(
          PlaybackActiveState(
            ui: state.ui.copyWith(
              selectedRecording: recording,
              isPlaying: false,
              position: Duration.zero,
              duration: Duration.zero,
              transcript: transcript,
            ),
          ),
        );
        return;
      }

      emit(
        PlaybackIdleState(
          ui: state.ui,
          snackBarMessage: const HomeSnackBarMessage(
            text: 'Recording không có file audio để phát.',
            type: HomeSnackBarType.warning,
          ),
        ),
      );
      return;
    }

    // Same recording: toggle play/pause
    final currentPath = state.ui.selectedRecording?.filePath;
    if (currentPath != null && currentPath == filePath) {
      add(const PlaybackTogglePressed());
      return;
    }

    // New recording: play it
    try {
      await _useCase.playFromFile(filePath);

      emit(
        PlaybackActiveState(
          ui: state.ui.copyWith(
            selectedRecording: recording,
            isPlaying: true,
            position: Duration.zero,
            transcript: transcript,
          ),
        ),
      );
    } catch (e) {
      emit(
        PlaybackErrorState(
          ui: state.ui.copyWith(
            selectedRecording: recording,
            isPlaying: false,
            position: Duration.zero,
            duration: Duration.zero,
            transcript: transcript,
          ),
          message: 'Không thể phát audio: $e',
          snackBarMessage: HomeSnackBarMessage(
            text: 'Không thể phát audio: $e',
            type: HomeSnackBarType.error,
          ),
        ),
      );
    }
  }

  Future<void> _onTogglePressed(
    PlaybackTogglePressed event,
    Emitter<PlaybackState> emit,
  ) async {
    if (state.ui.selectedRecording?.filePath == null) {
      return;
    }

    try {
      await _useCase.togglePlayPause();
    } catch (e) {
      emit(
        PlaybackErrorState(
          ui: state.ui.copyWith(isPlaying: false),
          message: 'Lỗi play/pause: $e',
          snackBarMessage: HomeSnackBarMessage(
            text: 'Lỗi play/pause: $e',
            type: HomeSnackBarType.error,
          ),
        ),
      );
    }
  }

  Future<void> _onStopPressed(
    PlaybackStopPressed event,
    Emitter<PlaybackState> emit,
  ) async {
    try {
      await _useCase.stop();
      emit(
        PlaybackActiveState(
          ui: state.ui.copyWith(isPlaying: false, position: Duration.zero),
        ),
      );
    } catch (_) {}
  }

  Future<void> _onClosed(
    PlaybackClosed event,
    Emitter<PlaybackState> emit,
  ) async {
    await _useCase.stopSilently();

    emit(PlaybackIdleState(ui: PlaybackStateUi.initial()));
  }

  Future<void> _onSeeked(
    PlaybackSeeked event,
    Emitter<PlaybackState> emit,
  ) async {
    final max = state.ui.duration;
    final target = event.position > max ? max : event.position;
    try {
      await _useCase.seek(target);
    } catch (_) {}
  }

  void _onPositionChanged(
    PlaybackPositionChanged event,
    Emitter<PlaybackState> emit,
  ) {
    if (state.ui.selectedRecording == null) {
      return;
    }
    emit(PlaybackActiveState(ui: state.ui.copyWith(position: event.position)));
  }

  void _onDurationChanged(
    PlaybackDurationChanged event,
    Emitter<PlaybackState> emit,
  ) {
    final duration = event.duration;
    if (duration == null) {
      return;
    }
    emit(PlaybackActiveState(ui: state.ui.copyWith(duration: duration)));
  }

  void _onPlayerStateChanged(
    PlaybackPlayerStateChanged event,
    Emitter<PlaybackState> emit,
  ) {
    if (state.ui.selectedRecording == null) {
      return;
    }

    final ps = event.playerState;
    final isPlaying = ps.playing;
    final isCompleted = ps.processingState == ProcessingState.completed;

    emit(
      PlaybackActiveState(
        ui: state.ui.copyWith(
          isPlaying: !isCompleted && isPlaying,
          position: isCompleted ? state.ui.duration : state.ui.position,
        ),
      ),
    );
  }

  /// Stop playback silently (for external use)
  Future<void> stopSilently() async {
    await _useCase.stopSilently();
  }

  @override
  Future<void> close() async {
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _useCase.dispose();
    return super.close();
  }
}
