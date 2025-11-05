import 'package:flutter/material.dart';

class TranscriptionView extends StatefulWidget {
  const TranscriptionView({
    required this.onChanged,
    this.value,
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;
  final ValueChanged<String> onChanged;
  final String? value;

  @override
  State<TranscriptionView> createState() => _TranscriptionViewState();
}

class _TranscriptionViewState extends State<TranscriptionView> {
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textController.text = widget.value ?? '';
  }

  @override
  void didUpdateWidget(covariant TranscriptionView oldWidget) {
    if (widget.value != oldWidget.value) {
      textController.text = widget.value ?? '';
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.brightnessOf(context) == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode == false ? Colors.grey[200] : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TextField(
        keyboardType: TextInputType.multiline,
        minLines: 4,
        onChanged: widget.onChanged,
        maxLines: null,
        // style: TextStyle(
        //   color: isDarkMode == false ? Colors.white : Colors.black,
        //   fontSize: 12,
        //   height: 1.45,
        // ),
        cursorColor: const Color(0xFF0A84FF),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'The transcript will be displayed here...',
          // fillColor: Colors.transparent,
          hintStyle: TextStyle(
            color: Colors.white38,
          ),
          isCollapsed: true,
        ),
      ),
    );
  }
}
