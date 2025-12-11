import '../print_log.dart';

void debugPrintStartingNewSession(String locale, bool hasTitle) {
  PrintLog.debug(
    '🎙️ [SessionManager] Starting new session - '
    'locale: $locale, '
    'hasTitle: $hasTitle',
  );
}

void debugPrintSessionStartedSuccessfully() {
  PrintLog.debug('🎙️ [SessionManager] Session started successfully');
}

void debugPrintWarningMinimizeSessionNoActiveSession() {
  PrintLog.debug(
    '🎙️ [SessionManager] WARNING: minimizeSession called but '
    'no active session!',
  );
}

void debugPrintMinimizingSession(
  bool isPipelineActive,
  bool hasCallback,
  int contentLength,
) {
  PrintLog.debug(
    '🎙️ [SessionManager] Minimizing session - '
    'isPipelineActive: $isPipelineActive, '
    'hasCallback: $hasCallback, '
    'contentLength: $contentLength',
  );
}

void debugPrintSessionMinimizedEmitted() {
  PrintLog.debug('🎙️ [SessionManager] Session minimized, emitted to stream');
}

void debugPrintWarningRestoreSessionNoActiveSession() {
  PrintLog.debug(
    '🎙️ [SessionManager] WARNING: restoreSession called but '
    'no active session!',
  );
}

void debugPrintRestoringSession(
  bool isPipelineActive,
  bool hasCallback,
  int contentLength,
  Type? blocStateType,
) {
  PrintLog.debug(
    '🎙️ [SessionManager] Restoring session - '
    'isPipelineActive: $isPipelineActive, '
    'hasCallback: $hasCallback, '
    'contentLength: $contentLength, '
    'blocState: $blocStateType',
  );
}

void debugPrintSessionRestoredEmitted() {
  PrintLog.debug('🎙️ [SessionManager] Session restored, emitted to stream');
}

void debugPrintUpdateContentCallbackChanged(bool wasSet, bool isSet) {
  PrintLog.debug(
    '🎙️ [SessionManager] Update content callback changed - '
    'from: ${wasSet ? "set" : "null"}, '
    'to: ${isSet ? "set" : "null"}',
  );
}

void debugPrintPipelineStateChanged(
  bool wasActive,
  bool active,
  bool hasCallback,
) {
  PrintLog.debug(
    '🎙️ [SessionManager] Pipeline state changed - '
    'from: $wasActive, '
    'to: $active, '
    'hasCallback: $hasCallback',
  );
}

void debugPrintCheckingPipelineRestartNeeded(
  bool isPipelineActive,
  bool hasCallback,
  bool blocClosed,
) {
  PrintLog.debug(
    '🎙️ [SessionManager] Checking if pipeline restart needed - '
    'isPipelineActive: $isPipelineActive, '
    'hasCallback: $hasCallback, '
    'blocClosed: $blocClosed',
  );
}

void debugPrintRestartingPipelineWithSavedCallback() {
  PrintLog.debug(
    '🎙️ [SessionManager] Restarting pipeline with saved callback',
  );
}

void debugPrintPipelineRestartedSuccessfully() {
  PrintLog.debug('🎙️ [SessionManager] Pipeline restarted successfully');
}

void debugPrintCannotRestartPipelineBlocClosed() {
  PrintLog.debug(
    '🎙️ [SessionManager] ERROR: Cannot restart pipeline - '
    'bloc is closed',
  );
}

void debugPrintPipelineRestartNotNeeded() {
  PrintLog.debug('🎙️ [SessionManager] Pipeline restart not needed');
}

void debugPrintEndingSession(
  bool disposeResources,
  bool hasActiveSession,
  bool isPipelineActive,
) {
  PrintLog.debug(
    '🎙️ [SessionManager] Ending session - '
    'disposeResources: $disposeResources, '
    'hadActiveSession: $hasActiveSession, '
    'isPipelineActive: $isPipelineActive',
  );
}

void debugPrintClosingBloc() {
  PrintLog.debug('🎙️ [SessionManager] Closing bloc');
}

void debugPrintSessionEndedAndCleanedUp() {
  PrintLog.debug('🎙️ [SessionManager] Session ended and cleaned up');
}
