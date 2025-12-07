import 'package:flutter/material.dart';

import '../../../domain/entities/pending_recording_types.dart';
import 'simple_audio_preview.dart';

export '../../../domain/entities/pending_recording_types.dart';

/// Dialog widget for displaying pending recording recovery options.
class PendingRecordingDialog extends StatefulWidget {
  const PendingRecordingDialog({
    super.key,
    required this.recording,
    required this.config,
  });

  final dynamic recording; // PendingRecording from pending_recording_service
  final PendingRecordingDialogConfig config;

  @override
  State<PendingRecordingDialog> createState() => _PendingRecordingDialogState();
}

class _PendingRecordingDialogState extends State<PendingRecordingDialog> {
  bool _isPreviewExpanded = false;
  bool _isLoading = false;

  String get _formattedDuration {
    final duration = widget.recording.duration as Duration;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _formattedDate {
    final date = widget.recording.startedAt as DateTime;
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
            if ((widget.recording.transcript as String?)?.isNotEmpty ==
                true) ...[
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
          if ((widget.recording.title as String?)?.isNotEmpty == true) ...[
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
                    widget.recording.title as String,
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
    final transcript = (widget.recording.transcript as String?) ?? '';
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
          SimpleAudioPreview(
            filePath: widget.recording.filePath as String,
            duration: widget.recording.duration as Duration,
          ),
        ],
      ],
    );
  }
}
