import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_manager/extensions.dart';

class FolderWidget extends StatefulWidget {
  final Directory dir;
  final ValueChanged<Directory> onTap;

  const FolderWidget({
    Key? key,
    required this.dir,
    required this.onTap,
  }) : super(key: key);

  @override
  _FolderWidgetState createState() => _FolderWidgetState();
}

class _FolderWidgetState extends State<FolderWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: widget.dir.name,
      waitDuration: const Duration(seconds: 1),
      child: InkWell(
        customBorder: const CircleBorder(),
        highlightColor: theme.colorScheme.secondary,
        hoverColor: theme.colorScheme.secondaryVariant,
        onTap: () => widget.onTap(widget.dir),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder),
            const SizedBox(height: 4.0),
            Flexible(
              child: Text(
                widget.dir.name,
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
