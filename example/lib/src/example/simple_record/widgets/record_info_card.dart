import 'package:flutter/material.dart';

class RecordInfoCard extends StatelessWidget {
  const RecordInfoCard({
    super.key,
    required this.selectedLanguageLabel,
  });

  final String selectedLanguageLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Simple API Demo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'This example uses SimpleRecordMixin which requires only 2 methods:\n'
              '• onRecordComplete()\n'
              '• requestPermissions()',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Current locale: $selectedLanguageLabel',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
