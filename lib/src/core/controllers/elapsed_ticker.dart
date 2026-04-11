import 'dart:async';

class ElapsedTicker {
  ElapsedTicker({
    required void Function(Duration elapsed) onTick,
    Duration initialElapsed = Duration.zero,
    this.interval = const Duration(milliseconds: 30),
  })  : _onTick = onTick,
        _base = initialElapsed;

  final void Function(Duration elapsed) _onTick;
  final Duration interval;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  Duration _base;

  bool get isRunning => _timer != null;

  Duration get elapsed => _base + _stopwatch.elapsed;

  void start() {
    if (_timer != null) {
      return;
    }

    _stopwatch
      ..reset()
      ..start();

    _timer = Timer.periodic(interval, (_) {
      _onTick(elapsed);
    });
  }

  void pause() {
    if (_timer == null) {
      return;
    }

    _timer?.cancel();
    _timer = null;

    _base = _base + _stopwatch.elapsed;
    _stopwatch
      ..stop()
      ..reset();

    _onTick(_base);
  }

  void reset() {
    _timer?.cancel();
    _timer = null;

    _stopwatch
      ..stop()
      ..reset();

    _base = Duration.zero;
    _onTick(_base);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
  }
}
