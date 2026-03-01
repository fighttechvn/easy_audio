import 'package:flutter/material.dart';

class ControlButtonWidget extends StatelessWidget {
  const ControlButtonWidget({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.size,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.7)],
                )
              : null,
          color: isPrimary ? null : color.withValues(alpha: 0.2),
          border: isPrimary
              ? null
              : Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : color,
          size: size * 0.45,
        ),
      ),
    );
  }
}
