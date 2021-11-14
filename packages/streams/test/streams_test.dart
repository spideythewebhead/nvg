import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streams/streams.dart';

void main() {
  test('expects the Subject to twice emit the same items', () async {
    final replaySubject = ReplaySubject<int>();
    addTearDown(replaySubject.close);

    replaySubject
      ..add(1)
      ..add(2)
      ..add(3);

    expect(replaySubject.stream, emitsInOrder([1, 2, 3]));

    await Future.delayed(const Duration(seconds: 1));

    expect(replaySubject.stream, emitsInOrder([1, 2, 3]));
  });

  test('expects the Subject to emit only the last item', () async {
    final replaySubject = ReplaySubject<int>(size: 1);
    addTearDown(replaySubject.close);

    replaySubject
      ..add(1)
      ..add(2)
      ..add(3);

    expect(replaySubject.stream, emits(3));

    await Future.delayed(const Duration(seconds: 1));

    expect(replaySubject.stream, emits(3));
  });

  test('expects 200ms to pass after stream emits all items', () async {
    final replaySubject = ReplaySubject<int>();
    addTearDown(replaySubject.close);

    replaySubject
      ..add(1)
      ..add(2)
      ..add(3)
      ..add(4);

    final stopwatch = clock.stopwatch()..start();

    await expectLater(
      replaySubject.stream.delayed(const Duration(milliseconds: 50)),
      emitsInOrder([1, 2, 3, 4]),
    );

    stopwatch.stop();

    expect(stopwatch.elapsed, greaterThan(const Duration(milliseconds: 200)));
  });
}
