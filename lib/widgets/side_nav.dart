import 'dart:io';

import 'package:file_manager/env.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

final _home = Directory(kHome);
final _documents = Directory(path.join(kHome, 'Documents'));
final _downloads = Directory(path.join(kHome, 'Downloads'));
final _music = Directory(path.join(kHome, 'Music'));
final _pictures = Directory(path.join(kHome, 'Pictures'));
final _videos = Directory(path.join(kHome, 'Videos'));
final _trash = Directory(path.join(kHome, 'Trash'));

class SideNav extends StatelessWidget {
  final ValueChanged<Directory> onDirTap;
  final Directory selectedDir;

  const SideNav({
    Key? key,
    required this.onDirTap,
    required this.selectedDir,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Material(
        borderRadius: BorderRadius.circular(8.0),
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: ListTileTheme(
            shape: const StadiumBorder(),
            selectedTileColor: theme.scaffoldBackgroundColor,
            selectedColor: theme.colorScheme.primaryVariant,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Home'),
                  leading: const Icon(Icons.home),
                  onTap: () => onDirTap(Directory(kHome)),
                  selected: selectedDir.path == _home.path,
                ),
                ListTile(
                  title: const Text('Documents'),
                  leading: const Icon(Icons.folder),
                  onTap: () => onDirTap(_documents),
                  selected: selectedDir.path == _documents.path,
                ),
                ListTile(
                  title: const Text('Downloads'),
                  leading: const Icon(Icons.download),
                  onTap: () => onDirTap(_downloads),
                  selected: selectedDir.path == _downloads.path,
                ),
                ListTile(
                  title: const Text('Music'),
                  leading: const Icon(Icons.library_music),
                  onTap: () => onDirTap(_music),
                  selected: selectedDir.path == _music.path,
                ),
                ListTile(
                  title: const Text('Pictures'),
                  leading: const Icon(Icons.image),
                  onTap: () => onDirTap(_pictures),
                  selected: selectedDir.path == _pictures.path,
                ),
                ListTile(
                  title: const Text('Videos'),
                  leading: const Icon(Icons.video_call),
                  onTap: () => onDirTap(_videos),
                  selected: selectedDir.path == _videos.path,
                ),
                ListTile(
                  title: const Text('Trash'),
                  leading: const Icon(Icons.delete),
                  // onTap: () => onDirTap(_trash),
                  selected: selectedDir.path == _trash.path,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
