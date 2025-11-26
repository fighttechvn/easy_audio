import 'package:flutter/material.dart';

import 'easy_record_callbacks.dart';
import 'record_session_data.dart';

class EasyRecordConfiguration {
  const EasyRecordConfiguration({
    this.onRecordComplete,
    this.onExitConfirmation,
    this.onError,
    this.onStateChange,
    this.onMinimize,
    this.onRestore,
    this.sessionData,
    this.defaultLocale = 'en-US',
    this.title,
    this.allowMinimize = true,
    this.showFloatingWidget = true,
    this.floatingWidgetBuilder,
    this.primaryColor,
    this.backgroundColor,
    this.waveformColor,
    this.enableSpeechToText = true,
    this.autoStartRecording = true,
    this.maxRecordingDuration,
  });

  /// Callback invoked when recording is completed and saved.
  final OnRecordComplete? onRecordComplete;

  /// Callback invoked when user attempts to exit the recording modal.
  /// Return true to allow exit, false to prevent.
  final OnExitConfirmation? onExitConfirmation;

  /// Callback invoked when an error occurs.
  final OnRecordError? onError;

  /// Callback invoked when recording state changes.
  final OnRecordStateChange? onStateChange;

  /// Callback invoked when modal is minimized.
  final OnMinimize? onMinimize;

  /// Callback invoked when modal is restored from minimized state.
  final OnRestore? onRestore;

  /// Session data to associate with this recording.
  /// Can be any data implementing [RecordSessionData].
  final RecordSessionData? sessionData;

  /// Default locale for speech-to-text.
  final String defaultLocale;

  /// Title displayed in the recording modal.
  final String? title;

  /// Whether to allow minimizing the recording modal.
  /// When minimized, a floating widget will be shown.
  final bool allowMinimize;

  /// Whether to show the floating widget when minimized.
  final bool showFloatingWidget;

  /// Custom builder for the floating widget.
  /// If null, the default floating widget will be used.
  final FloatingWidgetBuilder? floatingWidgetBuilder;

  /// Primary color for UI elements.
  /// If null, the theme's primary color will be used.
  final Color? primaryColor;

  /// Background color for the modal.
  /// If null, appropriate color based on theme brightness will be used.
  final Color? backgroundColor;

  /// Color for the waveform visualization.
  final Color? waveformColor;

  /// Whether to enable speech-to-text transcription.
  final bool enableSpeechToText;

  /// Whether to automatically start recording when modal opens.
  final bool autoStartRecording;

  /// Maximum recording duration. Recording will stop when this is reached.
  /// If null, there's no limit.
  final Duration? maxRecordingDuration;

  /// Creates a copy of this configuration with the given fields replaced.
  EasyRecordConfiguration copyWith({
    OnRecordComplete? onRecordComplete,
    OnExitConfirmation? onExitConfirmation,
    OnRecordError? onError,
    OnRecordStateChange? onStateChange,
    OnMinimize? onMinimize,
    OnRestore? onRestore,
    RecordSessionData? sessionData,
    String? defaultLocale,
    String? title,
    bool? allowMinimize,
    bool? showFloatingWidget,
    FloatingWidgetBuilder? floatingWidgetBuilder,
    Color? primaryColor,
    Color? backgroundColor,
    Color? waveformColor,
    bool? enableSpeechToText,
    bool? autoStartRecording,
    Duration? maxRecordingDuration,
  }) {
    return EasyRecordConfiguration(
      onRecordComplete: onRecordComplete ?? this.onRecordComplete,
      onExitConfirmation: onExitConfirmation ?? this.onExitConfirmation,
      onError: onError ?? this.onError,
      onStateChange: onStateChange ?? this.onStateChange,
      onMinimize: onMinimize ?? this.onMinimize,
      onRestore: onRestore ?? this.onRestore,
      sessionData: sessionData ?? this.sessionData,
      defaultLocale: defaultLocale ?? this.defaultLocale,
      title: title ?? this.title,
      allowMinimize: allowMinimize ?? this.allowMinimize,
      showFloatingWidget: showFloatingWidget ?? this.showFloatingWidget,
      floatingWidgetBuilder:
          floatingWidgetBuilder ?? this.floatingWidgetBuilder,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      waveformColor: waveformColor ?? this.waveformColor,
      enableSpeechToText: enableSpeechToText ?? this.enableSpeechToText,
      autoStartRecording: autoStartRecording ?? this.autoStartRecording,
      maxRecordingDuration: maxRecordingDuration ?? this.maxRecordingDuration,
    );
  }

  EasyRecordConfiguration withSessionData(RecordSessionData? sessionData) {
    return copyWith(sessionData: sessionData);
  }

  EasyRecordConfiguration withCallbacks({
    OnRecordComplete? onRecordComplete,
    OnExitConfirmation? onExitConfirmation,
    OnRecordError? onError,
  }) {
    return copyWith(
      onRecordComplete: onRecordComplete,
      onExitConfirmation: onExitConfirmation,
      onError: onError,
    );
  }
}
