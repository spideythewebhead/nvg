import 'dart:io';

import 'package:flutter/material.dart';

class FolderGlobalContextMenu extends StatefulWidget {
  final Directory directory;

  const FolderGlobalContextMenu({
    Key? key,
    required this.directory,
  }) : super(key: key);

  @override
  FolderGlobalContextMenuState createState() => FolderGlobalContextMenuState();
}

class FolderGlobalContextMenuState extends State<FolderGlobalContextMenu> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.dialogBackgroundColor,
      borderRadius: BorderRadius.circular(6.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 200.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: Text('Create folder'),
                onPressed: () {},
              ),
              TextButton(
                child: Text('Create file'),
                onPressed: () {},
              ),
              TextButton(
                child: Text('Open in terminal'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
