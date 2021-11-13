import 'package:file_manager/noop.dart';
import 'package:flutter/material.dart';

class SelfResizableWidget extends StatefulWidget {
  final Widget child;
  final double initialPercent;
  final double maxExtent;
  final double minExtent;
  final bool visible;

  const SelfResizableWidget({
    Key? key,
    this.initialPercent = 1.0,
    this.maxExtent = 1.0,
    this.minExtent = 0.25,
    required this.child,
    required this.visible,
  }) : super(key: key);

  @override
  _SelfResizableWidgetState createState() => _SelfResizableWidgetState();
}

class _SelfResizableWidgetState extends State<SelfResizableWidget> {
  final key = GlobalKey();
  late double percent = widget.initialPercent;
  late double maxHeight = 0.0;

  void onVerticalDrag(DragUpdateDetails details) {
    percent = 1 - ((details.globalPosition.dy + yOffset) / maxHeight);

    if (percent < widget.minExtent) {
      percent = widget.minExtent;
    } else if (percent > widget.maxExtent) {
      percent = widget.maxExtent;
    }

    updateState();
  }

  void updateState() {
    setState(noop);
  }

  double get yOffset {
    return (key.currentContext!.findRenderObject() as RenderBox) //
        .globalToLocal(Offset.zero)
        .dy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Visibility(
      key: key,
      visible: widget.visible,
      maintainState: true,
      maintainInteractivity: false,
      maintainAnimation: true,
      maintainSize: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          maxHeight = constraints.maxHeight;

          return SizedBox(
            height: maxHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: percent * maxHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.resizeRow,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: onVerticalDrag,
                        child: SizedBox(
                          height: 12.0,
                          width: double.infinity,
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2.0),
                                color: theme.colorScheme.secondary,
                              ),
                              child: const SizedBox(
                                height: 4.0,
                                width: 48.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Flexible(child: widget.child),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
