import '../print_log.dart';

void debugPrintStartLocale(String resolvedLocale) {
  PrintLog.debug('[SpeechToTextUsecase] start locale: $resolvedLocale');
}

void debugPrintStartedPendingRecordingSession(String userId) {
  PrintLog.debug(
    '[SpeechToTextUsecase] Started pending recording session '
    'for user: $userId',
  );
}

void debugPrintFailedToStartPendingSession(Object e) {
  PrintLog.debug(
    '[SpeechToTextUsecase] Failed to start pending session: $e',
  );
}

void debugPrintFailedToUpdatePendingSession(Object e) {
  PrintLog.debug(
    '[SpeechToTextUsecase] Failed to update pending session: $e',
  );
}

void debugPrintEndedPendingRecordingSession() {
  PrintLog.debug('[SpeechToTextUsecase] Ended pending recording session');
}

void debugPrintFailedToEndPendingSession(Object e) {
  PrintLog.debug('[SpeechToTextUsecase] Failed to end pending session: $e');
}

void debugPrintCancelledPendingRecordingSession() {
  PrintLog.debug(
    '[SpeechToTextUsecase] Cancelled pending recording session',
  );
}

void debugPrintFailedToCancelPendingSession(Object e) {
  PrintLog.debug(
    '[SpeechToTextUsecase] Failed to cancel pending session: $e',
  );
}

void debugPrintSpeechRecognitionNotSupported(
  Object error,
  StackTrace stackTrace,
) {
  PrintLog.debug(
    '[SpeechToTextUsecase] Speech recognition not supported: $error',
  );
  PrintLog.debug(stackTrace.toString());
}

void debugPrintMicrophonePermissionDenied(
  Object error,
  StackTrace stackTrace,
) {
  PrintLog.debug('[SpeechToTextUsecase] Microphone permission denied: $error');
  PrintLog.debug(stackTrace.toString());
}

void debugPrintFailedToInitialiseSpeechPipeline(
  Object error,
  StackTrace stackTrace,
) {
  PrintLog.debug(
    '[SpeechToTextUsecase] Failed to initialise speech pipeline: $error',
  );
  PrintLog.debug(stackTrace.toString());
}

void debugPrintFailedToStartSpeechPipeline(
  Object error,
  StackTrace stackTrace,
) {
  PrintLog.debug(
    '[SpeechToTextUsecase] Failed to start speech pipeline: $error',
  );
  PrintLog.debug(stackTrace.toString());
}

void debugPrintSpeechPipelineError(Object error, StackTrace stackTrace) {
  PrintLog.debug('[SpeechToTextUsecase] Speech pipeline error: $error');
  PrintLog.debug(stackTrace.toString());
}
