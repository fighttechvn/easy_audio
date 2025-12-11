import 'package:flutter/material.dart';

import '../../../core/easy_debounce.dart';

class TranscriptionView extends StatefulWidget {
  const TranscriptionView({
    required this.onChanged,
    this.value,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final String? value;

  @override
  State<TranscriptionView> createState() => _TranscriptionViewState();
}

class _TranscriptionViewState extends State<TranscriptionView> {
  final textController = TextEditingController();
  late final _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        EasyDebounce.debounce(
            '_debounceScrollTextToBttom', const Duration(milliseconds: 400),
            () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    textController.text = widget.value ?? '';
  }

  @override
  void didUpdateWidget(covariant TranscriptionView oldWidget) {
    if (widget.value != oldWidget.value) {
      textController.text = widget.value ?? '';
      _scrollToBottom();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: ValueListenableBuilder(
          valueListenable: textController,
          builder: (context, value, child) {
            final resultRecord = value.text;
            final isEmptyResult = resultRecord.isEmpty;
            const colorText = Colors.black;
            return SelectableText(
              isEmptyResult
                  ? 'The transcript will be displayed here...'
                  : resultRecord,
              style: const TextStyle(
                color: colorText,
                fontSize: 16,
                height: 1.45,
              ),
            );
          },
        ),
      ),
    );
  }
}
