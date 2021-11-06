import 'dart:io';

abstract class DirListEvent {
  const DirListEvent();
}

class DirListLoadingEvent implements DirListEvent {
  const DirListLoadingEvent();
}

class DirListLoadedEvent implements DirListEvent {
  final List<FileSystemEntity> entities;

  DirListLoadedEvent(this.entities);
}

class DirListChangedEvent implements DirListEvent {
  final List<FileSystemEntity> entities;

  DirListChangedEvent(this.entities);
}
