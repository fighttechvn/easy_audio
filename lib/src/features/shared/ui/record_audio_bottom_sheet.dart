import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/easy_audio_locale_display.dart';
import '../../../core/controllers/elapsed_ticker.dart';
import '../../../core/utils/duration_ext.dart';
import '../../../domain/entities/easy_audio_state.dart';
import '../../../domain/entities/record_audio_transcript_state.dart';
import '../../../domain/entities/transcript_result.dart';
import '../../../record_coordinator.dart';
import '../services/easy_audio/easy_audio_service.dart';
import 'record_audio_pause_button.dart';
import 'record_audio_session_controller.dart';
import 'record_audio_sheet_header.dart';
import 'record_audio_transcript_card.dart';
import 'record_audio_waveform_pill.dart';

class RecordAudioBottomSheetWidget extends StatefulWidget {
  const RecordAudioBottomSheetWidget({
    super.key,
    required this.easyAudio,
    required this.localeId,
    required this.enableAndroidBackgroundRecording,
    this.initialAmplitudeHistory,
    this.initialFinalTranscript,
    this.initialLiveTranscript,
    this.initialState,
    this.initialElapsed,
    this.onMinimizeRequested,
    this.onCloseRequested,
  });

  final EasyAudioService easyAudio;
  final String? localeId;
  final bool enableAndroidBackgroundRecording;

  final List<double>? initialAmplitudeHistory;
  final String? initialFinalTranscript;
  final String? initialLiveTranscript;
  final EasyAudioState? initialState;
  final Duration? initialElapsed;

  final Future<void> Function()? onMinimizeRequested;
  final Future<void> Function()? onCloseRequested;

  @override
  State<RecordAudioBottomSheetWidget> createState() =>
      _RecordAudioBottomSheetWidgetState();
}

class _RecordAudioBottomSheetWidgetState
    extends State<RecordAudioBottomSheetWidget> {
  final List<double> _amplitudeHistory = <double>[];
  static const int _maxSamples = 60;

  late final RecordAudioSessionController _controller;

  EasyAudioState _state = EasyAudioState.idle;

  late final ElapsedTicker _elapsedTicker;
  Duration _elapsed = Duration.zero;

  late final RecordAudioTranscriptState _transcriptState;

  bool get _isIOS => Platform.isIOS;
  bool get _canShowTranscript => _isIOS;
  bool get _isRecording => _state == EasyAudioState.recording;
  bool get _isPaused => _state == EasyAudioState.paused;
  bool get _isActiveSession =>
      _state == EasyAudioState.recording ||
      _state == EasyAudioState.paused ||
      _state == EasyAudioState.processing;

  @override
  void initState() {
    super.initState();

    _elapsed = widget.initialElapsed ?? Duration.zero;
    _elapsedTicker = ElapsedTicker(
      initialElapsed: _elapsed,
      onTick: (next) {
        if (!mounted) {
          return;
        }
        setState(() {
          _elapsed = next;
        });
      },
    );

    final initial = widget.initialAmplitudeHistory;
    if (initial != null && initial.isNotEmpty) {
      final startIndex =
          initial.length > _maxSamples ? initial.length - _maxSamples : 0;
      _amplitudeHistory.addAll(
        initial
            .skip(startIndex)
            .map((e) => e.clamp(0.0, 1.0))
            .toList(growable: false),
      );
    }

    _state = widget.initialState ?? widget.easyAudio.currentState;

    _transcriptState = RecordAudioTranscriptState(
      initialFinal: widget.initialFinalTranscript ?? '',
      initialLive: widget.initialLiveTranscript ?? '',
    );

    _controller = RecordAudioSessionController(
      easyAudio: widget.easyAudio,
      localeId: widget.localeId,
      enableAndroidBackgroundRecording: widget.enableAndroidBackgroundRecording,
      onStateChanged: _onEasyAudioState,
      onAmplitude: _onAmplitude,
      onTranscript: _onTranscript,
      onPermissionDenied: _onPermissionDenied,
      onInitFailed: _onInitFailed,
    );

    _controller.initAndStart();
  }

  void _onEasyAudioState(EasyAudioState s) {
    if (!mounted) {
      return;
    }

    setState(() {
      _state = s;
    });

    // Drive the local timer off the state stream.
    if (s == EasyAudioState.recording) {
      _elapsedTicker.start();
    } else if (s == EasyAudioState.paused) {
      _elapsedTicker.pause();
    } else if (s == EasyAudioState.processing) {
      // Treat processing as non-recording time.
      _elapsedTicker.pause();
    } else if (s == EasyAudioState.idle || s == EasyAudioState.error) {
      _elapsedTicker.reset();
    }
  }

  void _onAmplitude(double amp) {
    if (!mounted) {
      return;
    }

    setState(() {
      _amplitudeHistory.add(amp.clamp(0.0, 1.0));
      if (_amplitudeHistory.length > _maxSamples) {
        _amplitudeHistory.removeRange(
          0,
          _amplitudeHistory.length - _maxSamples,
        );
      }
    });
  }

  void _onTranscript(TranscriptResult result) {
    if (!mounted) {
      return;
    }

    setState(() {
      _transcriptState.apply(result);
    });
  }

  void _onPermissionDenied() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _onInitFailed() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _elapsedTicker.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onClose() async {
    final ok = await context.confirmCloseRecording(
      isActiveSession: _isActiveSession,
    );
    if (!ok) {
      return;
    }

    if (widget.onCloseRequested != null) {
      await widget.onCloseRequested!.call();
      return;
    }

    try {
      await widget.easyAudio.cancel();
    } catch (_) {
      // ignore
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _onPauseResume() async {
    try {
      if (_isRecording) {
        await widget.easyAudio.pause();
      } else if (_isPaused) {
        await widget.easyAudio.resume();
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _onStop() async {
    try {
      final result = await widget.easyAudio.stop();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    }
  }

  String _titleText() {
    if (!_canShowTranscript) {
      return '';
    }

    final id = widget.localeId?.toLowerCase().trim();
    if (id == null || id.isEmpty) {
      return 'Transcript';
    }

    final languageName = EasyAudioLocaleDisplay.labelForLocaleId(id);
    return languageName;
  }

  String _statusText() {
    if (_state == EasyAudioState.recording) {
      return _canShowTranscript ? 'Speech to text is working' : 'Recording…';
    }
    if (_state == EasyAudioState.paused) {
      return widget.easyAudio.wasPausedByInterruption
          ? 'Paused due to interruption'
          : 'Paused';
    }
    if (_state == EasyAudioState.processing) {
      return 'Processing…';
    }
    return 'Ready';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                RecordAudioSheetHeader(
                  title: _titleText(),
                  canStop: _isRecording || _isPaused,
                  onClose: _onClose,
                  onStop: _onStop,
                ),
                const SizedBox(height: 24),
                if (_canShowTranscript) ...[
                  Text(
                    'Transcript',
                    textAlign: TextAlign.start,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 180,
                    child: RecordAudioTranscriptCard(
                      text: _transcriptState.buildCombinedText(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                RecordAudioWaveformPill(samples: _amplitudeHistory),
                const SizedBox(height: 24),
                Text(
                  _elapsed.formatElapsedMinutesSecondsCentiseconds(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 48,
                    color: Colors.black,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_canShowTranscript && _isRecording) ...[
                      Icon(
                        Icons.graphic_eq,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _statusText(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: RecordAudioPauseButton(
                    enabled: _isRecording || _isPaused,
                    isPaused: _isPaused,
                    onTap: _onPauseResume,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
