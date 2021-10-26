import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class CurrentPathTitle extends StatefulWidget {
  final Directory dir;
  const CurrentPathTitle({
    Key? key,
    required this.dir,
  }) : super(key: key);

  @override
  _CurrentPathTitleState createState() => _CurrentPathTitleState();
}

class _CurrentPathTitleState extends State<CurrentPathTitle> {
  @override
  Widget build(BuildContext context) {
    final folders = widget.dir.path.split(path.separator).sublist(1);

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: folders.length,
      separatorBuilder: (context, index) => const SizedBox(width: 4.0),
      itemBuilder: (context, index) {
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: Size.zero,
          ),
          onPressed: () {},
          child: Text(folders[index]),
        );
      },
    );
  }
}
