import '../../../easy_audio.dart' show TranscriptResult;

class RecordAudioTranscriptState {
  RecordAudioTranscriptState({
    String initialFinal = '',
    String initialLive = '',
  })  : _finalTranscript = initialFinal,
        _liveTranscript = initialLive;

  String _finalTranscript;
  String _liveTranscript;

  String get finalTranscript => _finalTranscript;
  String get liveTranscript => _liveTranscript;

  void apply(TranscriptResult result) {
    if (result.isFinal) {
      final text = result.text.trim();
      if (text.isNotEmpty) {
        if (_finalTranscript.isEmpty) {
          _finalTranscript = text;
        } else {
          _finalTranscript = '$_finalTranscript $text';
        }
      }
      _liveTranscript = '';
    } else {
      _liveTranscript = result.text;
    }
  }

  String buildCombinedText() {
    if (_finalTranscript.isEmpty) {
      return _liveTranscript;
    }
    if (_liveTranscript.isEmpty) {
      return _finalTranscript;
    }
    return '$_finalTranscript\n\n$_liveTranscript';
  }
}
