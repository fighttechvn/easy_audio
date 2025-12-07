import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/logs/debug_print.dart';
import '../../core/utils/record_modal_utils.dart';
import '../../domain/entities/record_data.dart';
import '../shared/widgets/waveforms_sound/fixed_wareform.dart';
import 'bloc/speech_text_bloc.dart';
import 'record_session_manager.dart';
import 'widgets/control_bar.dart';
import 'widgets/record_modal_header.dart';
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
  bool _isRestoringFromSession = false;

  RecordSessionManager get sessionManager => RecordSessionManager.instance;

  void _stopRecord(bool save) {
    final bloc = context.read<SpeechTextBloc>();
    if (bloc.isClosed) {
      debugPrintCannotStopRecordBlocClosed();
      return;
    }

    debugPrintStopRecord(save);
    bloc.add(StopRecordEvent(isSave: save));
  }

  void _startPipeline() {
    debugPrintStartingPipeline();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        debugPrintCannotStartPipelineWidgetNotMounted();
        return;
      }
      final bloc = context.read<SpeechTextBloc>();
      if (bloc.isClosed) {
        debugPrintCannotStartPipelineBlocClosed();
        return;
      }
      debugPrintAddingStartRecordEvent(bloc.state.runtimeType);

      // Sử dụng wrapper callback để luôn gọi callback hiện tại
      // từ session manager
      bloc.add(
        StartRecordEvent(
          callbackToText: (String content) {
            // Lấy callback hiện tại từ session manager
            final currentCallback = sessionManager.updateContentCallback;
            if (currentCallback != null) {
              debugPrintCallingCurrentCallbackFromSessionManager();
              currentCallback(content);
            } else {
              debugPrintWarningNoCallbackInSessionManager();
            }
          },
        ),
      );
      // Đánh dấu pipeline active sau khi start
      sessionManager.setPipelineActive(true);
      debugPrintPipelineStarted();
    });
  }

  void _updateContent(String content) {
    if (content != sessionManager.content) {
      _contentController.value = content;
      sessionManager.updateContent(content);
    }
  }

  void _onListenerSpeechTextBloc(BuildContext context, SpeechTextState state) {
    debugPrintBlocStateChanged(state.runtimeType);

    if (state is InitFailed && state.stateUI.isCloseFeature) {
      debugPrintInitFailedClosingModal(state.stateUI);
      Navigator.of(context).pop();
      return;
    }

    if (state is InitSucceeded) {
      // Start pipeline cho cả restore và new session
      // Vì khi restore, recording vẫn đang chạy nên cần start lại pipeline
      debugPrintInitSucceededStartingPipeline();
      _startPipeline();
    } else if (state is Recording) {
      if (_recordStartedAt == null) {
        _recordStartedAt = DateTime.now();
        _elapsedDuration.value = Duration.zero;
        debugPrintRecordingStarted();
      }
      if (_pausedAt != null) {
        _pausedAccumulated += DateTime.now().difference(_pausedAt!);
        _pausedAt = null;
        debugPrintRecordingResumed();
      }
      // Update session manager
      RecordSessionManager.instance.updateRecordingMetadata(
        recordStartedAt: _recordStartedAt,
        pausedAccumulated: _pausedAccumulated,
        pausedAt: _pausedAt,
      );
    } else if (state is StoppedRecord) {
      debugPrintRecordingStopped(state.isSave, state.filePath != null);
      _recordStartedAt = null;
      // Set pipeline inactive khi recording stopped
      sessionManager.setPipelineActive(false);

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
      debugPrintRecordingError(state.message);
      _recordStartedAt = null;
      // Set pipeline inactive khi có error
      sessionManager.setPipelineActive(false);

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

    debugPrintInitState(
        widget.restoreFromSession, sessionManager.hasActiveSession);

    // Lưu callback vào session manager để có thể sử dụng lại khi restore
    sessionManager.setUpdateContentCallback(_updateContent);

    // Luôn lấy từ session manager (đã được tạo trong coordinator)
    _isRestoringFromSession = widget.restoreFromSession;

    if (_isRestoringFromSession && sessionManager.hasActiveSession) {
      // Restore state từ session manager
      _recordStartedAt = sessionManager.recordStartedAt;
      _pausedAccumulated = sessionManager.pausedAccumulated;
      _pausedAt = sessionManager.pausedAt;
      // Restore session về non-minimized state
      sessionManager.restoreSession();

      // Restore content - set trực tiếp vào controller
      final restoredContent = sessionManager.content ?? '';
      _contentController.value = restoredContent;
      debugPrintRestoredContentToController(restoredContent.length);

      debugPrintRestoringFromSession(
          sessionManager.isPipelineActive, sessionManager.content?.length ?? 0);

      // Không cần restart pipeline vì wrapper callback sẽ tự động
      // gọi callback mới từ session manager
      debugPrintPipelineWillUseNewCallback();
    } else {
      debugPrintStartingNewRecordingSession();
    }

    _timer =
        Timer.periodic(const Duration(milliseconds: 80), _updateElapsedTimer);
    _supportsPauseResume = RecordModalUtils.supportsPauseResume;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        debugPrintWarningWidgetNotMountedInPostFrameCallback();
        return;
      }
      final bloc = context.read<SpeechTextBloc>();
      if (bloc.isClosed) {
        debugPrintWarningBlocClosedInPostFrameCallback();
        return;
      }
      final currentState = bloc.state;
      if (currentState is InitSucceeded && !_isRestoringFromSession) {
        debugPrintNewSessionInitializedStartingPipeline();
        _startPipeline();
      }
    });
  }

  @override
  void dispose() {
    debugPrintDispose(
        sessionManager.hasActiveSession, sessionManager.isMinimized);

    _timer?.cancel();
    _elapsedDuration.dispose();

    // Lưu state vào session manager trước khi dispose
    if (sessionManager.hasActiveSession) {
      sessionManager.updateRecordingMetadata(
        recordStartedAt: _recordStartedAt,
        pausedAccumulated: _pausedAccumulated,
        pausedAt: _pausedAt,
      );

      // Clear callback nếu session đang kết thúc (không minimize)
      if (!sessionManager.isMinimized) {
        debugPrintSessionEndingClearingCallback();
        sessionManager.setUpdateContentCallback(null);
      } else {
        debugPrintSessionMinimizedKeepingCallback();
      }
    }

    _animatedWaveformController.pause = null;
    _animatedWaveformController.resume = null;

    super.dispose();
  }

  void _onTogglePauseResume(SpeechTextState state) {
    if (!_supportsPauseResume || !mounted) {
      debugPrintCannotTogglePauseResume(_supportsPauseResume, mounted);
      return;
    }

    final bloc = context.read<SpeechTextBloc>();
    if (bloc.isClosed) {
      debugPrintWarningCannotTogglePauseResumeBlocClosed();
      return;
    }

    if (state is Recording) {
      _pausedAt = DateTime.now();
      bloc.add(PauseRecordEvent());
      if (_animatedWaveformController.pause != null) {
        _animatedWaveformController.pause?.call();
      }
    } else if (state is PausedRecording) {
      bloc.add(ResumeRecordEvent());
      if (_animatedWaveformController.resume != null) {
        _animatedWaveformController.resume?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

              return GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                        ),
                      ]),
                  padding: const EdgeInsets.symmetric(horizontal: 24)
                      .copyWith(top: 16),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RecordModalHeader(
                          title: displayTitle,
                          elapsedDuration: _elapsedDuration,
                          recordStartedAt: _recordStartedAt,
                          isSaving: isSaving,
                          onClose: _onTapCloseButton,
                          onSave: () => _stopRecord(true),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 100,

                              // maxHeight: screenHeight * 0.32,
                            ),
                            child: ValueListenableBuilder(
                              valueListenable: _contentController,
                              builder: (context, value, child) {
                                return TranscriptionView(
                                  value: value,
                                  key: const ValueKey<String>('transcription'),
                                  onChanged: _updateContent,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                              RecordModalUtils.formatElapsedForDisplay(
                                  duration),
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
