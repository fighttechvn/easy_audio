import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> enableWakelock({bool enable = true}) async {
  try {
    if (enable) {
      await WakelockPlus.enable();
      await WakelockPlus.toggle(enable: enable);
    } else {
      await WakelockPlus.toggle(enable: enable);
    }
  } catch (e, trace) {
    if (kDebugMode) {
      print(e);
      print(trace);
    }
  }
}
