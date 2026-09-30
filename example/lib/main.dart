import 'dart:async';
import 'dart:developer';

import 'package:easy_audio/easy_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'presentation/sample_screen.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Must run before the first AudioPlayer is created.
      await EasyAudioBackground.init();

      runApp(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(useMaterial3: true),
          home: const SampleScreen(),
        ),
      );
    },
    (error, trace) {
      if (kDebugMode) {
        log('------------------------------------');
        log('[AppDelegate]');
        print(error);
        print(trace);
        log('------------------------------------');
      }
    },
  );
}
