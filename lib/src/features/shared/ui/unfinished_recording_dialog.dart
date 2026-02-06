import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/utils/datetime_ext.dart';
import '../../../domain/entities/pending_recording.dart';

class UnfinishedRecordingDialog extends StatelessWidget {
  const UnfinishedRecordingDialog({
    super.key,
    required this.record,
    required this.languageDisplayName,
    required this.onLater,
    required this.onDiscard,
    required this.onUpload,
    required this.canPreview,
    this.onPreview,
  });

  final PendingRecording record;
  final String languageDisplayName;

  final VoidCallback onLater;
  final VoidCallback onDiscard;
  final VoidCallback onUpload;

  final bool canPreview;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseBodyColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
    final bodyColor85 = baseBodyColor.withAlpha(217);
    final dialogBg =
        theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface;

    final patientName = record.patientName?.trim();
    final clinicName = record.clinicName?.trim();

    final transcript = record.content.trim();
    final hasTranscript = transcript.isNotEmpty;

    final dt = record.createdAt;
    final dateTimeText = dt.formatMonthDayYearTime();

    final durationText = record.formattedDuration ?? '--:--';

    final sizeText = record.fileSizeText;

    final canPreview = this.canPreview && File(record.filePath).existsSync();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF4B400),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unfinished Recording',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'A previous recording was interrupted.\n'
                'Would you like to upload it or discard?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyColor85,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),

              // Selected item card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F3F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 18,
                        color: Color(0xFF9E9E9E),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Language: $languageDisplayName',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((patientName ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Patient: $patientName',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                            if ((clinicName ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Clinic: $clinicName',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                            if (record.bookingLine != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                record.bookingLine!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dateTimeText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  durationText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  sizeText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (hasTranscript) ...[
                const SizedBox(height: 12),

                // Transcript preview
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE7E7EA)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.subject_outlined,
                              size: 18,
                              color: Color(0xFFB0B0B0),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Transcript Preview',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB0B0B0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          transcript,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF9AA0A6),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],

              // Preview action
              InkWell(
                onTap: !canPreview ? null : onPreview,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE7E7EA)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 18,
                        color: canPreview
                            ? const Color(0xFFB0B0B0)
                            : const Color(0xFFDDDDDD),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Preview',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: canPreview
                                ? const Color(0xFFB0B0B0)
                                : const Color(0xFFDDDDDD),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onLater, child: const Text('Later')),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: onDiscard,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                    ),
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: onUpload,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Upload'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
