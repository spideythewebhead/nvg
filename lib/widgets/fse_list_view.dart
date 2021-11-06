import 'dart:io';

import 'package:file_manager/widgets/file.dart';
import 'package:file_manager/widgets/folder.dart';
import 'package:flutter/material.dart';

class FseListView extends StatelessWidget {
  final List<FileSystemEntity> entities;
  final ValueChanged<Directory> onDirDoubleClick;
  final ValueChanged<File> onFileDoubleClick;
  final ValueChanged<FileSystemEntity> onClick;
  final bool Function(String path) isSelected;

  const FseListView({
    Key? key,
    required this.entities,
    required this.onDirDoubleClick,
    required this.onFileDoubleClick,
    required this.onClick,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: entities.length,
      itemBuilder: (context, index) {
        final entity = entities[index];

        if (entity is Directory) {
          return FolderListWidget(
            key: Key(entity.path),
            dir: entity,
            onClick: onClick,
            onDoubleClick: onDirDoubleClick,
            isSelected: isSelected(entity.path),
          );
        }

        if (entity is File) {
          return FileListWidget(
            key: Key(entity.path),
            file: entity,
            onClick: onClick,
            onDoubleClick: onFileDoubleClick,
            isSelected: isSelected(entity.path),
          );
        }

        return const SizedBox();
      },
    );
  }
}
