library streams;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

class ReplaySubject<T> extends Stream<T> implements StreamController<T> {
  final _controller = StreamController<T>.broadcast();
  final _queue = Queue<T>();

  final int size;

  ReplaySubject({this.size = 0});

  List<T> get currentItems => List<T>.unmodifiable(_queue);

  @override
  FutureOr<void> Function()? onCancel;

  @override
  VoidCallback? onListen;

  @override
  VoidCallback? onPause;

  @override
  VoidCallback? onResume;

  @override
  StreamSink<T> get sink => _controller.sink;

  @override
  Stream<T> get stream => this;

  bool get _needsPop => size != 0 && _queue.length == size;

  @override
  void add(T event) {
    if (_needsPop) {
      _queue.removeFirst();
    }

    _queue.addLast(event);
    _controller.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<T> source, {bool? cancelOnError}) {
    return _controller.addStream(source, cancelOnError: cancelOnError);
  }

  @override
  Future close() {
    return _controller.close();
  }

  @override
  Future get done => _controller.done;

  @override
  bool get hasListener => _controller.hasListener;

  @override
  bool get isClosed => _controller.isClosed;

  @override
  bool get isPaused => _controller.isPaused;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    VoidCallback? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream
        .transform(
          _ReplyTransformer(_queue),
        )
        .listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }
}

class _ReplyTransformer<T> implements StreamTransformer<T, T> {
  final Queue<T> events;

  _ReplyTransformer(this.events);

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamController<T> controller;

    controller = StreamController<T>.broadcast(
      onListen: () {
        for (final event in events) {
          controller.add(event);
        }
      },
    );

    late StreamSubscription subscription;

    subscription = stream.listen(
      (event) {
        controller.add(event);
      },
      onDone: () {
        subscription.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    return StreamTransformer.castFrom(this);
  }
}

class _DelayTransformer<T> implements StreamTransformer<T, T> {
  final Duration delay;

  final _queue = Queue<T>();
  var _queueConsumeOnGoing = false;

  _DelayTransformer({required this.delay}) : assert(delay.compareTo(Duration.zero) != 0);

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamController<T> controller;

    controller = stream.isBroadcast ? StreamController.broadcast() : StreamController();

    late StreamSubscription subscription;
    subscription = stream.listen(
      (event) {
        _queue.addLast(event);
        _onQueueUpdated(controller);
      },
      onDone: () {
        subscription.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    return StreamTransformer.castFrom(this);
  }

  void _onQueueUpdated(StreamController<T> controller) async {
    if (_queueConsumeOnGoing) return;

    _queueConsumeOnGoing = true;

    while (_queue.isNotEmpty) {
      final value = _queue.removeFirst();
      await Future.delayed(
        delay,
        () => controller.add(value),
      );
    }

    _queueConsumeOnGoing = false;
  }
}

extension StreamExtension<T> on Stream<T> {
  Stream<T> delayed(Duration delay) => transform(_DelayTransformer(delay: delay));
}
