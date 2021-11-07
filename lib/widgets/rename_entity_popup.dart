import 'package:file_manager/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _RenameEntityTextField extends StatefulWidget {
  // final Offset position;
  final ValueChanged<String> onOk;
  final VoidCallback onDismiss;
  final RenderBox renderBox;
  final Radius radius;

  const _RenameEntityTextField({
    Key? key,
    required this.onOk,
    required this.onDismiss,
    // required this.position,
    required this.renderBox,
    required this.radius,
  }) : super(key: key);

  @override
  _RenameEntityTextFieldState createState() => _RenameEntityTextFieldState();
}

class _RenameEntityTextFieldState extends State<_RenameEntityTextField> {
  final focusNode = FocusNode();
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    HardwareKeyboard.instance.addHandler(handleOnEscapeKey);

    focusNode.requestFocus();
  }

  bool handleOnEscapeKey(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(handleOnEscapeKey);
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = widget.renderBox.size
        .center(
          widget.renderBox.localToGlobal(Offset.zero),
        )
        .translate(0, widget.renderBox.size.height / 2.0);

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: ClipPath(
                clipper: _ObjectShapeClipper(
                  offset: widget.renderBox.localToGlobal(Offset.zero),
                  widgetSize: widget.renderBox.size,
                  radius: widget.radius,
                ),
                child: const ColoredBox(color: Colors.black45),
              ),
            ),
          ),
          CustomSingleChildLayout(
            delegate: _PositionDelegate(offset),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 350.0,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Flexible(
                        child: TextField(
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12.0,
                              horizontal: 8.0,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              allowedEntityRegExp,
                            )
                          ],
                          focusNode: focusNode,
                          onSubmitted: widget.onOk,
                          controller: textController,
                        ),
                      ),
                      ElevatedButton(
                        child: const Text('OK'),
                        onPressed: () => widget.onOk(textController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionDelegate extends SingleChildLayoutDelegate {
  final Offset position;

  _PositionDelegate(this.position);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.tighten();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var dx = position.dx - childSize.width / 2.0;

    if (dx + childSize.width >= size.width) {
      dx = size.width - childSize.width - 8.0;
    }

    return Offset(
      dx,
      position.dy,
    );
  }

  @override
  bool shouldRelayout(covariant _PositionDelegate oldDelegate) {
    return position != oldDelegate.position;
  }
}

class RenameTextFieldPopup extends StatefulWidget {
  final Widget child;
  final bool show;
  final ValueChanged<String> onRename;
  final VoidCallback onDismiss;
  final Radius radius;

  const RenameTextFieldPopup({
    Key? key,
    required this.child,
    required this.onRename,
    required this.onDismiss,
    required this.radius,
    this.show = false,
  }) : super(key: key);

  @override
  _RenameTextFieldPopupState createState() => _RenameTextFieldPopupState();
}

class _RenameTextFieldPopupState extends State<RenameTextFieldPopup> {
  OverlayEntry? overlayEntry;

  @override
  void didUpdateWidget(covariant RenameTextFieldPopup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.show != widget.show && overlayEntry == null) {
      Future.microtask(() {
        final renderBox = context.findRenderObject() as RenderBox;

        overlayEntry = OverlayEntry(
          builder: (context) {
            return _RenameEntityTextField(
              onOk: widget.onRename,
              onDismiss: widget.onDismiss,
              renderBox: renderBox,
              radius: widget.radius,
              // position: offset,
            );
          },
        );

        Overlay.of(context)!.insert(overlayEntry!);
      });
    }

    if (!widget.show && overlayEntry != null) {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _ObjectShapeClipper extends CustomClipper<Path> {
  final Radius radius;
  final Offset offset;
  final Size widgetSize;

  _ObjectShapeClipper({
    required this.offset,
    required this.widgetSize,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    path.addRRect(
      RRect.fromLTRBR(
        offset.dx,
        offset.dy,
        offset.dx + widgetSize.width,
        offset.dy + widgetSize.height,
        radius,
      ),
    );

    path.fillType = PathFillType.evenOdd;

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return true;
  }
}
