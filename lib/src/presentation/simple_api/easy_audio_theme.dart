import 'package:flutter/material.dart';

class EasyAudioTheme {
  /// Primary color for buttons and active states.
  final Color? primaryColor;

  /// Background color for modal and widgets.
  final Color? backgroundColor;

  /// Color for waveform visualization.
  final Color? waveformColor;

  /// Color for inactive waveform bars.
  final Color? waveformInactiveColor;

  /// Primary text color.
  final Color? textColor;

  /// Secondary text color (for timestamps, subtitles).
  final Color? secondaryTextColor;

  /// Text style for titles.
  final TextStyle? titleStyle;

  /// Text style for time displays.
  final TextStyle? timeStyle;

  /// Text style for body text.
  final TextStyle? bodyStyle;

  /// Border radius for modal bottom sheet.
  final BorderRadius? modalBorderRadius;

  /// Padding for modal content.
  final EdgeInsets? modalPadding;

  /// Size of control buttons (play, pause, etc.).
  final double? buttonSize;

  /// Color for icon buttons.
  final Color? iconColor;

  /// Color for disabled icon buttons.
  final Color? disabledIconColor;

  const EasyAudioTheme({
    this.primaryColor,
    this.backgroundColor,
    this.waveformColor,
    this.waveformInactiveColor,
    this.textColor,
    this.secondaryTextColor,
    this.titleStyle,
    this.timeStyle,
    this.bodyStyle,
    this.modalBorderRadius,
    this.modalPadding,
    this.buttonSize,
    this.iconColor,
    this.disabledIconColor,
  });

  /// Merge with another theme, preferring non-null values from [other].
  EasyAudioTheme merge(EasyAudioTheme? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      primaryColor: other.primaryColor,
      backgroundColor: other.backgroundColor,
      waveformColor: other.waveformColor,
      waveformInactiveColor: other.waveformInactiveColor,
      textColor: other.textColor,
      secondaryTextColor: other.secondaryTextColor,
      titleStyle: other.titleStyle,
      timeStyle: other.timeStyle,
      bodyStyle: other.bodyStyle,
      modalBorderRadius: other.modalBorderRadius,
      modalPadding: other.modalPadding,
      buttonSize: other.buttonSize,
      iconColor: other.iconColor,
      disabledIconColor: other.disabledIconColor,
    );
  }

  /// Copy with modified values.
  EasyAudioTheme copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? waveformColor,
    Color? waveformInactiveColor,
    Color? textColor,
    Color? secondaryTextColor,
    TextStyle? titleStyle,
    TextStyle? timeStyle,
    TextStyle? bodyStyle,
    BorderRadius? modalBorderRadius,
    EdgeInsets? modalPadding,
    double? buttonSize,
    Color? iconColor,
    Color? disabledIconColor,
  }) {
    return EasyAudioTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      waveformColor: waveformColor ?? this.waveformColor,
      waveformInactiveColor:
          waveformInactiveColor ?? this.waveformInactiveColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      titleStyle: titleStyle ?? this.titleStyle,
      timeStyle: timeStyle ?? this.timeStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      modalBorderRadius: modalBorderRadius ?? this.modalBorderRadius,
      modalPadding: modalPadding ?? this.modalPadding,
      buttonSize: buttonSize ?? this.buttonSize,
      iconColor: iconColor ?? this.iconColor,
      disabledIconColor: disabledIconColor ?? this.disabledIconColor,
    );
  }

  /// Create theme from Flutter's ColorScheme.
  factory EasyAudioTheme.fromColorScheme(ColorScheme scheme) {
    return EasyAudioTheme(
      primaryColor: scheme.primary,
      backgroundColor: scheme.surface,
      waveformColor: scheme.primary.withValues(alpha: 0.7),
      waveformInactiveColor: scheme.onSurface.withValues(alpha: 0.2),
      textColor: scheme.onSurface,
      secondaryTextColor: scheme.onSurface.withValues(alpha: 0.6),
      iconColor: scheme.onSurface,
      disabledIconColor: scheme.onSurface.withValues(alpha: 0.38),
    );
  }
}
