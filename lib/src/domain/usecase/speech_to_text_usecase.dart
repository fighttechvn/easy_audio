import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextUsecase {
  final String? local;

  SpeechToTextUsecase({
    this.local,
  });

  ///
  /// service handle stt
  ///
  final SpeechToText _speech = SpeechToText();

  Future<List<(String, String)>> getListLocaleSupported() async {
    final locales = await _speech.locales();
    final result = <(String, String)>[];

    for (final e in locales) {
      result.add((e.name, e.localeId));
    }

    return result;
  }


  Future<String?> initSpeechToText({
    Function(String)? statusListener,
  }) async {
    final hasSpeech = await _speech.initialize(
      onStatus: (status) {
        if (kDebugMode) {
          print('[SeechToTextUsecase] status: $status');
        }
      },
      onError: (val) => debugPrint('onError: $val'),
      debugLogging: true,
    );

    if (hasSpeech) {
      if (statusListener != null) {
        _speech.statusListener = statusListener;
      }

      final systemLocale = await _speech.systemLocale();

      // if (kDebugMode) {
      //   final locales = await _speech.locales();
      //   print('locales ${locales.length}');
      //   final result = <String>[];
      //   for (final e in locales) {
      //     print('locales: ${e.name} ${e.localeId}');
      //   }
      //   final data = 'locales ${result.join('-')}';
      //   print(data);
      // }

      return local ?? systemLocale?.localeId ?? 'en-US';
    }

    return local;
  }

  void startSpeak(
    Function(String) callback,
    String currentLocaleId,
  ) {
    debugPrint('[EasyAudio]: start record with locale: $currentLocaleId');

    _speech.listen(
      localeId: currentLocaleId,
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      ),
      onResult: (value) {
        callback(value.alternates.last.recognizedWords);
      },
    );
  }

  Future<void> stopSpeak() async {
    if (_speech.isAvailable == true) {
      await _speech.stop();
    }
  }
}
