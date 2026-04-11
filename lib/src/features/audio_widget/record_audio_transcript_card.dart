import 'package:flutter/material.dart';

class RecordAudioTranscriptCard extends StatefulWidget {
  const RecordAudioTranscriptCard({
    super.key,
    required this.text,
    this.emptyText = 'The transcript will be displayed here...',
    this.borderRadius = 20.0,
    this.backgroundColor,
  });

  final String text;
  final String emptyText;
  final double borderRadius;
  final Color? backgroundColor;

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
    final ThemeData theme = Theme.of(context);
    final String combined = widget.text.trim();
    final bool isEmpty = combined.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 10),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 6),
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
      ),
    );
  }
}
