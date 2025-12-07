import '../print_log.dart';

void debugPrintMicrophonePermissionDenied(Object error) {
  PrintLog.debug('[EasyAudioController] Microphone permission denied: $error');
}

void debugPrintRecorderStateError(Object error) {
  PrintLog.debug('[EasyAudioController] Recorder state error: $error');
}

void debugPrintFailedToStartRecording(Object error) {
  PrintLog.debug('[EasyAudioController] Failed to start recording: $error');
}
