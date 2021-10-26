import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_manager/extensions.dart';

class FileWidget extends StatelessWidget {
  final File file;
  final ValueChanged<File> onTap;
  final bool isSelected;

  const FileWidget({
    Key? key,
    required this.file,
    required this.onTap,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: file.name,
      waitDuration: const Duration(seconds: 1),
      child: Material(
        type: MaterialType.canvas,
        color: isSelected ? Colors.purple : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          hoverColor: theme.colorScheme.secondaryVariant,
          onTap: () => onTap(file),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.file_copy),
              const SizedBox(height: 4.0),
              Flexible(
                child: Text(
                  file.name,
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
