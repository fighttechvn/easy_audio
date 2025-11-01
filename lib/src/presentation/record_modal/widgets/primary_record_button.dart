import 'package:flutter/material.dart';

class PrimaryRecordButton extends StatelessWidget {
  const PrimaryRecordButton({
    required this.isPaused,
    required this.isEnabled,
    required this.isLoading,
    required this.useStopIcon,
    required this.onTap,
    super.key,
  });

  final bool isPaused;
  final bool isEnabled;
  final bool isLoading;
  final bool useStopIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = useStopIcon
        ? const Color(0xFFFF453A)
        : (isPaused ? const Color(0xFF0A84FF) : const Color(0xFFFF453A));
    final IconData icon = useStopIcon
        ? Icons.stop_rounded
        : (isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded);

    return GestureDetector(
      onTap: (!isEnabled || isLoading) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 148,
        height: 68,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF2C2C2E) : Colors.white10,
          borderRadius: BorderRadius.circular(40),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Center(
          child: Container(
            width: 96,
            height: 52,
            decoration: BoxDecoration(
              color: (isEnabled && !isLoading) ? activeColor : Colors.white24,
              borderRadius: BorderRadius.circular(32),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
        ),
      ),
    );
  }
}

