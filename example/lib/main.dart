import 'dart:async';
import 'dart:developer';

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
      log('------------------------------------');
      log('[AppDelegate]');
      log('$error');
      log('$trace');
      log('------------------------------------');
    },
  );
}
