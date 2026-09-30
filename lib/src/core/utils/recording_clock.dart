/// How long a recording has been recording, with its pauses taken out.
///
/// SttRecord writes nothing while a session is paused, whether the user paused
/// it or a call did, so wall-clock time from start to stop overstates how much
/// audio there is by every pause in between.
class RecordingClock {
  RecordingClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Duration _paused = Duration.zero;
  DateTime? _pausedAt;

  /// Forgets the pauses of an earlier recording.
  void reset() {
    _paused = Duration.zero;
    _pausedAt = null;
  }

  /// A pause that is already running keeps its start, so a call followed by
  /// the user pausing counts once.
  void pause() {
    _pausedAt ??= _now();
  }

  void resume() {
    final at = _pausedAt;
    if (at == null) {
      return;
    }
    _paused += _now().difference(at);
    _pausedAt = null;
  }

  /// The part of [start] to [end] spent recording. A pause still running at
  /// [end] is left out too: stopping while paused adds nothing.
  Duration activeBetween(DateTime start, DateTime end) {
    final at = _pausedAt;
    final ongoing = at == null || at.isAfter(end)
        ? Duration.zero
        : end.difference(at);
    final active = end.difference(start) - _paused - ongoing;
    return active.isNegative ? Duration.zero : active;
  }
}
