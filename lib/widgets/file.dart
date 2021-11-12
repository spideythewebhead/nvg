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

abstract class _BaseFileWidget extends StatefulWidget {
  final File file;
  final ValueChanged<File> onClick;
  final bool isSelected;
  final ValueChanged<File> onDoubleClick;

  const _BaseFileWidget({
    Key? key,
    required this.file,
    required this.onClick,
    required this.isSelected,
    required this.onDoubleClick,
  }) : super(key: key);
}

abstract class _BaseFileState<T extends _BaseFileWidget> extends State<T> {
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
        unawaited(DbManager.instance.favItemsBoxListenable.value.delete(widget.file.path));
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
}

class FileGridWidget extends _BaseFileWidget {
  const FileGridWidget({
    Key? key,
    required File file,
    required ValueChanged<File> onClick,
    required bool isSelected,
    required ValueChanged<File> onDoubleClick,
  }) : super(
          key: key,
          file: file,
          onClick: onClick,
          isSelected: isSelected,
          onDoubleClick: onDoubleClick,
        );

  @override
  State<FileGridWidget> createState() => _FileGridWidgetState();
}

class _FileGridWidgetState extends _BaseFileState<FileGridWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContextMenu(
      builder: (_) {
        return _ContextMenu(
          onDelete: onDelete,
          onRename: () => isRenaming = true,
          onCopyPath: () {
            Clipboard.setData(ClipboardData(text: widget.file.path));
          },
          openInTerminal: () async {
            await openInTerminal(widget.file.parent.path);
          },
        );
      },
      child: RenameTextFieldPopup(
        show: isRenaming,
        onRename: onRename,
        radius: const Radius.circular(4.0),
        onDismiss: () {
          isRenaming = false;
        },
        child: CommonActions(
          onRename: () {
            isRenaming = true;
          },
          onDelete: onDelete,
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
                focusNode: focusNode,
                onTap: () {
                  focusNode.requestFocus();
                  widget.onClick(widget.file);
                },
                onDoubleTap: () => widget.onDoubleClick(widget.file),
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
                child: const Text('Copy path'),
                onPressed: onCopyPath,
              ),
              TextButton(child: const Text('Open in terminal'), onPressed: openInTerminal),
            ],
          ),
        ),
      ),
    );
  }
}

class FileListWidget extends _BaseFileWidget {
  const FileListWidget({
    Key? key,
    required File file,
    required ValueChanged<File> onClick,
    required ValueChanged<File> onDoubleClick,
    required bool isSelected,
  }) : super(
          key: key,
          file: file,
          onClick: onClick,
          onDoubleClick: onDoubleClick,
          isSelected: isSelected,
        );

  @override
  _FileListWidgetState createState() => _FileListWidgetState();
}

class _FileListWidgetState extends _BaseFileState<FileListWidget> {
  final fileStat = ValueNotifier<FileStat?>(null);

  @override
  void initState() {
    super.initState();

    _getFolderStat();
  }

  @override
  void didUpdateWidget(FileListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.file != widget.file) {
      _getFolderStat();
    }
  }

  void _getFolderStat() {
    widget.file.stat().then((stats) {
      if (mounted) {
        fileStat.value = stats;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContextMenu(
      builder: (_) {
        return _ContextMenu(
          onDelete: onDelete,
          onRename: () => isRenaming = true,
          onCopyPath: () {
            Clipboard.setData(ClipboardData(text: widget.file.path));
          },
          openInTerminal: () async {
            await openInTerminal(widget.file.parent.path);
          },
        );
      },
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
                widget.onClick(widget.file);
              },
              onDoubleTap: () => widget.onDoubleClick(widget.file),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 6.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Tooltip(
                        message: widget.file.name,
                        waitDuration: const Duration(seconds: 1),
                        child: Text(
                          widget.file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<FileStat?>(
                      valueListenable: fileStat,
                      builder: (context, stats, child) {
                        if (stats == null) return const SizedBox();

                        return FileLastModified(datetime: stats.modified);
                      },
                    ),
                    FavButton(fse: widget.file),
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
