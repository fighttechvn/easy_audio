import '../../core/services/pending_recording_service.dart';

/// Result from the pending recording dialog.
enum PendingRecordingAction {
  /// User chose to upload the recording
  upload,

  /// User chose to discard the recording
  discard,

  /// User chose to handle it later
  later,
}

/// Result data from pending recording dialog.
class PendingRecordingResult {
  const PendingRecordingResult({
    required this.action,
    required this.recording,
  });

  final PendingRecordingAction action;
  final PendingRecording recording;
}

/// Configuration for the pending recording recovery dialog.
class PendingRecordingDialogConfig {
  const PendingRecordingDialogConfig({
    this.title = 'Unfinished Recording Found',
    this.message = 'We found a recording that was interrupted. '
        'Would you like to upload it or discard?',
    this.uploadButtonText = 'Upload',
    this.discardButtonText = 'Discard',
    this.previewButtonText = 'Preview',
    this.cancelButtonText = 'Later',
    this.showPreview = true,
    this.showCancel = true,
    this.barrierDismissible = false,
  });

  final String title;
  final String message;
  final String uploadButtonText;
  final String discardButtonText;
  final String previewButtonText;
  final String cancelButtonText;
  final bool showPreview;
  final bool showCancel;
  final bool barrierDismissible;
}
