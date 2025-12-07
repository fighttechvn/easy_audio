import '../../domain/entities/record_data.dart';
import 'easy_audio_localizations.dart';
import 'easy_audio_theme.dart';

class EasyAudioConfig {
  /// Supported locales include:
  /// - 'en-US', 'en-GB' (English)
  /// - 'vi-VN' (Vietnamese)
  /// - 'ja-JP' (Japanese)
  /// - 'zh-CN' (Chinese Simplified)
  /// - See RecordLanguage.supportedLanguages for full list.
  final String defaultLocale;

  /// Whether to show confirmation dialog when user tries to close modal
  /// while recording is in progress.
  ///
  /// Defaults to true.
  final bool confirmOnExit;

  /// Custom theme for audio widgets.
  ///
  /// If not provided, widgets will use the app's default theme.
  final EasyAudioTheme? theme;

  /// Custom localization messages.
  ///
  /// If not provided, English defaults are used.
  /// Use [EasyAudioLocalizations.vi] for Vietnamese.
  final EasyAudioLocalizations localizations;

  /// Callback when recording is complete.
  ///
  /// This is called after the user saves a recording from the modal.
  /// Use this for common post-recording actions like uploading.
  ///
  /// For more complex handling (e.g., different behavior per screen),
  /// use the advanced API with [BaseRecordSessionMixin] instead.
  final Future<void> Function(RecordData result)? onRecordComplete;

  /// Whether to enable crash recovery for pending recordings.
  ///
  /// When enabled, if the app crashes during recording, the recording
  /// will be saved and can be recovered on next app launch.
  ///
  /// Requires [EasyAudio.setUserId] to be called first.
  /// Defaults to true.
  final bool enablePendingRecovery;

  /// Default transcript label prefix.
  ///
  /// This is prepended to recordings as a label.
  /// Defaults to 'Transcript: '.
  final String defaultTranscriptLabel;

  const EasyAudioConfig({
    this.defaultLocale = 'en-US',
    this.confirmOnExit = true,
    this.theme,
    this.localizations = const EasyAudioLocalizations(),
    this.onRecordComplete,
    this.enablePendingRecovery = true,
    this.defaultTranscriptLabel = 'Transcript: ',
  });

  /// Copy with modified values.
  EasyAudioConfig copyWith({
    String? defaultLocale,
    bool? confirmOnExit,
    EasyAudioTheme? theme,
    EasyAudioLocalizations? localizations,
    Future<void> Function(RecordData result)? onRecordComplete,
    bool? enablePendingRecovery,
    String? defaultTranscriptLabel,
  }) {
    return EasyAudioConfig(
      defaultLocale: defaultLocale ?? this.defaultLocale,
      confirmOnExit: confirmOnExit ?? this.confirmOnExit,
      theme: theme ?? this.theme,
      localizations: localizations ?? this.localizations,
      onRecordComplete: onRecordComplete ?? this.onRecordComplete,
      enablePendingRecovery:
          enablePendingRecovery ?? this.enablePendingRecovery,
      defaultTranscriptLabel:
          defaultTranscriptLabel ?? this.defaultTranscriptLabel,
    );
  }
}
