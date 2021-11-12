import 'dart:io';

import 'package:file_manager/utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

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
            minWidth: 200.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                child: const Text('Create folder'),
                onPressed: () async {
                  String? name = await showDialog(
                    context: context,
                    builder: (_) => const _EntityNameTextField(),
                  );

                  if (name != null) {
                    try {
                      await Directory(path.join(widget.directory.path, name)).create();
                    } catch (_) {}
                  }
                },
              ),
              TextButton(
                child: const Text('Create file'),
                onPressed: () async {
                  String? name = await showDialog(
                    context: context,
                    builder: (_) => const _EntityNameTextField(),
                  );

                  if (name != null) {
                    try {
                      await File(path.join(widget.directory.path, name)).create();
                    } catch (_) {}
                  }
                },
              ),
              TextButton(
                child: const Text('Open in terminal'),
                onPressed: () async {
                  await openInTerminal(widget.directory.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntityNameTextField extends StatefulWidget {
  const _EntityNameTextField({Key? key}) : super(key: key);

  @override
  _EntityNameTextFieldState createState() => _EntityNameTextFieldState();
}

class _EntityNameTextFieldState extends State<_EntityNameTextField> {
  final textController = TextEditingController();

  bool canCreate = false;

  @override
  void initState() {
    super.initState();

    textController.addListener(() {
      canCreate = textController.text.trim().isNotEmpty;
      setState(() {});
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void onSubmit([String? _]) {
    Navigator.pop(context, textController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 300.0,
          ),
          child: Material(
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      label: Text('Name'),
                    ),
                    controller: textController,
                    autofocus: true,
                    onSubmitted: onSubmit,
                  ),
                  const SizedBox(height: 8.0),
                  ElevatedButton(
                    onPressed: canCreate ? onSubmit : null,
                    child: const Text('OK'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
