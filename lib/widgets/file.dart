import 'dart:io';

import 'package:file_manager/widgets/common_actions.dart';
import 'package:file_manager/widgets/context_menu.dart';
import 'package:file_manager/widgets/delete_confirm_dialog.dart';
import 'package:file_manager/widgets/rename_entity_popup.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/extensions.dart';
import 'package:path/path.dart' as path;

class FileWidget extends StatefulWidget {
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
  State<FileWidget> createState() => _FileWidgetState();
}

class _FileWidgetState extends State<FileWidget> {
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

  void onDelete() async {
    final canDelete = await showDialog(
          context: context,
          builder: (_) {
            return DeleteConfirmDialog(name: widget.file.name);
          },
        ) ??
        false;

    if (canDelete) {
      try {
        await widget.file.delete();
      } catch (_) {}
    }
  }

  Future<void> onRename(String rename) async {
    isRenaming = false;

    try {
      final indexOfLastSep = widget.file.path.lastIndexOf(path.separator);

      await widget.file.rename(path.join(widget.file.path.substring(0, indexOfLastSep), rename));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContextMenu(
      builder: (_) {
        return _ContextMenu(
          onDelete: onDelete,
          onRename: () => isRenaming = true,
        );
      },
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
              message: widget.file.name,
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
                    widget.onTap(widget.file);
                  },
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

  const _ContextMenu({
    Key? key,
    required this.onDelete,
    required this.onRename,
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
                    child: Text('Rename (F2)'),
                    onPressed: onRename,
                  ),
                  TextButton(
                    child: Text('Delete (Delete)'),
                    onPressed: onDelete,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('Open in terminal'),
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
