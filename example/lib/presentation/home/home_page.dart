import 'dart:async';

import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/header_widget.dart';
import '../../core/widgets/language_selector_dialog.dart';
import '../../core/widgets/main_content_widget.dart';
import '../../core/widgets/mode_selector_widget.dart';
import '../../core/widgets/playback_controls_widget.dart';
import '../../core/widgets/recording_controls_widget.dart';
import '../../core/widgets/recordings_list_widget.dart';
import '../../core/widgets/transcript_card_widget.dart';
import '../../domain/entities/home_data.dart';
import 'bloc/home_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final HomeBloc _homeBloc;

  EasyAudioState? _lastAudioState;

  Timer? _recordingTimer;
  Duration _recordingAccumulated = Duration.zero;
  DateTime? _recordingStartedAt;
  Duration _recordingDuration = Duration.zero;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc.create()..start();
    _lastAudioState = _homeBloc.recordingBloc.state.ui.audioState;
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _homeBloc.close();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecordingUiTimer({required bool isResume}) {
    if (!isResume) {
      _recordingAccumulated = Duration.zero;
      _recordingDuration = Duration.zero;
    }

    _recordingStartedAt = DateTime.now();
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _recordingStartedAt;
      if (startedAt == null) {
        return;
      }
      setState(() {
        _recordingDuration =
            _recordingAccumulated + DateTime.now().difference(startedAt);
      });
    });
  }

  void _pauseRecordingUiTimer() {
    final startedAt = _recordingStartedAt;
    if (startedAt != null) {
      _recordingAccumulated += DateTime.now().difference(startedAt);
    }
    _recordingStartedAt = null;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    setState(() {
      _recordingDuration = _recordingAccumulated;
    });
  }

  void _resetRecordingUiTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingStartedAt = null;
    _recordingAccumulated = Duration.zero;
    setState(() {
      _recordingDuration = Duration.zero;
    });
  }

  void _showSnackBar(HomeSnackBarMessage message) {
    Color color;
    switch (message.type) {
      case HomeSnackBarType.success:
        color = Colors.green;
        break;
      case HomeSnackBarType.warning:
        color = Colors.orange;
        break;
      case HomeSnackBarType.error:
        color = Colors.red;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.text), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeBloc.easyAudioManageBloc),
        BlocProvider.value(value: _homeBloc.recordingBloc),
        BlocProvider.value(value: _homeBloc.playbackBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          // Snackbar listeners
          BlocListener<EasyAudioManageBloc, EasyAudioManageState>(
            listenWhen: (prev, next) =>
                prev.snackBarMessage != next.snackBarMessage &&
                next.snackBarMessage != null,
            listener: (context, state) {
              if (state.snackBarMessage != null) {
                _showSnackBar(state.snackBarMessage!);
              }
            },
          ),
          BlocListener<RecordingBloc, RecordingState>(
            listenWhen: (prev, next) =>
                prev.snackBarMessage != next.snackBarMessage &&
                next.snackBarMessage != null,
            listener: (context, state) {
              if (state.snackBarMessage != null) {
                _showSnackBar(state.snackBarMessage!);
              }
            },
          ),
          BlocListener<PlaybackBloc, PlaybackState>(
            listenWhen: (prev, next) =>
                prev.snackBarMessage != next.snackBarMessage &&
                next.snackBarMessage != null,
            listener: (context, state) {
              if (state.snackBarMessage != null) {
                _showSnackBar(state.snackBarMessage!);
              }
            },
          ),
          // Recording timer listener
          BlocListener<RecordingBloc, RecordingState>(
            listenWhen: (prev, next) =>
                prev.ui.audioState != next.ui.audioState,
            listener: (context, state) {
              final prev = _lastAudioState;
              final next = state.ui.audioState;

              _lastAudioState = next;

              if (next == EasyAudioState.recording) {
                _startRecordingUiTimer(isResume: prev == EasyAudioState.paused);
                return;
              }

              if (next == EasyAudioState.paused ||
                  next == EasyAudioState.processing ||
                  next == EasyAudioState.error) {
                _pauseRecordingUiTimer();
                return;
              }

              if (next == EasyAudioState.idle ||
                  next == EasyAudioState.initializing) {
                _resetRecordingUiTimer();
                return;
              }
            },
          ),
          // Handle recovered recording
          BlocListener<EasyAudioManageBloc, EasyAudioManageState>(
            listenWhen: (prev, next) =>
                next is EasyAudioManageReadyState &&
                next.recoveredRecording != null,
            listener: (context, state) {
              if (state is EasyAudioManageReadyState &&
                  state.recoveredRecording != null) {
                _homeBloc.recordingBloc.add(
                  RecordingAdded(state.recoveredRecording!),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: SafeArea(child: _buildContent()),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<EasyAudioManageBloc, EasyAudioManageState>(
      builder: (context, manageState) {
        return BlocBuilder<RecordingBloc, RecordingState>(
          builder: (context, recordingState) {
            return BlocBuilder<PlaybackBloc, PlaybackState>(
              builder: (context, playbackState) {
                final audioState = recordingState.ui.audioState;
                final selectedMode = manageState.ui.selectedMode;
                final selectedRecording = playbackState.ui.selectedRecording;
                final isDetailMode = selectedRecording != null;
                final isAudioSelected = selectedRecording?.filePath != null;
                final isPlaybackMode = isDetailMode;
                final isTranscriptOnlySelected =
                    isDetailMode && !isAudioSelected;

                final transcriptText = isPlaybackMode
                    ? playbackState.ui.transcript
                    : recordingState.ui.transcript;

                return Column(
                  children: [
                    HeaderWidget(
                      state: audioState,
                      showMicIcon: !isPlaybackMode,
                    ),
                    ModeSelectorWidget(
                      selectedMode: selectedMode,
                      state: audioState,
                      onModeSelected: (mode) => context
                          .read<EasyAudioManageBloc>()
                          .add(EasyAudioManageModeSelected(mode)),
                    ),
                    if (selectedMode != EasyAudioMode.recordOnly)
                      _buildLocaleSelector(context, manageState, audioState),
                    Expanded(
                      child: MainContentWidget(
                        selectedMode: selectedMode,
                        state: audioState,
                        recordingDuration: _recordingDuration,
                        amplitude: recordingState.ui.amplitude,
                        pulseAnimation: _pulseAnimation,
                        transcript: recordingState.ui.transcript,
                        liveTranscript: recordingState.ui.liveTranscript,
                        isPlaybackMode: isPlaybackMode,
                        forceShowTranscript:
                            isAudioSelected && transcriptText.isNotEmpty,
                        hideTranscriptSection: isTranscriptOnlySelected,
                      ),
                    ),
                    if (!isDetailMode)
                      RecordingControlsWidget(
                        state: audioState,
                        onToggleRecording: () => context
                            .read<RecordingBloc>()
                            .add(const RecordingTogglePressed()),
                        onCancelRecording: () => context
                            .read<RecordingBloc>()
                            .add(const RecordingCancelPressed()),
                        onPauseRecording: () => context
                            .read<RecordingBloc>()
                            .add(const RecordingPausePressed()),
                      ),
                    PlaybackControlsWidget(
                      selectedRecording: selectedRecording,
                      isPlaying: playbackState.ui.isPlaying,
                      position: playbackState.ui.position,
                      duration: playbackState.ui.duration,
                      onToggle: () => context.read<PlaybackBloc>().add(
                        const PlaybackTogglePressed(),
                      ),
                      onStop: () => context.read<PlaybackBloc>().add(
                        const PlaybackStopPressed(),
                      ),
                      onSeek: (pos) =>
                          context.read<PlaybackBloc>().add(PlaybackSeeked(pos)),
                      onClose: () => context.read<PlaybackBloc>().add(
                        const PlaybackClosed(),
                      ),
                    ),
                    if (isTranscriptOnlySelected)
                      TranscriptCardWidget(
                        transcript: transcriptText,
                        onClose: () => context.read<PlaybackBloc>().add(
                          const PlaybackClosed(),
                        ),
                      ),
                    RecordingsListWidget(
                      recordings: recordingState.ui.recordings,
                      selectedRecording: selectedRecording,
                      isPlaying: playbackState.ui.isPlaying,
                      onRecordingPressed: (r) => context
                          .read<PlaybackBloc>()
                          .add(PlaybackRecordingSelected(r)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLocaleSelector(
    BuildContext context,
    EasyAudioManageState manageState,
    EasyAudioState audioState,
  ) {
    final selectedLocale = manageState.ui.selectedLocale;
    final locales = manageState.ui.supportedLocales;
    final isLoading = manageState.ui.isLocalesLoading;
    final isDisabled = audioState != EasyAudioState.idle;

    // Find selected locale name
    String selectedName = 'Tự động';
    if (selectedLocale != null) {
      final found = locales.where((l) => l.localeId == selectedLocale);
      if (found.isNotEmpty) {
        selectedName = found.first.name;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled || isLoading
              ? null
              : () async {
                  final result = await LanguageSelectorDialog.show(
                    context: context,
                    locales: locales,
                    selectedLocale: selectedLocale,
                  );

                  // result is null if dialog was dismissed,
                  // or the selected locale (can be null for "Auto")
                  if (result != selectedLocale && context.mounted) {
                    context.read<EasyAudioManageBloc>().add(
                      EasyAudioManageLocaleSelected(result),
                    );
                  }
                },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.language,
                    size: 20,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngôn ngữ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedName,
                        style: TextStyle(
                          color: isDisabled ? Colors.white38 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.blue),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: isDisabled ? Colors.white24 : Colors.white54,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
