import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/entities/easy_audio_state.dart';
import '../../domain/entities/transcript_result.dart';
import '../utils/transcript_persistence.dart';

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

  final TranscriptDeltaAccumulator _deltaAccumulator =
      TranscriptDeltaAccumulator();

  void resetCommittedTranscript() {
    _deltaAccumulator.reset();
  }

  bool get _shouldProactivelyCycle =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> start({required String? localeId}) async {
    _localeId = localeId;
    if (_starting) {
      return;
    }

    // Avoid re-entering listen() while a session is already active.
    if (speechToText.isListening) {
      return;
    }

    _starting = true;
    try {
      await speechToText.listen(
        onResult: _onSpeechResult,
        localeId: _localeId,
        // IMPORTANT: Cái này quan trọng.
        // Với iOS, sau khi speech to text work
        // 9phút nó sẽ kết thúc luồng để bắt đầu luồng mới để tránh vượt quá
        // giới hạn thời gian của OS
        // (lỗi error_speech_recognizer_connection_interrupted)
        listenFor: _shouldProactivelyCycle ? const Duration(minutes: 9) : null,
        // --> https://pub.dev/packages/speech_to_text/changelog#710
        // listenFor: null,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e, trace) {
      if (kDebugMode) {
        print(e);
        print(trace);
      }
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
    final recognizedWords = result.recognizedWords.trim();
    final transcript = TranscriptResult(
      text: recognizedWords,
      confidence: result.confidence,
      isFinal: result.finalResult,
      timestamp: DateTime.now(),
      alternatives: result.alternates.map((a) => a.recognizedWords).toList(),
    );

    if (!result.finalResult) {
      if (!transcriptController.isClosed) {
        transcriptController.add(transcript);
      }
      return;
    }

    final delta = _deltaAccumulator.commitFinal(recognizedWords);
    if (delta.isEmpty) {
      return;
    }

    final deltaTranscript = TranscriptResult(
      text: delta,
      confidence: result.confidence,
      isFinal: true,
      timestamp: transcript.timestamp,
      alternatives: transcript.alternatives,
    );

    if (!transcriptController.isClosed) {
      transcriptController.add(deltaTranscript);
    }

    if (transcriptBuffer.isNotEmpty) {
      transcriptBuffer.write(' ');
    }
    transcriptBuffer.write(delta);
  }
}
