import 'package:flutter/material.dart';

class RecordBottomBar extends StatelessWidget {
  const RecordBottomBar({super.key, required this.onTapRecord});

  final VoidCallback onTapRecord;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12, top: 8),
      child: SizedBox(
        height: 72,
        child: Center(
          child: InkResponse(
            onTap: onTapRecord,
            radius: 28,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(48),
              ),
              child: Icon(
                Icons.mic,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
