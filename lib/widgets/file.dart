import 'dart:io';

import 'package:file_manager/widgets/common_actions.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RenameTextFieldPopup(
      show: isRenaming,
      onRename: (String rename) async {
        isRenaming = false;

        try {
          final indexOfLastSep = widget.file.path.lastIndexOf(path.separator);

          await widget.file.rename(path.join(widget.file.path.substring(0, indexOfLastSep), rename));
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
          await widget.file.delete();
        },
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
    );
  }
}
