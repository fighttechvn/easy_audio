const limitRetryInitSpeechToText = 3;

enum StateInitSpeechText {
  none,
  succeeded,
  failed,
}

const List<double> kAudioTemplates = [
  3.67,
  15.87,
  7.74,
  3.67,
  7.74,
  15.87,
  3.67,
  2.4,
  15.87,
  3.67,
  15.87,
  15.87,
  7.74,
  3.67,
  4.4,
  3.67,
  2.4,
  3.67,
  2.4,
  3.67,
  2.4,
  7.74,
  3.67,
  2.4,
  7.74,
  2.4,
  3.67,
  2.4,
  3.67,
  3.67,
  2.4,
  7.74,
  3.67,
  2.4,
  7.74,
  2.4,
  3.67,
  2.4,
  3.67,
  3.67,
  2.4,
  7.74,
  3.67,
  2.4,
  3.67,
  15.87,
  7.74,
  3.67,
  2.4,
  3.67,
];

extension DurationExt on Duration {
  String get formatTimeAudio {
    return toString().split('.').first.padLeft(8, '0');
  }
}

extension StringHandleDiffExt on String {
  String getDiff(String newString) {
    String diffString = '';
    bool startDiff = false;

    for (var i = 0; i < newString.length; i++) {
      if (i >= length) {
        return newString;
      } else {
        if (newString[i] != this[i]) {
          startDiff = true;
        }

        if (startDiff) {
          diffString += newString[i];
        }
      }
    }

    return diffString;
  }
}
