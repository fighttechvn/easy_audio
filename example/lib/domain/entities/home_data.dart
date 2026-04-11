import 'package:flutter/material.dart';

enum HomeSnackBarType { success, warning, error }

/// Enum các loại error
enum HomeErrorType {
  initialization,
  modeChange,
  start,
  stop,
  pause,
  resume,
  cancel,
  playback,
}

@immutable
class HomeSnackBarMessage {
  const HomeSnackBarMessage({required this.text, required this.type});

  final String text;
  final HomeSnackBarType type;
}
