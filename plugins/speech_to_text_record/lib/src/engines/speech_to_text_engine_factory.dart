import 'package:flutter/foundation.dart';

import 'noop_speech_to_text_engine.dart';
import 'speech_to_text_engine.dart';
import 'speech_to_text_plugin_engine.dart';
import 'vosk_speech_to_text_engine.dart'
    if (dart.library.io) 'vosk_speech_to_text_engine.dart';

/// Factory helpers for choosing the best available engine at runtime.
abstract class SpeechToTextEngineFactory {
  /// Returns a platform-aware engine implementation.
  static SpeechToTextEngine createDefault({
    required int sampleRate,
    Iterable<String>? preloadLocales,
  }) {
    if (!kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          return SpeechToTextPluginEngine();
        case TargetPlatform.android:
          if (VoskSpeechToTextEngine.isPlatformSupported) {
            final Iterable<String> resolvedPreloads =
                preloadLocales ?? const <String>['en-US', 'vi-VN'];
            return VoskSpeechToTextEngine(
              sampleRate: sampleRate,
              preloadLocales: resolvedPreloads,
            );
          }
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
          if (VoskSpeechToTextEngine.isPlatformSupported) {
            return VoskSpeechToTextEngine(
              sampleRate: sampleRate,
              preloadLocales: preloadLocales ?? const <String>[],
            );
          }
          break;
        case TargetPlatform.fuchsia:
          break;
      }
    }
    return NoOpSpeechToTextEngine();
  }
}
