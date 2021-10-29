import 'dart:io';

import 'package:file_manager/utils.dart';
import 'package:file_manager/widgets/common_actions.dart';
import 'package:file_manager/widgets/context_menu.dart';
import 'package:file_manager/widgets/delete_confirm_dialog.dart';
import 'package:file_manager/widgets/rename_entity_popup.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/extensions.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class FolderWidget extends StatefulWidget {
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
  State<FolderWidget> createState() => _FolderWidgetState();
}

class _FolderWidgetState extends State<FolderWidget> {
  final focusNode = FocusNode();

  var _isRenaming = false;
  bool get isRenaming => _isRenaming;

  set isRenaming(bool v) {
    _isRenaming = v;
    setState(() {});
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void onRename(String name) async {
    isRenaming = false;

    try {
      final indexOfLastSep = widget.dir.path.lastIndexOf(path.separator);

      await widget.dir.rename(path.join(widget.dir.path.substring(0, indexOfLastSep), name));
    } catch (_) {}
  }

  void onDelete() async {
    final canDelete = await showDialog(
          context: context,
          builder: (_) {
            return DeleteConfirmDialog(name: widget.dir.name);
          },
        ) ??
        false;

    if (canDelete) {
      try {
        await widget.dir.delete();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContextMenu(
      builder: (_) => _ContextMenu(
        onDelete: onDelete,
        onRename: () {
          isRenaming = true;
        },
        onCopyPath: () {
          Clipboard.setData(ClipboardData(text: widget.dir.path));
        },
        openInTerminal: () async {
          await openInTerminal(widget.dir.path);
        },
      ),
      child: RenameTextFieldPopup(
        show: isRenaming,
        onRename: onRename,
        onDismiss: () {
          isRenaming = false;
        },
        child: CommonActions(
          onRename: () {
            isRenaming = true;
          },
          onDelete: onDelete,
          child: Focus(
            focusNode: focusNode,
            child: Tooltip(
              message: widget.dir.name,
              waitDuration: const Duration(seconds: 1),
              child: Material(
                type: MaterialType.canvas,
                color: widget.isSelected ? theme.colorScheme.secondary : Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  hoverColor: theme.colorScheme.primaryVariant,
                  onTap: () {
                    focusNode.requestFocus();
                    widget.onTap(widget.dir);
                  },
                  onDoubleTap: () => widget.onDoubleTap(widget.dir),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextMenu extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onCopyPath;
  final VoidCallback openInTerminal;

  const _ContextMenu({
    Key? key,
    required this.onDelete,
    required this.onRename,
    required this.onCopyPath,
    required this.openInTerminal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: IntrinsicWidth(
        child: Material(
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
                    child: const Text('Rename (F2)'),
                    onPressed: onRename,
                  ),
                  TextButton(
                    child: const Text('Delete (Delete)'),
                    onPressed: onDelete,
                  ),
                  TextButton(
                    onPressed: onCopyPath,
                    child: const Text('Copy path'),
                  ),
                  TextButton(
                    child: const Text('Open in terminal'),
                    onPressed: openInTerminal,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
