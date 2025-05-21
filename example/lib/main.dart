import 'package:flutter/material.dart';

import 'src/easy_audio_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Audio Example Screen',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const EasyAudioExampleScreen(),
    );
  }
}
