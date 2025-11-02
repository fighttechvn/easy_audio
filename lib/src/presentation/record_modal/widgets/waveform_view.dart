import 'package:flutter/material.dart';

import '../../shared/widgets/waveforms_sound/fixed_wareform.dart';

class WaveformView extends StatelessWidget {
  const WaveformView({
    super.key,
    required this.controller,
    required this.isInitialising,
    this.color,
  });

  final AnimatedWaveformController controller;
  final bool isInitialising;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200] ?? color ?? const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: isInitialising
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Initializing microphone...',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimatedWaveform(
                      divide: 3,
                      controller: controller,
                    ),
                  ),
                ),
                // const SizedBox(height: 24),
                // const FixedWaveform(
                //   waveThickness: 3,
                //   size: Size(double.infinity, 24),
                // ),
              ],
            ),
    );
  }
}
