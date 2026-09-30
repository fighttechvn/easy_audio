import 'package:easy_audio/src/core/utils/recording_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 9, 30, 10);
  late DateTime now;
  late RecordingClock clock;

  DateTime at(int seconds) => start.add(Duration(seconds: seconds));

  setUp(() {
    now = start;
    clock = RecordingClock(now: () => now);
  });

  test('without pauses it is the time from start to end', () {
    expect(clock.activeBetween(start, at(90)), const Duration(seconds: 90));
  });

  test('leaves out a pause that ended', () {
    now = at(10);
    clock.pause();
    now = at(40);
    clock.resume();

    expect(clock.activeBetween(start, at(60)), const Duration(seconds: 30));
  });

  test('leaves out every pause', () {
    now = at(10);
    clock.pause();
    now = at(20);
    clock.resume();
    now = at(30);
    clock.pause();
    now = at(45);
    clock.resume();

    expect(clock.activeBetween(start, at(50)), const Duration(seconds: 25));
  });

  test('stopping while paused adds nothing after the pause', () {
    now = at(20);
    clock.pause();

    expect(clock.activeBetween(start, at(80)), const Duration(seconds: 20));
  });

  test('a second pause before resuming keeps the first start', () {
    now = at(10);
    clock.pause();
    now = at(15);
    clock.pause();
    now = at(30);
    clock.resume();

    expect(clock.activeBetween(start, at(40)), const Duration(seconds: 20));
  });

  test('resuming without a pause changes nothing', () {
    now = at(10);
    clock.resume();

    expect(clock.activeBetween(start, at(30)), const Duration(seconds: 30));
  });

  test('reset forgets earlier pauses', () {
    now = at(10);
    clock.pause();
    now = at(40);
    clock.resume();
    clock.reset();

    expect(clock.activeBetween(start, at(60)), const Duration(seconds: 60));
  });

  test('is never negative', () {
    expect(clock.activeBetween(at(10), start), Duration.zero);
  });
}
