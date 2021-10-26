import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class CurrentPathTitle extends StatelessWidget {
  final Directory dir;
  final ValueChanged<Directory> onTap;

  const CurrentPathTitle({
    Key? key,
    required this.dir,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final folders = dir.path.split(path.separator).sublist(1);

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: folders.length,
      separatorBuilder: (context, index) => const SizedBox(width: 4.0),
      itemBuilder: (context, index) {
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: Size.zero,
          ),
          onPressed: () {
            final dir = Directory(
              path.joinAll([path.separator, ...folders.sublist(0, 1 + index)]),
            );
            onTap(dir);
          },
          child: Text(folders[index]),
        );
      },
    );
  }
}
