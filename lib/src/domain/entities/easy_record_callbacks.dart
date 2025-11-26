import 'package:flutter/material.dart';

import 'record_data.dart';
import 'record_session_data.dart';

typedef OnRecordComplete = Future<void> Function(
  RecordData record,
  String locale,
  RecordSessionData? sessionData,
);

typedef OnExitConfirmation = Future<bool?> Function(BuildContext context);

typedef OnLanguageSelected = void Function(String locale, String label);

typedef OnRecordError = void Function(Object error, StackTrace stackTrace);

typedef OnRecordStateChange = void Function(bool isRecording, bool isPaused);

typedef OnMinimize = void Function();

typedef OnRestore = void Function();

typedef FloatingWidgetBuilder = Widget? Function(
  BuildContext context,
  VoidCallback onTap,
  Duration elapsedTime,
  bool isPaused,
);
