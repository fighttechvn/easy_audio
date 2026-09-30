import 'dart:async';

import 'package:stt_record/stt_record.dart';

import '../../domain/entities/transcript_result.dart';
import '../utils/transcript_persistence.dart';

class SpeechRecognitionController {
  SpeechRecognitionController({
    required this.sttRecord,
    required this.transcriptController,
    required this.transcriptBuffer,
  });

  final SttRecord sttRecord;
  final StreamController<TranscriptResult> transcriptController;
  final StringBuffer transcriptBuffer;

  final TranscriptDeltaAccumulator _deltaAccumulator =
      TranscriptDeltaAccumulator();

  StreamSubscription<SttRecordTranscript>? _sub;

  void resetCommittedTranscript() {
    _deltaAccumulator.reset();
  }

  Future<void> start() async {
    if (_sub != null) {
      return;
    }

    _sub = sttRecord.transcripts.listen(
      _onSttRecordTranscript,
      onError: (_) {
        // Best-effort.
      },
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onSttRecordTranscript(SttRecordTranscript result) {
    final recognizedWords = result.text.trim();
    final transcript = TranscriptResult(
      text: recognizedWords,
      confidence: 0.0,
      isFinal: result.isFinal,
      timestamp: DateTime.now(),
      alternatives: const [],
    );

    if (!result.isFinal) {
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
      confidence: 0.0,
      isFinal: true,
      timestamp: transcript.timestamp,
      alternatives: const [],
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
