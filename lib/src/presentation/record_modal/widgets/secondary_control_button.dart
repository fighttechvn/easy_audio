import 'package:flutter/material.dart';

class SecondaryControlButton extends StatelessWidget {
  const SecondaryControlButton({
    required this.icon,
    this.onTap,
    this.isActive = false,
    this.isDisabled = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF0A84FF);
    final bool enabled = !isDisabled && onTap != null;
    final Color baseBackground =
        isActive ? accent.withValues(alpha: 0.16) : Colors.white10;
    final Color effectiveBackground =
        enabled ? baseBackground : baseBackground.withValues(alpha: 0.5);
    final Color baseIconColor = isActive ? accent : Colors.white70;
    final Color effectiveIconColor =
        enabled ? baseIconColor : baseIconColor.withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: 26,
            color: effectiveIconColor,
          ),
        ),
      ),
    );
  }
}

