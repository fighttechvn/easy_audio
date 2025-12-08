import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DownloadProgressDialog extends StatelessWidget {
  const DownloadProgressDialog({
    super.key,
    required this.languageLabel,
    required this.progressListenable,
    required this.onCancel,
  });

  final String languageLabel;
  final ValueListenable<double?> progressListenable;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Downloading model'),
      content: ValueListenableBuilder<double?>(
        valueListenable: progressListenable,
        builder: (context, progress, _) {
          final hasProgress = progress != null;
          final double? progressValue;
          if (hasProgress) {
            final value = progress;
            progressValue =
                value < 0 ? 0.0 : (value > 1 ? 1.0 : value.toDouble());
          } else {
            progressValue = null;
          }
          final percentLabel = hasProgress
              ? () {
                  final percent = progressValue! * 100;
                  final safePercent =
                      percent < 0 ? 0 : (percent > 100 ? 100 : percent);
                  return '${safePercent.toStringAsFixed(0)}%';
                }()
              : 'Downloading...';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The "$languageLabel" model is being downloaded.'),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progressValue),
              const SizedBox(height: 8),
              Text('Process: $percentLabel'),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
