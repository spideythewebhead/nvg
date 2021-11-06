import 'dart:io';

import 'package:file_manager/widgets/file.dart';
import 'package:file_manager/widgets/folder.dart';
import 'package:flutter/material.dart';

class FseGridView extends StatelessWidget {
  final List<FileSystemEntity> entities;
  final ValueChanged<Directory> onDirDoubleClick;
  final ValueChanged<File> onFileDoubleClick;
  final ValueChanged<FileSystemEntity> onClick;
  final bool Function(String path) isSelected;

  const FseGridView({
    Key? key,
    required this.entities,
    required this.onDirDoubleClick,
    required this.onFileDoubleClick,
    required this.onClick,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        late int columnItems;

        if (width >= 1600) {
          columnItems = 16;
        } else if (width >= 1280) {
          columnItems = 14;
        } else if (width >= 800) {
          columnItems = 12;
        } else if (width >= 600) {
          columnItems = 8;
        } else if (width >= 400) {
          columnItems = 6;
        } else if (width >= 250) {
          columnItems = 4;
        } else {
          columnItems = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnItems,
            mainAxisSpacing: 2.0,
            crossAxisSpacing: 2.0,
          ),
          itemCount: entities.length,
          itemBuilder: (context, index) {
            final entity = entities[index];

            if (entity is Directory) {
              return FolderGridWidget(
                key: Key(entity.path),
                dir: entity,
                onClick: onClick,
                onDoubleClick: onDirDoubleClick,
                isSelected: isSelected(entity.path),
              );
            }

            if (entity is File) {
              return FileGridWidget(
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
      },
    );
  }
}
