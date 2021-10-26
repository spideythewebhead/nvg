import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_manager/extensions.dart';

class FolderWidget extends StatelessWidget {
  final Directory dir;
  final ValueChanged<Directory> onTap;
  final ValueChanged<Directory> onDoubleTap;
  final bool isSelected;

  const FolderWidget({
    Key? key,
    required this.dir,
    required this.onTap,
    required this.onDoubleTap,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: dir.name,
      waitDuration: const Duration(seconds: 1),
      child: Material(
        type: MaterialType.canvas,
        color: isSelected ? theme.colorScheme.secondary : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          hoverColor: theme.colorScheme.primaryVariant,
          onTap: () => onTap(dir),
          onDoubleTap: () => onDoubleTap(dir),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder),
              const SizedBox(height: 4.0),
              Flexible(
                child: Text(
                  dir.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
