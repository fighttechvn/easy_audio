import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../record_audio_constants.dart';
import '../bloc/speech_text_bloc.dart';
import '../record_session_manager.dart';

/// Widget nhỏ gọn hiển thị trạng thái recording khi minimize
class FloatingRecordWidget extends StatefulWidget {
  const FloatingRecordWidget({
    super.key,
    required this.onTap,
    this.onClose,
  });

  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  State<FloatingRecordWidget> createState() => _FloatingRecordWidgetState();
}

class _FloatingRecordWidgetState extends State<FloatingRecordWidget> {
  Timer? _timer;
  final ValueNotifier<Duration> _elapsedDuration =
      ValueNotifier<Duration>(Duration.zero);

  @override
  void initState() {
    super.initState();
    debugPrint('🎙️ [Build][SessionManager] initState');
    _timer =
        Timer.periodic(const Duration(milliseconds: 80), _updateElapsedTimer);
  }

  @override
  void dispose() {
    debugPrint('🎙️ [Build][SessionManager] dispose');
    _timer?.cancel();
    _elapsedDuration.dispose();
    super.dispose();
  }

  void _updateElapsedTimer(Timer timer) {
    final sessionManager = RecordSessionManager.instance;
    final startedAt = sessionManager.recordStartedAt;

    if (startedAt == null) {
      _elapsedDuration.value = Duration.zero;
      return;
    }

    final now = DateTime.now();
    final pausedExtra = sessionManager.pausedAt != null
        ? now.difference(sessionManager.pausedAt!)
        : Duration.zero;
    final effective = now.difference(startedAt) -
        sessionManager.pausedAccumulated -
        pausedExtra;
    _elapsedDuration.value = effective.isNegative ? Duration.zero : effective;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎙️ [Build][SessionManager] build');
    final sessionManager = RecordSessionManager.instance;
    final bloc = sessionManager.bloc;

    if (bloc == null) {
      return const SizedBox.shrink();
    }

    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<SpeechTextBloc, SpeechTextState>(
        builder: (context, state) {
          final isPaused = state is PausedRecording;
          final isRecording = state is Recording || state is PausedRecording;
          debugPrint(
              '🎙️ [Build][SessionManager] build BlocBuilder state: $state');

          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Main content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon - play nếu pause, mic nếu recording
                        Icon(
                          isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.mic_rounded,
                          color:
                              isPaused ? const Color(0xFF0A84FF) : Colors.red,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        // Elapsed time nếu đang record
                        if (isRecording)
                          ValueListenableBuilder<Duration>(
                            valueListenable: _elapsedDuration,
                            builder: (_, duration, __) {
                              return Text(
                                duration.formatTimeAudio,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  // Close button (optional)
                  if (widget.onClose != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1C1C1E),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  // Recording indicator
                  if (isRecording && !isPaused)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
