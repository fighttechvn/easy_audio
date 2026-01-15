import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/entities/easy_audio_state.dart';
import '../../domain/entities/transcript_result.dart';

class SpeechRecognitionController {
  SpeechRecognitionController({
    required this.speechToText,
    required this.transcriptController,
    required this.transcriptBuffer,
    required this.getCurrentState,
    required this.isSpeechAvailable,
  });

  final SpeechToText speechToText;
  final StreamController<TranscriptResult> transcriptController;
  final StringBuffer transcriptBuffer;
  final EasyAudioState Function() getCurrentState;
  final bool Function() isSpeechAvailable;

  String? _localeId;
  bool _starting = false;

  Future<void> start({required String? localeId}) async {
    _localeId = localeId;
    if (_starting) {
      return;
    }
    _starting = true;
    try {
      await speechToText.listen(
        onResult: _onSpeechResult,
        localeId: _localeId,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    try {
      await speechToText.stop();
    } catch (_) {
      // ignore
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final transcript = TranscriptResult(
      text: result.recognizedWords,
      confidence: result.confidence,
      isFinal: result.finalResult,
      timestamp: DateTime.now(),
      alternatives: result.alternates.map((a) => a.recognizedWords).toList(),
    );

    if (!transcriptController.isClosed) {
      transcriptController.add(transcript);
    }

    if (result.finalResult) {
      if (transcriptBuffer.isNotEmpty) {
        transcriptBuffer.write(' ');
      }
      transcriptBuffer.write(result.recognizedWords);

      if (getCurrentState() == EasyAudioState.recording &&
          isSpeechAvailable()) {
        unawaited(start(localeId: _localeId));
      }
    }
  }
}
