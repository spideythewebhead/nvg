import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _RenameIntent extends Intent {
  const _RenameIntent();
}

class _DeleteIntent extends Intent {
  const _DeleteIntent();
}

class CommonActions extends StatelessWidget {
  final Widget child;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const CommonActions({
    Key? key,
    required this.child,
    required this.onRename,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.f2): _RenameIntent(),
        SingleActivator(LogicalKeyboardKey.delete): _DeleteIntent(),
      },
      child: Actions(
        actions: {
          _RenameIntent: CallbackAction<_RenameIntent>(onInvoke: (intent) {
            onRename();
          }),
          _DeleteIntent: CallbackAction<_DeleteIntent>(onInvoke: (intent) {
            onDelete();
          })
        },
        child: child,
      ),
    );
  }
}
