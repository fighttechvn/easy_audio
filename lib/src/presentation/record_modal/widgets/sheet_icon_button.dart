import 'package:flutter/material.dart';

class SheetIconButton extends StatelessWidget {
  const SheetIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.backgroundColor = Colors.white10,
    this.iconColor = Colors.white,
    this.isLoading = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color backgroundColor;
  final Color iconColor;
  final bool isLoading;

  factory SheetIconButton.progressAware({
    Key? key,
    required IconData icon,
    required VoidCallback? onTap,
    String? tooltip,
    Color backgroundColor = const Color(0xFF0A84FF),
    Color iconColor = Colors.white,
    required bool isLoading,
  }) {
    return SheetIconButton(
      key: key,
      icon: icon,
      onTap: onTap,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      isLoading: isLoading,
    );
  }

  bool get _isEnabled => onTap != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: 46,
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: _isEnabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isEnabled
                  ? backgroundColor
                  : backgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.brightnessOf(context) == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    )
                  : Icon(
                      icon,
                      color: _isEnabled ? iconColor : Colors.white30,
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }
    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}
