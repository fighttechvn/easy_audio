import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

import 'mode_button_widget.dart';

class ModeSelectorWidget extends StatelessWidget {
  const ModeSelectorWidget({
    super.key,
    required this.selectedMode,
    required this.state,
    required this.onModeSelected,
  });

  final EasyAudioMode selectedMode;
  final EasyAudioState state;
  final ValueChanged<EasyAudioMode> onModeSelected;

  bool get _isDisabled => state != EasyAudioState.idle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ModeButtonWidget(
              label: 'Record',
              icon: Icons.fiber_manual_record,
              isSelected: selectedMode == EasyAudioMode.recordOnly,
              isDisabled: _isDisabled,
              onTap: () => onModeSelected(EasyAudioMode.recordOnly),
            ),
            ModeButtonWidget(
              label: 'Speech',
              icon: Icons.text_fields,
              isSelected: selectedMode == EasyAudioMode.speechToTextOnly,
              isDisabled: _isDisabled,
              onTap: () => onModeSelected(EasyAudioMode.speechToTextOnly),
            ),
            ModeButtonWidget(
              label: 'Realtime',
              icon: Icons.bolt,
              isSelected: selectedMode == EasyAudioMode.realtime,
              isDisabled: _isDisabled,
              isIosOnly: true,
              onTap: () => onModeSelected(EasyAudioMode.realtime),
            ),
          ],
        ),
      ),
    );
  }
}
