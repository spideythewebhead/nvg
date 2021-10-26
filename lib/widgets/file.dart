import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_manager/extensions.dart';

class FileWidget extends StatefulWidget {
  final File file;

  const FileWidget({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  _FolderState createState() => _FolderState();
}

class _FolderState extends State<FileWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: widget.file.name,
      waitDuration: const Duration(seconds: 1),
      child: InkWell(
        customBorder: const CircleBorder(),
        highlightColor: theme.colorScheme.secondary,
        hoverColor: theme.colorScheme.secondaryVariant,
        onTap: () {},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_copy),
            const SizedBox(height: 4.0),
            Flexible(
              child: Text(
                widget.file.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
