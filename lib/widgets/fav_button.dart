import 'dart:io';

import 'package:file_manager/db_manager.dart';
import 'package:file_manager/models/fav_item.dart';
import 'package:file_manager/widgets/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavButton extends StatelessWidget {
  final FileSystemEntity fse;

  const FavButton({
    Key? key,
    required this.fse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<FavItem>>(
      valueListenable: DbManager.instance.favItemsBoxListenable,
      builder: (context, box, child) {
        final item = box.get(fse.path);

        return FMIconButton(
          child: item != null ? const Icon(Icons.star) : const Icon(Icons.star_outline),
          iconSize: 14.0,
          onTap: () async {
            if (item != null) {
              await box.delete(fse.path);
            } else {
              await box.put(
                fse.path,
                FavItem(path: fse.path, type: FavItemType.file),
              );
            }
          },
        );
      },
    );
  }
}
