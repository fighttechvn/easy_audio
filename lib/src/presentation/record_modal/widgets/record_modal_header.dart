import 'package:flutter/material.dart';

import '../../../core/utils/record_modal_utils.dart';
import '../../../record_audio_constants.dart';
import 'sheet_icon_button.dart';

class RecordModalHeader extends StatelessWidget {
  const RecordModalHeader({
    super.key,
    required this.title,
    required this.elapsedDuration,
    required this.recordStartedAt,
    required this.isSaving,
    required this.onClose,
    required this.onSave,
  });

  /// Title to display in the header
  final String title;

  /// Current elapsed recording duration
  final ValueNotifier<Duration> elapsedDuration;

  /// When the recording started (for clock display)
  final DateTime? recordStartedAt;

  /// Whether save is in progress
  final bool isSaving;

  /// Callback when close button is tapped
  final VoidCallback onClose;

  /// Callback when save button is tapped
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.brightnessOf(context) == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle indicator
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
        // Header row with buttons and title
        Row(
          children: [
            // Close button
            SheetIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Close',
              onTap: isSaving ? null : onClose,
              backgroundColor: Theme.brightnessOf(context) == Brightness.light
                  ? Colors.grey[200]!
                  : Colors.white10,
              iconColor: isDarkMode ? Colors.white : Colors.black,
            ),
            // Title and time
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ValueListenableBuilder<Duration>(
                    valueListenable: elapsedDuration,
                    builder: (_, duration, __) {
                      final reference = recordStartedAt ?? DateTime.now();
                      final subtitle =
                          '${RecordModalUtils.formatClockTime(reference)}  '
                          '${duration.formatTimeAudio}';
                      return Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Save button
            SheetIconButton.progressAware(
              icon: Icons.check_rounded,
              tooltip: 'Save record',
              onTap: isSaving ? null : onSave,
              backgroundColor: const Color(0xFF0A84FF),
              iconColor: Colors.white,
              isLoading: isSaving,
            ),
          ],
        ),
      ],
    );
  }
}
