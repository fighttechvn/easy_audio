class TranscriptResult {
  final String text;

  final double confidence;

  final bool isFinal;

  final DateTime timestamp;

  final List<String> alternatives;

  TranscriptResult({
    required this.text,
    this.confidence = 0.0,
    this.isFinal = false,
    DateTime? timestamp,
    this.alternatives = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  factory TranscriptResult.empty() => TranscriptResult(text: '', isFinal: true);

  @override
  String toString() {
    return 'TranscriptResult(text: "$text", '
        'confidence: ${confidence.toStringAsFixed(2)}, '
        'isFinal: $isFinal)';
  }
}
