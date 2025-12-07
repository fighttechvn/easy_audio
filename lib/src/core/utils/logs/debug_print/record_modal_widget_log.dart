import '../print_log.dart';

void debugPrintCannotStopRecordBlocClosed() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] WARNING: Cannot stop record - '
    'bloc is closed',
  );
}

void debugPrintStopRecord(bool save) {
  PrintLog.debug('🎙️ [RecordModalWidget] Stopping record - save: $save');
}

void debugPrintStartingPipeline() {
  PrintLog.debug('🎙️ [RecordModalWidget] Starting pipeline...');
}

void debugPrintCannotStartPipelineWidgetNotMounted() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] WARNING: Cannot start pipeline - '
    'widget not mounted',
  );
}

void debugPrintCannotStartPipelineBlocClosed() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] ERROR: Cannot start pipeline - '
    'bloc is closed',
  );
}

void debugPrintAddingStartRecordEvent(Type blocStateType) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Adding StartRecordEvent to bloc - '
    'blocState: $blocStateType',
  );
}

void debugPrintCallingCurrentCallbackFromSessionManager() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Calling current callback'
    ' from session manager',
  );
}

void debugPrintWarningNoCallbackInSessionManager() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] WARNING: No callback '
    'in session manager',
  );
}

void debugPrintPipelineStarted() {
  PrintLog.debug('🎙️ [RecordModalWidget] Pipeline started');
}

void debugPrintBlocStateChanged(Type stateType) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Bloc state changed: $stateType',
  );
}

void debugPrintInitFailedClosingModal(dynamic error) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Init failed, closing modal - '
    'error: $error',
  );
}

void debugPrintInitSucceededStartingPipeline() {
  PrintLog.debug('🎙️ [RecordModalWidget] Init succeeded, starting pipeline');
}

void debugPrintRecordingStarted() {
  PrintLog.debug('🎙️ [RecordModalWidget] Recording started');
}

void debugPrintRecordingResumed() {
  PrintLog.debug('🎙️ [RecordModalWidget] Recording resumed');
}

void debugPrintRecordingStopped(bool isSave, bool hasFilePath) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Recording stopped - '
    'isSave: $isSave, '
    'hasFilePath: $hasFilePath',
  );
}

void debugPrintRecordingError(String message) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Recording error - '
    'message: $message',
  );
}

void debugPrintInitState(bool restoreFromSession, bool hasActiveSession) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] initState - '
    'restoreFromSession: $restoreFromSession, '
    'hasActiveSession: $hasActiveSession',
  );
}

void debugPrintRestoredContentToController(int length) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Restored content to controller - '
    'length: $length',
  );
}

void debugPrintRestoringFromSession(bool isPipelineActive, int contentLength) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Restoring from session - '
    'isPipelineActive: $isPipelineActive, '
    'contentLength: $contentLength',
  );
}

void debugPrintPipelineWillUseNewCallback() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Pipeline will use new callback '
    'via session manager',
  );
}

void debugPrintStartingNewRecordingSession() {
  PrintLog.debug('🎙️ [RecordModalWidget] Starting new recording session');
}

void debugPrintWarningWidgetNotMountedInPostFrameCallback() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] WARNING: Widget not mounted in '
    'post frame callback',
  );
}

void debugPrintWarningBlocClosedInPostFrameCallback() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] WARNING: Bloc closed in '
    'post frame callback',
  );
}

void debugPrintNewSessionInitializedStartingPipeline() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] New session initialized, '
    'starting pipeline',
  );
}

void debugPrintDispose(bool hasActiveSession, bool isMinimized) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] dispose - '
    'hasActiveSession: $hasActiveSession, '
    'isMinimized: $isMinimized',
  );
}

void debugPrintSessionEndingClearingCallback() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Session ending, clearing callback',
  );
}

void debugPrintSessionMinimizedKeepingCallback() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Session minimized, keeping callback',
  );
}

void debugPrintCannotTogglePauseResume(bool supportsPauseResume, bool mounted) {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] Cannot toggle pause/resume - '
    'supportsPauseResume: $supportsPauseResume, mounted: $mounted',
  );
}

void debugPrintWarningCannotTogglePauseResumeBlocClosed() {
  PrintLog.debug(
    '🎙️ [RecordModalWidget] WARNING: Cannot toggle pause/resume - '
    'bloc is closed',
  );
}
