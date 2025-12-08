import 'package:flutter/material.dart';

import '../../core/services/pending_recording_service.dart';
import '../../domain/entities/pending_recording_types.dart';
import '../../record_audio_coodinator.dart';

class PendingRecordingRecoveryWidget extends StatefulWidget {
  const PendingRecordingRecoveryWidget({
    super.key,
    required this.userId,
    required this.onRecordingRecovered,
    required this.child,
    this.config = const PendingRecordingDialogConfig(),
    this.checkOnInit = true,
    this.autoCleanupDays = 7,
  });

  /// The current user's ID to filter pending recordings
  final String userId;

  /// Callback when user decides what to do with a pending recording
  final Future<void> Function(
    PendingRecording recording,
    PendingRecordingAction action,
  ) onRecordingRecovered;

  /// The child widget to display
  final Widget child;

  /// Configuration for the recovery dialog
  final PendingRecordingDialogConfig config;

  /// Whether to check for pending recordings on init
  final bool checkOnInit;

  /// Number of days after which old recordings are auto-cleaned
  final int autoCleanupDays;

  @override
  State<PendingRecordingRecoveryWidget> createState() =>
      _PendingRecordingRecoveryWidgetState();
}

class _PendingRecordingRecoveryWidgetState
    extends State<PendingRecordingRecoveryWidget> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    if (widget.checkOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForPendingRecordings();
      });
    }
  }

  @override
  void didUpdateWidget(PendingRecordingRecoveryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check if user changed
    if (oldWidget.userId != widget.userId) {
      _hasChecked = false;
      _checkForPendingRecordings();
    }
  }

  Future<void> _checkForPendingRecordings() async {
    if (_hasChecked) {
      return;
    }
    _hasChecked = true;

    final service = PendingRecordingService.instance;

    // Cleanup old recordings first
    await service.cleanupOldRecordings(
      maxAge: Duration(days: widget.autoCleanupDays),
    );

    // Get pending recordings for this user
    final pendingRecordings = await service.getPendingRecordingsForUser(
      widget.userId,
    );

    if (pendingRecordings.isEmpty) {
      debugPrint(
        '[PendingRecordingRecovery] No pending recordings for user: '
        '${widget.userId}',
      );
      return;
    }

    // Show dialog for each pending recording
    for (final recording in pendingRecordings) {
      if (!mounted) {
        break;
      }

      final result = await context.showPendingRecordingDialog(
        recording: recording,
        config: widget.config,
      );

      if (result != null) {
        await widget.onRecordingRecovered(result.recording, result.action);

        // Handle the recording based on action
        switch (result.action) {
          case PendingRecordingAction.upload:
            // Mark as handled but don't delete file
            // (caller will handle upload and cleanup)
            break;
          case PendingRecordingAction.discard:
            await service.markAsHandled(recording.id, deleteFile: true);
            break;
          case PendingRecordingAction.later:
            // Do nothing, keep in pending list
            break;
        }
      }
    }
  }

  /// Manually trigger a check for pending recordings
  Future<void> checkForPendingRecordings() async {
    _hasChecked = false;
    await _checkForPendingRecordings();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

mixin PendingRecordingCheckMixin<T extends StatefulWidget> on State<T> {
  /// Override this to provide the current user's ID
  String get userId;

  /// Override this to handle when a pending recording is found
  Future<void> onPendingRecordingFound(
    PendingRecording recording,
    PendingRecordingAction action,
  );

  /// Configuration for the dialog
  PendingRecordingDialogConfig get dialogConfig =>
      const PendingRecordingDialogConfig();

  bool _hasCheckedPendingRecordings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForPendingRecordings();
    });
  }

  /// Manually check for pending recordings
  Future<void> checkForPendingRecordings() async {
    if (_hasCheckedPendingRecordings) {
      return;
    }
    _hasCheckedPendingRecordings = true;

    final service = PendingRecordingService.instance;
    final pendingRecordings = await service.getPendingRecordingsForUser(userId);

    if (pendingRecordings.isEmpty || !mounted) {
      return;
    }

    for (final recording in pendingRecordings) {
      if (!mounted) {
        break;
      }

      final result = await context.showPendingRecordingDialog(
        recording: recording,
        config: dialogConfig,
      );

      if (result != null) {
        await onPendingRecordingFound(result.recording, result.action);

        switch (result.action) {
          case PendingRecordingAction.upload:
            // Caller handles upload, then should call markAsHandled
            break;
          case PendingRecordingAction.discard:
            await service.markAsHandled(recording.id, deleteFile: true);
            break;
          case PendingRecordingAction.later:
            // Keep in pending list
            break;
        }
      }
    }
  }

  /// Reset the check flag to allow re-checking
  void resetPendingRecordingCheck() {
    _hasCheckedPendingRecordings = false;
  }
}
