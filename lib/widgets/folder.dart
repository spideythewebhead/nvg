import 'dart:async';
import 'dart:io';

import 'package:file_manager/db_manager.dart';
import 'package:file_manager/extensions.dart';
import 'package:file_manager/utils.dart';
import 'package:file_manager/widgets/common_actions.dart';
import 'package:file_manager/widgets/context_menu.dart';
import 'package:file_manager/widgets/delete_confirm_dialog.dart';
import 'package:file_manager/widgets/fav_button.dart';
import 'package:file_manager/widgets/file_last_modified_text.dart';
import 'package:file_manager/widgets/rename_entity_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

abstract class _BaseFolderWidget extends StatefulWidget {
  final Directory dir;
  final ValueChanged<Directory> onClick;
  final ValueChanged<Directory> onDoubleClick;
  final bool isSelected;

  const _BaseFolderWidget({
    Key? key,
    required this.dir,
    required this.onClick,
    required this.onDoubleClick,
    required this.isSelected,
  }) : super(key: key);
}

abstract class _BaseFolderState<T extends _BaseFolderWidget> extends State<T> {
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
        unawaited(DbManager.instance.favItemsBoxListenable.value.delete(widget.dir.path));
      } catch (_) {}
    }
  }
}

class FolderGridWidget extends _BaseFolderWidget {
  const FolderGridWidget({
    Key? key,
    required Directory dir,
    required ValueChanged<Directory> onClick,
    required ValueChanged<Directory> onDoubleClick,
    required bool isSelected,
  }) : super(
          key: key,
          dir: dir,
          onClick: onClick,
          onDoubleClick: onDoubleClick,
          isSelected: isSelected,
        );

  @override
  _FolderGridWidgetState createState() => _FolderGridWidgetState();
}

class _FolderGridWidgetState extends _BaseFolderState<FolderGridWidget> {
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
        radius: const Radius.circular(4.0),
        onRename: onRename,
        onDismiss: () {
          isRenaming = false;
        },
        child: CommonActions(
          onRename: () {
            isRenaming = true;
          },
          onDelete: onDelete,
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
                focusNode: focusNode,
                onTap: () {
                  focusNode.requestFocus();
                  widget.onClick(widget.dir);
                },
                onDoubleTap: () => widget.onDoubleClick(widget.dir),
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
    );
  }
}

class FolderListWidget extends _BaseFolderWidget {
  const FolderListWidget({
    Key? key,
    required Directory dir,
    required ValueChanged<Directory> onClick,
    required ValueChanged<Directory> onDoubleClick,
    required bool isSelected,
  }) : super(
          key: key,
          dir: dir,
          onClick: onClick,
          onDoubleClick: onDoubleClick,
          isSelected: isSelected,
        );

  @override
  _FolderListWidgetState createState() => _FolderListWidgetState();
}

class _FolderListWidgetState extends _BaseFolderState<FolderListWidget> {
  final fileStat = ValueNotifier<FileStat?>(null);

  @override
  void initState() {
    super.initState();

    _getFileStat();
  }

  @override
  void didUpdateWidget(FolderListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dir != widget.dir) {
      _getFileStat();
    }
  }

  void _getFileStat() {
    widget.dir.stat().then((stats) {
      if (mounted) {
        fileStat.value = stats;
      }
    });
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
        radius: const Radius.circular(4.0),
        onRename: onRename,
        onDismiss: () {
          isRenaming = false;
        },
        child: CommonActions(
          onRename: () {
            isRenaming = true;
          },
          onDelete: onDelete,
          child: Tooltip(
            message: widget.dir.name,
            waitDuration: const Duration(seconds: 1),
            child: Material(
              type: MaterialType.canvas,
              color: widget.isSelected ? theme.colorScheme.secondary : Colors.transparent,
              child: InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
                hoverColor: theme.colorScheme.primaryVariant,
                focusNode: focusNode,
                onTap: () {
                  focusNode.requestFocus();
                  widget.onClick(widget.dir);
                },
                onDoubleTap: () => widget.onDoubleClick(widget.dir),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 14.0),
                      Expanded(
                        child: Text(
                          widget.dir.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ValueListenableBuilder<FileStat?>(
                        valueListenable: fileStat,
                        builder: (context, stats, child) {
                          if (stats == null) return const SizedBox();

                          return FileLastModified(datetime: stats.modified);
                        },
                      ),
                      FavButton(fse: widget.dir),
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
