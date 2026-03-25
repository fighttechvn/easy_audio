import 'package:flutter/material.dart';

class RecordAudioTranscriptCard extends StatefulWidget {
  const RecordAudioTranscriptCard({
    super.key,
    required this.text,
    this.emptyText = 'The transcript will be displayed here...',
  });

  final String text;
  final String emptyText;

  @override
  State<RecordAudioTranscriptCard> createState() =>
      _RecordAudioTranscriptCardState();
}

class _RecordAudioTranscriptCardState extends State<RecordAudioTranscriptCard> {
  late final ScrollController _scrollController;
  bool _shouldAutoScrollNextFrame = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant RecordAudioTranscriptCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text.trim() != widget.text.trim()) {
      _shouldAutoScrollNextFrame = _isNearBottom();
      _maybeAutoScrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isNearBottom({double threshold = 48}) {
    if (!_scrollController.hasClients) {
      return true;
    }
    final position = _scrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    return distanceToBottom <= threshold;
  }

  void _maybeAutoScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      if (!_shouldAutoScrollNextFrame) {
        return;
      }
      _shouldAutoScrollNextFrame = false;
      final maxExtent = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        maxExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final combined = widget.text.trim();
    final isEmpty = combined.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Text(
          isEmpty ? widget.emptyText : combined,
          textAlign: isEmpty ? TextAlign.start : TextAlign.start,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isEmpty
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
