import 'package:flutter/material.dart';

class FMIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double iconSize;

  const FMIconButton({
    Key? key,
    required this.child,
    this.iconSize = 20.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconTheme(
          data: IconThemeData(
            size: iconSize,
            color: onTap == null ? theme.textTheme.caption!.color : theme.iconTheme.color,
          ),
          child: child,
        ),
      ),
    );
  }
}
