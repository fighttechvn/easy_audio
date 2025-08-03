import '../../../record_audio_constants.dart';

class SpeechTextStateUI {
  final String currentLocaleId;
  final int retryInitCount;
  final StateInitSpeechText stateInit;

  const SpeechTextStateUI({
    this.currentLocaleId = 'en-US',
    this.retryInitCount = 0,
    this.stateInit = StateInitSpeechText.none,
  });

  SpeechTextStateUI copyWith({
    String? currentLocaleId,
    int? retryInitCount,
    StateInitSpeechText? stateInit,
  }) {
    return SpeechTextStateUI(
      stateInit: stateInit ?? this.stateInit,
      currentLocaleId: currentLocaleId ?? this.currentLocaleId,
      retryInitCount: retryInitCount ?? this.retryInitCount,
    );
  }

  bool get isCloseFeature => retryInitCount > limitRetryInitSpeechToText;
  bool get isInitSuccess => stateInit == StateInitSpeechText.succeeded;
}
