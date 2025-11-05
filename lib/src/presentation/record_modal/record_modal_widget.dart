import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/record_data.dart';
import '../../record_audio_constants.dart';
import '../shared/widgets/waveforms_sound/fixed_wareform.dart';
import 'bloc/speech_text_bloc.dart';
import 'record_session_manager.dart';
import 'widgets/control_bar.dart';
import 'widgets/sheet_icon_button.dart';
import 'widgets/transcription_view.dart';
import 'widgets/waveform_view.dart';

class RecordModalWidget extends StatefulWidget {
  const RecordModalWidget({
    super.key,
    this.onExits,
    this.title,
    required this.locale,
    this.colorWaveformView,
    this.restoreFromSession = false,
    this.onShouldMinimize,
  });

  final String? title;
  final Future<bool?> Function()? onExits;
  final String locale;
  final Color? colorWaveformView;
  final bool restoreFromSession;
  final VoidCallback? onShouldMinimize;

  @override
  State<RecordModalWidget> createState() => _RecordModalWidgetState();
}

class _RecordModalWidgetState extends State<RecordModalWidget> {
  Timer? _timer;
  final ValueNotifier<Duration> _elapsedDuration =
      ValueNotifier<Duration>(Duration.zero);
  final AnimatedWaveformController _animatedWaveformController =
      AnimatedWaveformController();

  final ValueNotifier<String> _contentController = ValueNotifier<String>('');
  DateTime? _recordStartedAt;
  Duration _pausedAccumulated = Duration.zero;
  DateTime? _pausedAt;
  bool _supportsPauseResume = true;
  bool _showTranscription = false;
  final ScrollController _scrollController = ScrollController();
  bool _isRestoringFromSession = false;

  RecordSessionManager get sessionManager => RecordSessionManager.instance;

  void _stopRecord(bool save) {
    context.read<SpeechTextBloc>().add(StopRecordEvent(isSave: save));
  }

  void _startPipeline() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<SpeechTextBloc>().add(
            StartRecordEvent(
              callbackToText: _updateContent,
            ),
          );
    });
  }

  void _updateContent(String content) {
    if (content != sessionManager.content) {
      _contentController.value = content;
      sessionManager.updateContent(content);
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    }
  }

  void _onListenerSpeechTextBloc(BuildContext context, SpeechTextState state) {
    if (state is InitFailed && state.stateUI.isCloseFeature) {
      Navigator.of(context).pop();
      return;
    }

    if (state is InitSucceeded) {
      // Start pipeline cho cả restore và new session
      // Vì khi restore, recording vẫn đang chạy nên cần start lại pipeline
      _startPipeline();
    } else if (state is Recording) {
      if (_recordStartedAt == null) {
        _recordStartedAt = DateTime.now();
        _elapsedDuration.value = Duration.zero;
      }
      if (_pausedAt != null) {
        _pausedAccumulated += DateTime.now().difference(_pausedAt!);
        _pausedAt = null;
      }
      // Update session manager
      RecordSessionManager.instance.updateRecordingMetadata(
        recordStartedAt: _recordStartedAt,
        pausedAccumulated: _pausedAccumulated,
        pausedAt: _pausedAt,
      );
    } else if (state is StoppedRecord) {
      _recordStartedAt = null;
      if (!state.isSave) {
        Navigator.of(context).pop();
        return;
      }

      final filePath = state.filePath;
      if (filePath == null) {
        if (state.recordingAvailable == false && mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('Recording unavailable on this platform.'),
            ),
          );
        }
        Navigator.of(context).pop();
        return;
      }

      final record = RecordData(
        createdAt: DateTime.now(),
        url: filePath,
        totalTime: state.recordedDuration,
        content: sessionManager.content,
      );

      if (context.mounted) {
        Navigator.of(context).pop(record);
      }
    } else if (state is RecordError) {
      _recordStartedAt = null;
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(state.message)),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _onTapCloseButton() {
    if (widget.onExits != null) {
      widget.onExits?.call().then((value) {
        if (value == true) {
          _stopRecord(false);
        }
      });
    } else {
      _stopRecord(false);
    }
  }

  void _updateElapsedTimer(Timer timer) {
    final startedAt = _recordStartedAt;
    if (startedAt == null) {
      _elapsedDuration.value = Duration.zero;
      return;
    }
    final now = DateTime.now();
    final pausedExtra =
        _pausedAt != null ? now.difference(_pausedAt!) : Duration.zero;
    final effective =
        now.difference(startedAt) - _pausedAccumulated - pausedExtra;
    _elapsedDuration.value = effective.isNegative ? Duration.zero : effective;
  }

  @override
  void initState() {
    super.initState();

    // Luôn lấy từ session manager (đã được tạo trong coordinator)
    _isRestoringFromSession = widget.restoreFromSession;

    if (_isRestoringFromSession && sessionManager.hasActiveSession) {
      // Restore state từ session manager
      _recordStartedAt = sessionManager.recordStartedAt;
      _pausedAccumulated = sessionManager.pausedAccumulated;
      _pausedAt = sessionManager.pausedAt;
      // Restore session về non-minimized state
      sessionManager.restoreSession();
      _updateContent(sessionManager.content ?? '');
    }

    _timer =
        Timer.periodic(const Duration(milliseconds: 80), _updateElapsedTimer);
    _supportsPauseResume = _detectPauseSupport();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentState = context.read<SpeechTextBloc>().state;
        if (currentState is InitSucceeded && !_isRestoringFromSession) {
          _startPipeline();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedDuration.dispose();

    // Lưu state vào session manager trước khi dispose
    final sessionManager = RecordSessionManager.instance;
    if (sessionManager.hasActiveSession) {
      sessionManager.updateRecordingMetadata(
        recordStartedAt: _recordStartedAt,
        pausedAccumulated: _pausedAccumulated,
        pausedAt: _pausedAt,
      );
    }

    _animatedWaveformController.pause = null;
    _animatedWaveformController.resume = null;

    super.dispose();
  }

  bool _detectPauseSupport() {
    try {
      if (Platform.isAndroid) {
        final v = Platform.operatingSystemVersion; // e.g. 'Android 13 (SDK 33)'
        final sdkMatch = RegExp(r'SDK\s*(\d+)').firstMatch(v);
        if (sdkMatch != null) {
          final sdk = int.tryParse(sdkMatch.group(1) ?? '') ?? 0;
          return sdk >= 24;
        }
        // If cannot parse, be conservative and disable
        return false;
      }
      // iOS/macOS/web: allow by default
      return true;
    } catch (_) {
      return true;
    }
  }

  String _formatClockTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatElapsedForDisplay(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hundredths =
        (value.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    if (hours > 0) {
      final hoursText = hours.toString().padLeft(2, '0');
      return '$hoursText:$minutes:$seconds,$hundredths';
    }
    return '$minutes:$seconds,$hundredths';
  }

  void _onTogglePauseResume(SpeechTextState state) {
    if (!_supportsPauseResume || !mounted) {
      return;
    }

    if (state is Recording) {
      _pausedAt = DateTime.now();
      context.read<SpeechTextBloc>().add(PauseRecordEvent());
      if (_animatedWaveformController.pause != null) {
        _animatedWaveformController.pause?.call();
      }
    } else if (state is PausedRecording) {
      context.read<SpeechTextBloc>().add(ResumeRecordEvent());
      if (_animatedWaveformController.resume != null) {
        _animatedWaveformController.resume?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;

    final displayTitle = (widget.title?.trim().isNotEmpty ?? false)
        ? widget.title!.trim()
        : 'New Recording';

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: double.infinity,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: BlocConsumer<SpeechTextBloc, SpeechTextState>(
            listener: _onListenerSpeechTextBloc,
            builder: (context, state) {
              final bool isSaving = state is StopingRecord;
              final bool isInitialising = state is InitialingService;
              final isDarkMode = Theme.brightnessOf(context) == Brightness.dark;

              return GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24)
                      .copyWith(top: 20),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 52,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            SheetIconButton(
                              icon: Icons.close_rounded,
                              tooltip: 'Close',
                              onTap: isSaving ? null : _onTapCloseButton,
                              backgroundColor: Theme.brightnessOf(context) ==
                                      Brightness.light
                                  ? Colors.grey[200]!
                                  : Colors.white10,
                              iconColor:
                                  isDarkMode ? Colors.white : Colors.black,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayTitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.brightnessOf(context) ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ValueListenableBuilder<Duration>(
                                    valueListenable: _elapsedDuration,
                                    builder: (_, duration, __) {
                                      final reference =
                                          _recordStartedAt ?? DateTime.now();
                                      final subtitle =
                                          '${_formatClockTime(reference)}  '
                                          '${duration.formatTimeAudio}';
                                      return Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 13,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SheetIconButton.progressAware(
                              icon: Icons.check_rounded,
                              tooltip: 'Save record',
                              onTap: isSaving ? null : () => _stopRecord(true),
                              backgroundColor: const Color(0xFF0A84FF),
                              iconColor: Colors.white,
                              isLoading: isSaving,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                            constraints: BoxConstraints(
                              minWidth: 100,
                              maxHeight: screenHeight * 0.32,
                            ),
                            child: ValueListenableBuilder(
                              valueListenable: _contentController,
                              builder: (context, value, child) {
                                return TranscriptionView(
                                  value: value,
                                  key: const ValueKey<String>('transcription'),
                                  onChanged: _updateContent,
                                  scrollController: _scrollController,
                                );
                              },
                            )),
                        const SizedBox(height: 12),
                        const Spacer(),
                        Container(
                          height: 70,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          child: WaveformView(
                            key: const ValueKey<String>('waveform'),
                            controller: _animatedWaveformController,
                            isInitialising: isInitialising,
                            color: widget.colorWaveformView,
                          ),
                        ),
                        ValueListenableBuilder<Duration>(
                          valueListenable: _elapsedDuration,
                          builder: (_, duration, __) {
                            return Text(
                              _formatElapsedForDisplay(duration),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.brightnessOf(context) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.graphic_eq_outlined,
                              size: 16,
                              color:
                                  Theme.brightnessOf(context) == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Speech to text is working',
                              style: TextStyle(
                                color: Theme.brightnessOf(context) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ControlBar(
                          showTranscription: _showTranscription,
                          supportsPauseResume: _supportsPauseResume,
                          isPaused: state is PausedRecording,
                          isRecording:
                              state is Recording || state is PausedRecording,
                          isSaving: isSaving,
                          isInitialising: isInitialising,
                          onToggleText: () {
                            setState(() {
                              _showTranscription = !_showTranscription;
                            });
                          },
                          onTogglePause: () => _onTogglePauseResume(state),
                          onStop: () => _stopRecord(true),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
