import 'package:flutter/material.dart';

class ShortcutsHelper extends StatelessWidget {
  const ShortcutsHelper({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ShortcutsHelper(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IntrinsicWidth(
        child: Card(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 550.0,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: const [
                        _PrettyKey(displayName: 'alt'),
                        _Plus(),
                        _PrettyKey(displayName: 'right arrow'),
                        _Colon(),
                        Text('Go backwards to history'),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: const [
                        _PrettyKey(displayName: 'alt'),
                        _Plus(),
                        _PrettyKey(displayName: 'left arrow'),
                        _Colon(),
                        Text('Go forwards to history'),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: const [
                        _PrettyKey(displayName: 'f2'),
                        _Colon(),
                        Text('Rename file/folder'),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: const [
                        _PrettyKey(displayName: 'delete'),
                        _Colon(),
                        Text('Delete file/folder'),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: const [
                        _PrettyKey(displayName: 'shift'),
                        _Plus(),
                        _PrettyKey(displayName: '?'),
                        _Colon(),
                        Text('Shows this helper'),
                      ],
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

class _Plus extends StatelessWidget {
  const _Plus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(' + ');
  }
}

class _Colon extends StatelessWidget {
  const _Colon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(' : ');
  }
}

class _PrettyKey extends StatelessWidget {
  final String displayName;

  const _PrettyKey({
    Key? key,
    required this.displayName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.background.withOpacity(.75),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Text(
          displayName,
          style: theme.textTheme.button,
        ),
      ),
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
        side: const BorderSide(color: Colors.white24),
      ),
    );
  }
}
