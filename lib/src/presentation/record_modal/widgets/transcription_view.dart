import 'package:flutter/material.dart';

class TranscriptionView extends StatelessWidget {
  const TranscriptionView({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.45,
        ),
        cursorColor: const Color(0xFF0A84FF),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Nội dung chuyển giọng nói sẽ hiển thị tại đây...',
          fillColor: Colors.transparent,
          hintStyle: TextStyle(
            color: Colors.white38,
          ),
          isCollapsed: true,
        ),
      ),
    );
  }
}

