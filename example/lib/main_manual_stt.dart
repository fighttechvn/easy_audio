import 'package:flutter/material.dart';

import 'presentation/manual_stt/manual_stt_history_page.dart';

void main() {
  runApp(const ManualSttExampleApp());
}

class ManualSttExampleApp extends StatelessWidget {
  const ManualSttExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manual STT Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const ManualSttHistoryPage(),
    );
  }
}
