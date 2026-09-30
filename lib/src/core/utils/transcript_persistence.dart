String resolveTranscriptForPersistence({
  required String? resultTranscript,
  required String finalTranscript,
  required String liveTranscript,
}) {
  final resultText = (resultTranscript ?? '').trim();
  final finalText = finalTranscript.trim();
  final liveText = liveTranscript.trim();

  final baseText = resultText.isNotEmpty ? resultText : finalText;

  if (baseText.isEmpty) {
    return liveText;
  }
  if (liveText.isEmpty) {
    return baseText;
  }

  if (baseText.contains(liveText)) {
    return baseText;
  }

  final deltaAccumulator = TranscriptDeltaAccumulator();

  deltaAccumulator.commitFinal(baseText);
  final delta = deltaAccumulator.commitFinal(liveText).trim();

  if (delta.isEmpty) {
    return baseText;
  }

  return '$baseText $delta';
}

class TranscriptDeltaAccumulator {
  final List<String> _committedWords = <String>[];

  void reset() {
    _committedWords.clear();
  }

  String commitFinal(String fullFinalText) {
    final full = fullFinalText.trim();
    if (full.isEmpty) {
      return '';
    }

    if (_committedWords.isEmpty) {
      _committedWords.addAll(_splitWords(full));
      return full;
    }

    final fullWords = _splitWords(full);
    if (fullWords.isEmpty) {
      return '';
    }

    final committedText = _committedWords.join(' ');
    if (full.startsWith(committedText)) {
      final suffix = full.substring(committedText.length).trim();
      if (suffix.isEmpty) {
        return '';
      }
      _committedWords
        ..clear()
        ..addAll(fullWords);
      return suffix;
    }

    final overlap = _maxSuffixPrefixOverlap(
      committed: _committedWords,
      incoming: fullWords,
    );

    final deltaWords = fullWords.sublist(overlap);
    if (deltaWords.isEmpty) {
      return '';
    }

    _committedWords.addAll(deltaWords);
    return deltaWords.join(' ');
  }

  List<String> _splitWords(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
  }

  int _maxSuffixPrefixOverlap({
    required List<String> committed,
    required List<String> incoming,
  }) {
    final max = committed.length < incoming.length
        ? committed.length
        : incoming.length;

    for (var k = max; k >= 1; k--) {
      var ok = true;
      for (var i = 0; i < k; i++) {
        if (committed[committed.length - k + i] != incoming[i]) {
          ok = false;
          break;
        }
      }
      if (ok) {
        return k;
      }
    }
    return 0;
  }
}
