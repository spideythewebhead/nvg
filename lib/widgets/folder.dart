import 'dart:io';

import 'package:file_manager/widgets/common_actions.dart';
import 'package:file_manager/widgets/rename_entity_popup.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/extensions.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RenameTextFieldPopup(
      show: isRenaming,
      onRename: (String rename) async {
        isRenaming = false;

        try {
          final indexOfLastSep = widget.dir.path.lastIndexOf(path.separator);

          await widget.dir.rename(path.join(widget.dir.path.substring(0, indexOfLastSep), rename));
        } catch (_) {}
      },
      onDismiss: () {
        isRenaming = false;
      },
      child: CommonActions(
        onRename: () {
          isRenaming = true;
        },
        onDelete: () async {
          await widget.dir.delete();
        },
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
    );
  }
}
