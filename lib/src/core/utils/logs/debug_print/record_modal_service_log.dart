import '../print_log.dart';

void debugPrintInitialized() {
  PrintLog.debug('[RecordModalService] Initialized with navigator key');
}

void debugPrintSetCurrentUserId(String? userId) {
  PrintLog.debug('[RecordModalService] Set current user ID: $userId');
}

void debugPrintNavigatorKeyNotInitialized() {
  PrintLog.debug(
    '[RecordModalService] ERROR: Navigator key not initialized! '
    'Cannot open modal.',
  );
}

void debugPrintContextNotAvailable() {
  PrintLog.debug(
    '[RecordModalService] ERROR: Cannot open modal - '
    'context not available or not mounted',
  );
}

void debugPrintRestoringExistingSession() {
  PrintLog.debug(
    '[RecordModalService] Same appointment detected, '
    'restoring existing session',
  );
}

void debugPrintDifferentAppointmentDetected() {
  PrintLog.debug('[RecordModalService] Different appointment detected');
}

void debugPrintUserChoseToRestore() {
  PrintLog.debug(
    '[RecordModalService] User chose to restore existing session',
  );
}

void debugPrintUserCancelledOpening() {
  PrintLog.debug('[RecordModalService] User cancelled opening new modal');
}

void debugPrintOpeningModal(bool restoreFromSession) {
  PrintLog.debug(
    '[RecordModalService] Opening modal - '
    'restoreFromSession: $restoreFromSession, ',
  );
}

void debugPrintWarningRestoreNoActiveSession() {
  PrintLog.debug(
    '[RecordModalService] WARNING: Restore requested but no active '
    'session found. Creating new session instead.',
  );
}

void debugPrintSessionExistsButBlocNull() {
  PrintLog.debug(
    '[RecordModalService] ERROR: Session exists but bloc is null! '
    'Creating new session.',
  );
}

void debugPrintRestoringFromExistingSession(
  Type blocState,
  bool isPipelineActive,
) {
  PrintLog.debug(
    '[RecordModalService] Restoring from existing session - '
    'bloc state: $blocState, '
    'isPipelineActive: $isPipelineActive',
  );
}

void debugPrintCreatedNewSession(Type blocState) {
  PrintLog.debug(
    '[RecordModalService] Created new session - bloc state: $blocState',
  );
}

void debugPrintShowingModalBottomSheet() {
  PrintLog.debug('[RecordModalService] Showing modal bottom sheet...');
}

void debugPrintUserClickedCloseButton() {
  PrintLog.debug('[RecordModalService] User clicked close button');
}

void debugPrintUserConfirmedClose() {
  PrintLog.debug('[RecordModalService] User confirmed close');
}

void debugPrintUserCancelledClose() {
  PrintLog.debug('[RecordModalService] User cancelled close');
}

void debugPrintMinimizeButtonClicked() {
  PrintLog.debug('[RecordModalService] Minimize button clicked');
}

void debugPrintModalBottomSheetCompleted() {
  PrintLog.debug('[RecordModalService] Modal bottom sheet completed');
}

void debugPrintFailedToShowModal(Object error, StackTrace stackTrace) {
  PrintLog.debug(
    '[RecordModalService] ERROR: Failed to show modal bottom sheet',
  );
  PrintLog.debug('[RecordModalService] Error: $error');
  PrintLog.debug('[RecordModalService] StackTrace: $stackTrace');
}

void debugPrintModalClosed(
  dynamic result,
  bool userExplicitlyClosed,
  bool isMinimized,
  bool hasActiveSession,
) {
  PrintLog.debug(
    '[RecordModalService] Modal closed - '
    'result: ${result != null ? "RecordData" : "null"}, '
    'userExplicitlyClosed: $userExplicitlyClosed, '
    'isMinimized: $isMinimized, '
    'hasActiveSession: $hasActiveSession',
  );
}

void debugPrintUserSavedRecording(Duration? duration, int contentLength) {
  PrintLog.debug(
    '[RecordModalService] User saved recording - '
    'duration: $duration, '
    'contentLength: $contentLength',
  );
}

void debugPrintUserCancelledEndingSession() {
  PrintLog.debug('[RecordModalService] User cancelled, ending session');
}

void debugPrintUserMinimizedKeepingSession(bool isPipelineActive) {
  PrintLog.debug(
    '[RecordModalService] User minimized, keeping session alive - '
    'isPipelineActive: $isPipelineActive',
  );
}

void debugPrintUserDismissedModalMinimizing() {
  PrintLog.debug('[RecordModalService] User dismissed modal, minimizing');
}

void debugPrintCloseModalCalled(bool hasOpenModal) {
  PrintLog.debug(
    '[RecordModalService] closeModal called - '
    'hasOpenModal: $hasOpenModal',
  );
}

void debugPrintWarningCloseModalNoModal() {
  PrintLog.debug(
    '[RecordModalService] WARNING: closeModal called but '
    'no modal is open',
  );
}

void debugPrintCannotCloseModalNavigatorKeyNull() {
  PrintLog.debug(
    '[RecordModalService] ERROR: Cannot close modal - '
    'navigator key is null',
  );
}

void debugPrintCannotCloseModalContextNull() {
  PrintLog.debug(
    '[RecordModalService] ERROR: Cannot close modal - '
    'context is null',
  );
}

void debugPrintCannotCloseModalContextNotMounted() {
  PrintLog.debug(
    '[RecordModalService] ERROR: Cannot close modal - '
    'context not mounted',
  );
}

void debugPrintModalClosedProgrammatically() {
  PrintLog.debug('[RecordModalService] Modal closed programmatically');
}

void debugPrintFailedToCloseModal(Object error, StackTrace stackTrace) {
  PrintLog.debug('[RecordModalService] ERROR: Failed to close modal');
  PrintLog.debug('[RecordModalService] Error: $error');
  PrintLog.debug('[RecordModalService] StackTrace: $stackTrace');
}
