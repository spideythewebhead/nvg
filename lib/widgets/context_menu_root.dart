import 'package:flutter/material.dart';

class ContextMenuRoot extends StatefulWidget {
  final Widget child;

  const ContextMenuRoot({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ContextMenuRootState createState() => ContextMenuRootState();

  static ContextMenuRootState of(BuildContext context) {
    final state = context.findRootAncestorStateOfType<ContextMenuRootState>();

    if (state == null) {
      throw '''
ContextMenuRoot.of(context) returned null
Did you forget to add it as root widget?
      ''';
    }

    return state;
  }
}

class ContextMenuRootState extends State<ContextMenuRoot> {
  OverlayEntry? _overlayEntry;

  DateTime? _lastEntryTime;

  void show({
    required WidgetBuilder builder,
    required Offset position,
  }) {
    final now = DateTime.now();
    if (_lastEntryTime != null && now.difference(_lastEntryTime!) <= const Duration(milliseconds: 500)) {
      return;
    }

    _lastEntryTime = now;

    remove();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _ContextMenuWrapper(
          builder: builder,
          position: position,
          remove: remove,
        );
      },
    );

    Overlay.of(context)!.insert(_overlayEntry!);
  }

  void remove() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _ContextMenuWrapper extends StatefulWidget {
  final VoidCallback remove;
  final Offset position;
  final WidgetBuilder builder;

  const _ContextMenuWrapper({
    Key? key,
    required this.builder,
    required this.position,
    required this.remove,
  }) : super(key: key);

  @override
  _ContextMenuWrapperState createState() => _ContextMenuWrapperState();
}

class _ContextMenuWrapperState extends State<_ContextMenuWrapper> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.remove,
            ),
          ),
          Positioned(
            left: widget.position.dx,
            top: widget.position.dy,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerUp: (_) {
                widget.remove();
              },
              child: widget.builder(context),
            ),
          ),
        ],
      ),
    );
  }
}
