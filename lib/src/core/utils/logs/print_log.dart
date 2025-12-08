import 'package:flutter/material.dart';

class PrintLog {
  static void debug(dynamic message) {
    debugPrint(message.toString());
  }
}
