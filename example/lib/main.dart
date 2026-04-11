import 'package:flutter/material.dart';

import 'presentation/home/home_page.dart';

void main() {
  runApp(const EasyAudioExampleApp());
}

class EasyAudioExampleApp extends StatelessWidget {
  const EasyAudioExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Audio Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const HomePage(),
    );
  }
}
