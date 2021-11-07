import 'package:hive_flutter/hive_flutter.dart';

enum FavItemType {
  directory,
  file,
}

class FavItem {
  final String path;
  final FavItemType type;

  FavItem({
    required this.path,
    required this.type,
  });
}

class FavItemTypeAdapter extends TypeAdapter<FavItem> {
  @override
  int get typeId => 0;

  @override
  FavItem read(BinaryReader reader) {
    return FavItem(
      path: reader.readString(),
      type: FavItemType.values[reader.readInt()],
    );
  }

  @override
  void write(BinaryWriter writer, FavItem obj) {
    writer
      ..writeString(obj.path)
      ..writeInt(obj.type.index);
  }
}
