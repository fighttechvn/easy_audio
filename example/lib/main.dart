import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/material.dart';

import 'src/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyAudio with Simple API
  final navigatorKey = GlobalKey<NavigatorState>();

  EasyAudio.initialize(
    navigatorKey: navigatorKey,
    config: EasyAudioConfig(
      defaultLocale: 'en-US',
      confirmOnExit: true,
      localizations: const EasyAudioLocalizations(), // English default
      onRecordComplete: (result) async {
        debugPrint('Recording completed!');
        debugPrint('URL: ${result.url}');
        debugPrint('Transcript: ${result.content}');
        debugPrint('Duration: ${result.totalTime}ms');
      },
    ),
  );

  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Easy Audio Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
