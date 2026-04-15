import 'package:floating_draggable_widget/floating_draggable_widget.dart';
import 'package:flutter/material.dart';

class CustomerRecordFloatingOverlay extends StatelessWidget {
  const CustomerRecordFloatingOverlay({
    super.key,
    required this.child,
    required this.floatingWidget,
  });

  final Widget child;
  final Widget floatingWidget;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return FloatingDraggableWidget(
      mainScreenWidget: child,
      floatingWidgetWidth: 56,
      floatingWidgetHeight: 56,
      dx: size.width - 60,
      dy: size.height - 120,
      autoAlign: true,
      floatingWidget: floatingWidget,
    );
  }
}

class CustomerRecordFloatingBadge extends StatelessWidget {
  const CustomerRecordFloatingBadge({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor,
    this.shape,
  });

  final Widget child;
  final Future<void> Function() onTap;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: backgroundColor ?? theme.colorScheme.primary,
      shape: shape ?? const CircleBorder(),
      child: InkWell(
        customBorder: shape ?? const CircleBorder(),
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}

class CustomerRecordRecordingBadgeContent extends StatelessWidget {
  const CustomerRecordRecordingBadgeContent({
    super.key,
    required this.blinkOn,
    required this.elapsedText,
    this.styleRec,
    this.style,
    this.color,
  });

  final bool blinkOn;
  final String elapsedText;
  final TextStyle? styleRec;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: blinkOn ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color ?? Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'REC',
              style:
                  styleRec ??
                  theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            elapsedText,
            style:
                style ??
                theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
          ),
        ),
      ],
    );
  }
}

class CustomerRecordUploadBadgeContent extends StatelessWidget {
  const CustomerRecordUploadBadgeContent({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            color: theme.colorScheme.onPrimary,
            backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
          ),
        ),
        Text(
          '${(progress * 100).round()}%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
