import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'presentation/sample_screen.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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
