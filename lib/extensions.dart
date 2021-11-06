import 'dart:io';

import 'package:path/path.dart' as path;

extension FileSystemEntityExtension on FileSystemEntity {
  String get name => path.basename(this.path);
  bool get isHidden => path.basename(this.path)[0] == '.';
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
