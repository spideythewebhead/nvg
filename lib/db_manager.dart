import 'dart:io';

import 'package:file_manager/env.dart';
import 'package:file_manager/models/fav_item.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;

const _kFavItemsBox = 'fav_items';

class DbManager {
  static DbManager get instance => _instance!;
  static DbManager? _instance;

  static Future<DbManager> init() async {
    DbManager? instance = _instance;

    if (instance == null) {
      instance = DbManager();
      await instance._init();

      _instance = instance;
    }

    return instance;
  }

  final _listenableCache = <Type, ValueListenable>{};

  Future<void> _init() async {
    await Hive.initFlutter(path.join(kHome, '.local', 'share', 'file_manager'));
    Hive.registerAdapter(FavItemTypeAdapter());

    await Hive.openBox<FavItem>(_kFavItemsBox);
  }

  ValueListenable<Box<FavItem>> get favItemsBoxListenable {
    _listenableCache[FavItem] ??= Hive.box<FavItem>(_kFavItemsBox).listenable();
    return _listenableCache[FavItem] as ValueListenable<Box<FavItem>>;
  }
}
