import 'package:meta/meta.dart';

/// Describes incremental speech recognition output.
@immutable
class SpeechRecognitionResult {
  const SpeechRecognitionResult({
    required this.text,
    required this.isFinal,
    this.words,
  });

  /// Recognized text for the current chunk.
  final String text;

  /// Indicates whether the recognizer considers this a final segment.
  final bool isFinal;

  /// Optional list of word-level alternatives with timestamps.
  final List<SpeechWord>? words;

  @override
  String toString() =>
      'SpeechRecognitionResult(text: "$text", isFinal: $isFinal, words: $words)';
}

/// Word timing metadata parsed from the recognizer output.
@immutable
class SpeechWord {
  const SpeechWord({
    required this.word,
    required this.start,
    required this.end,
    this.confidence,
  });

  /// Word token as produced by the recognizer.
  final String word;

  /// Start timestamp (seconds) inside the current session.
  final double start;

  /// End timestamp (seconds) inside the current session.
  final double end;

  /// Optional confidence value reported by the recognizer.
  final double? confidence;

  @override
  String toString() =>
      'SpeechWord(word: "$word", start: $start, end: $end, confidence: $confidence)';
}
