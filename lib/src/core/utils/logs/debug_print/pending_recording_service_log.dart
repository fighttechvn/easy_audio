import '../print_log.dart';

void debugPrintStartedSession(String sessionId, String userId) {
  PrintLog.debug(
    '[PendingRecordingService] Started session: $sessionId '
    'for user: $userId',
  );
}

void debugPrintWarningUpdateSessionNoActive() {
  PrintLog.debug(
    '[PendingRecordingService] WARNING: updateSession called '
    'but no active session',
  );
}

void debugPrintWarningEndSessionNoActive() {
  PrintLog.debug(
    '[PendingRecordingService] WARNING: endSession called '
    'but no active session',
  );
}

void debugPrintEndingSession(String sessionId) {
  PrintLog.debug(
    '[PendingRecordingService] Ending session: $sessionId',
  );
}

void debugPrintDeletedCancelledRecording(String filePath) {
  PrintLog.debug(
    '[PendingRecordingService] Deleted cancelled recording: $filePath',
  );
}

void debugPrintFailedToDeleteFile(Object error) {
  PrintLog.debug(
    '[PendingRecordingService] Failed to delete file: $error',
  );
}

void debugPrintFoundPendingRecordings(int count, String userId) {
  PrintLog.debug(
    '[PendingRecordingService] Found $count pending '
    'recordings for user: $userId',
  );
}

void debugPrintRestoredActiveSession(String id) {
  PrintLog.debug(
    '[PendingRecordingService] Restored active session: $id',
  );
}

void debugPrintFailedToRestoreActiveSession(Object error) {
  PrintLog.debug(
    '[PendingRecordingService] Failed to restore active session: $error',
  );
}

void debugPrintFailedToSaveActiveSession(Object error) {
  PrintLog.debug(
    '[PendingRecordingService] Failed to save active session: $error',
  );
}

void debugPrintFailedToClearActiveSession(Object error) {
  PrintLog.debug(
    '[PendingRecordingService] Failed to clear active session: $error',
  );
}

void debugPrintFailedToGetPendingRecordings(Object error) {
  PrintLog.debug(
    '[PendingRecordingService] Failed to get pending recordings: $error',
  );
}

void debugPrintFailedToAddToPendingList(Object error) {
  PrintLog.debug(
    '[PendingRecordingService] Failed to add to pending list: $error',
  );
}

void debugPrintFailedToUpdatePendingList(Object error) {
  PrintLog.debug(
    '[PendingRecordingService] Failed to update pending list: $error',
  );
}

void debugPrintFailedToRemoveFromPendingList(Object error) {
  PrintLog.debug(
    '[PendingRecordingService] Failed to remove from pending list: $error',
  );
}

void debugPrintFailedToSavePendingList(Object error) {
  PrintLog.debug(
    '[PendingRecordingService] Failed to save pending list: $error',
  );
}

void debugPrintMarkedAsHandled(String id, bool deleted) {
  PrintLog.debug(
    '[PendingRecordingService] Marked as handled: $id '
    '(deleted: $deleted)',
  );
}

void debugPrintCleanedUpOldRecordings(int count) {
  PrintLog.debug(
    '[PendingRecordingService] Cleaned up $count old recordings',
  );
}

void debugPrintMarkedAsUploaded(String id) {
  PrintLog.debug(
    '[PendingRecordingService] Recording successfully uploaded'
    ' and removed: $id',
  );
}
