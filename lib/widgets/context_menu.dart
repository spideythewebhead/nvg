import 'package:file_manager/widgets/context_menu_root.dart';
import 'package:flutter/material.dart';

class ContextMenu extends StatefulWidget {
  final Widget child;
  final WidgetBuilder? builder;

  const ContextMenu({
    Key? key,
    required this.child,
    required this.builder,
  }) : super(key: key);

  @override
  _ContextMenuState createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  void show(Offset position) {
    if (widget.builder == null) {
      return;
    }

    ContextMenuRoot.of(context).show(
      builder: widget.builder!,
      position: position,
    );
  }

  void remove() {
    ContextMenuRoot.of(context).remove();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == 2) {
          show(event.position);
        }
      },
      child: widget.child,
    );
  }
}
