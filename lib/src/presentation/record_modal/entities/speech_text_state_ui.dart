import '../../../record_audio_constants.dart';

class SpeechTextStateUI {
  final String currentLocaleId;
  final int retryInitCount;
  final StateInitSpeechText stateInit;
  final void Function(String)? callbackToText;

  final DateTime? recordingStartedAt;
  final Duration totalPausedDuration;
  final DateTime? pausedAt;

  const SpeechTextStateUI({
    this.currentLocaleId = 'en-US',
    this.retryInitCount = 0,
    this.stateInit = StateInitSpeechText.none,
    this.callbackToText,
    this.recordingStartedAt,
    this.totalPausedDuration = Duration.zero,
    this.pausedAt,
  });

  SpeechTextStateUI copyWith({
    String? currentLocaleId,
    int? retryInitCount,
    StateInitSpeechText? stateInit,
    void Function(String)? callbackToText,
    DateTime? recordingStartedAt,
    Duration? totalPausedDuration,
    DateTime? pausedAt,
  }) {
    return SpeechTextStateUI(
      stateInit: stateInit ?? this.stateInit,
      currentLocaleId: currentLocaleId ?? this.currentLocaleId,
      retryInitCount: retryInitCount ?? this.retryInitCount,
      callbackToText: callbackToText ?? this.callbackToText,
      recordingStartedAt: recordingStartedAt ?? this.recordingStartedAt,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      pausedAt: pausedAt ?? this.pausedAt,
    );
  }

  bool get isCloseFeature => retryInitCount > limitRetryInitSpeechToText;
  bool get isInitSuccess => stateInit == StateInitSpeechText.succeeded;
}
