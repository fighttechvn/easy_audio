import 'package:flutter/material.dart';

class TranscriptionView extends StatelessWidget {
  const TranscriptionView({
    super.key,
    required this.controller,
    this.scrollController,
  });

  final TextEditingController controller;
  final ScrollController? scrollController;

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
        controller: controller,
        keyboardType: TextInputType.multiline,
        minLines: 4,
        scrollController: scrollController,
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
