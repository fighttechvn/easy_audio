import 'package:flutter/material.dart';

import '../../core/services/pending_recording_service.dart';

/// Configuration for the pending recording recovery dialog
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

/// Result from the pending recording dialog
enum PendingRecordingAction {
  /// User chose to upload the recording
  upload,

  /// User chose to discard the recording
  discard,

  /// User chose to handle it later
  later,
}

/// Result data from pending recording dialog
class PendingRecordingResult {
  const PendingRecordingResult({
    required this.action,
    required this.recording,
  });

  final PendingRecordingAction action;
  final PendingRecording recording;
}

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

      final result = await _showRecoveryDialog(recording);
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

  Future<PendingRecordingResult?> _showRecoveryDialog(
    PendingRecording recording,
  ) async {
    return showDialog<PendingRecordingResult>(
      context: context,
      barrierDismissible: widget.config.barrierDismissible,
      builder: (dialogContext) => _PendingRecordingDialog(
        recording: recording,
        config: widget.config,
      ),
    );
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

/// Internal dialog widget for displaying pending recording recovery options
class _PendingRecordingDialog extends StatefulWidget {
  const _PendingRecordingDialog({
    required this.recording,
    required this.config,
  });

  final PendingRecording recording;
  final PendingRecordingDialogConfig config;

  @override
  State<_PendingRecordingDialog> createState() =>
      _PendingRecordingDialogState();
}

class _PendingRecordingDialogState extends State<_PendingRecordingDialog> {
  bool _isPreviewExpanded = false;
  bool _isLoading = false;

  String get _formattedDuration {
    final duration = widget.recording.duration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _formattedDate {
    final date = widget.recording.startedAt;
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleAction(PendingRecordingAction action) async {
    setState(() => _isLoading = true);

    Navigator.of(context).pop(PendingRecordingResult(
      action: action,
      recording: widget.recording,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = widget.config;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              config.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.message),
            const SizedBox(height: 16),
            _buildRecordingInfo(theme),
            if (widget.recording.transcript?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildTranscriptPreview(theme),
            ],
            if (config.showPreview) ...[
              const SizedBox(height: 12),
              _buildAudioPreview(theme),
            ],
          ],
        ),
      ),
      actions: [
        if (config.showCancel)
          TextButton(
            onPressed: _isLoading
                ? null
                : () => _handleAction(PendingRecordingAction.later),
            child: Text(config.cancelButtonText),
          ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () => _handleAction(PendingRecordingAction.discard),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          child: Text(config.discardButtonText),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () => _handleAction(PendingRecordingAction.upload),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(config.uploadButtonText),
        ),
      ],
    );
  }

  Widget _buildRecordingInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.recording.title?.isNotEmpty == true) ...[
            Row(
              children: [
                Icon(
                  Icons.label_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.recording.title!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                _formattedDate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formattedDuration,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptPreview(ThemeData theme) {
    final transcript = widget.recording.transcript ?? '';
    final previewText = transcript.length > 150
        ? '${transcript.substring(0, 150)}...'
        : transcript;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_snippet_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Transcript Preview',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            previewText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() => _isPreviewExpanded = !_isPreviewExpanded);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  _isPreviewExpanded
                      ? Icons.expand_less
                      : Icons.play_circle_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _isPreviewExpanded
                      ? 'Hide Preview'
                      : widget.config.previewButtonText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isPreviewExpanded) ...[
          const SizedBox(height: 8),
          _SimpleAudioPreview(
            filePath: widget.recording.filePath,
            duration: widget.recording.duration,
          ),
        ],
      ],
    );
  }
}

/// Simple audio preview widget for pending recordings
class _SimpleAudioPreview extends StatelessWidget {
  const _SimpleAudioPreview({
    required this.filePath,
    required this.duration,
  });

  final String filePath;
  final Duration duration;

  String get _formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.audio_file,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Recording',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: $_formattedDuration',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<PendingRecordingResult?> showPendingRecordingDialog({
  required BuildContext context,
  required PendingRecording recording,
  PendingRecordingDialogConfig config = const PendingRecordingDialogConfig(),
}) {
  return showDialog<PendingRecordingResult>(
    context: context,
    barrierDismissible: config.barrierDismissible,
    builder: (dialogContext) => _PendingRecordingDialog(
      recording: recording,
      config: config,
    ),
  );
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

      final result = await showPendingRecordingDialog(
        context: context,
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
