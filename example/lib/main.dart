import 'package:flutter/material.dart';

import 'src/easy_audio_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Easy Audio',
      home: EasyAudioExampleScreen(),
    );
  }
}
