import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextUtils {
  SpeechToTextUtils._();

  static Future<bool> ensureInitialized(
    SpeechToText speechToText, {
    void Function(String)? onStatus,
    void Function(String)? onError,
  }) async {
    return speechToText.initialize(
      onError: (error) {
        debugPrint('SpeechToText error: ${error.errorMsg}');
        onError?.call(error.errorMsg);
      },
      onStatus: (status) {
        debugPrint('SpeechToText status: $status');
        onStatus?.call(status);
      },
    );
  }
}
