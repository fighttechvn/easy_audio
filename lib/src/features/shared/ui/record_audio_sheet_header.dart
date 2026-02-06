import 'package:flutter/material.dart';

class RecordAudioSheetHeader extends StatelessWidget {
  const RecordAudioSheetHeader({
    super.key,
    required this.title,
    required this.canStop,
    required this.onClose,
    required this.onStop,
  });

  final String title;
  final bool canStop;

  final Future<void> Function()? onClose;
  final Future<void> Function()? onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languages = title.split('(');
    var langText = title;
    var localText = '';
    if (languages.length > 1) {
      langText = languages[0].trim();
      localText = '(${languages[1]}';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RecordCircleIconButton(icon: Icons.close, onTap: onClose),
        const SizedBox(width: 12),
        Expanded(
          child: Center(
            child: Column(
              children: [
                Text(
                  '$langText ',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    fontSize: 17,
                  ),
                ),
                if (localText.isNotEmpty)
                  Text(
                    localText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _RecordCircleIconButton(
          icon: Icons.check,
          background: Colors.blueAccent,
          iconColor: theme.colorScheme.onPrimary,
          onTap: canStop ? onStop : null,
        ),
      ],
    );
  }
}

class _RecordCircleIconButton extends StatelessWidget {
  const _RecordCircleIconButton({
    required this.icon,
    required this.onTap,
    this.background,
    this.iconColor,
  });

  final IconData icon;
  final Future<void> Function()? onTap;
  final Color? background;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = background ?? Colors.grey[200]!;
    final fg = iconColor ?? theme.colorScheme.onSurface;

    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null ? bg.withValues(alpha: 0.5) : bg,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: onTap == null ? fg.withValues(alpha: 0.4) : fg,
        ),
      ),
    );
  }
}
