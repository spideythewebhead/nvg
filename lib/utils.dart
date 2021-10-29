import 'dart:async';
import 'dart:convert';
import 'dart:io';

final allowedEntityRegExp = RegExp(r'[\w\d \._-]+');

Future<bool> openInTerminal(String path) async {
  try {
    final completer = Completer<bool>();
    final proc = await Process.start('/bin/sh', []);

    late StreamSubscription subscription;

    subscription = proc.stdout.transform(utf8.decoder).listen((result) async {
      final terminals = LineSplitter.split(result);

      for (final terminal in terminals) {
        if (terminal == 'gnome-terminal') {
          proc.stdin.writeln('$terminal --working-directory $path');
          await proc.stdin.flush();

          completer.complete(true);
          subscription.cancel();

          Future.delayed(const Duration(seconds: 1), () => proc.kill());

          return;
        } else if (terminal == 'konsole') {
          proc.stdin.writeln('$terminal --workdir $path');

          completer.complete(true);
          subscription.cancel();

          Future.delayed(const Duration(seconds: 1), () => proc.kill());

          return;
        }
      }

      completer.complete(false);
      subscription.cancel();
    });

    proc.stderr.listen((event) {});

    proc.stdin.writeln('ls /usr/bin | grep -Ei "gnome-terminal|konsole"');

    return completer.future;
  } catch (_) {}

  return false;
}
