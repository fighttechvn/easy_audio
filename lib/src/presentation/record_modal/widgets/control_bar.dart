import 'package:flutter/material.dart';

import 'primary_record_button.dart';
import 'secondary_control_button.dart';

class ControlBar extends StatelessWidget {
  const ControlBar({
    required this.showTranscription,
    required this.supportsPauseResume,
    required this.isPaused,
    required this.isRecording,
    required this.isSaving,
    required this.isInitialising,
    required this.onToggleText,
    required this.onTogglePause,
    required this.onStop,
    this.onMinimize,
    super.key,
  });

  final bool showTranscription;
  final bool supportsPauseResume;
  final bool isPaused;
  final bool isRecording;
  final bool isSaving;
  final bool isInitialising;
  final VoidCallback onToggleText;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;
  final VoidCallback? onMinimize;

  @override
  Widget build(BuildContext context) {
    final bool showLoading = isSaving || isInitialising;
    final bool enablePauseButton =
        supportsPauseResume && isRecording && !showLoading;
    final bool useStopIcon = !supportsPauseResume;
    final bool centralIsPaused = supportsPauseResume && isPaused;
    final bool centralEnabled =
        supportsPauseResume ? enablePauseButton : !showLoading;
    final VoidCallback? centralOnTap =
        supportsPauseResume ? onTogglePause : (showLoading ? null : onStop);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // SecondaryControlButton(
        //   icon: Icons.chat_bubble_outline_rounded,
        //   isActive: showTranscription,
        //   onTap: showLoading ? null : onToggleText,

        // ),
        PrimaryRecordButton(
          isPaused: centralIsPaused,
          isEnabled: centralEnabled,
          isLoading: showLoading,
          useStopIcon: useStopIcon,
          onTap: centralOnTap,
        ),
        const SizedBox(width: 24),
        SecondaryControlButton(
          icon: Icons.remove_circle_outline_rounded,
          isActive: false,
          onTap: showLoading ? null : onMinimize,
        ),
      ],
    );
  }
}
