import 'dart:async';
import 'dart:io';

import 'package:file_manager/env.dart';
import 'package:file_manager/widgets/current_path_title.dart';
import 'package:file_manager/widgets/file.dart';
import 'package:file_manager/widgets/folder.dart';
import 'package:file_manager/widgets/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:streams/streams.dart';
import 'package:file_manager/extensions.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var historyStack = <FileSystemEntity>[
    Directory(kHome),
  ];

  var historyIndex = 0;

  final dirListStream = <String, ReplaySubject<List<FileSystemEntity>>>{};

  late Directory currentDirectory = historyStack[0] as Directory;

  var showHidden = false;

  @override
  void initState() {
    super.initState();

    dirListStream[currentDirectory.path] = dirList(currentDirectory);
  }

  ReplaySubject<List<FileSystemEntity>> dirList(Directory dir) {
    final replay = ReplaySubject<List<FileSystemEntity>>(size: 1);

    final subFiles = <FileSystemEntity>[];

    late final StreamSubscription subscription;

    subscription = dir.list().listen((entity) {
      subFiles.add(entity);
    }, onDone: () {
      replay.add(subFiles);
      subscription.cancel();
    });

    return replay;
  }

  void onDirClicked(Directory dir) {
    if (historyStack.length > 1) {
      final index = historyStack.lastIndexWhere(
        (e) => e.parent.path == dir.parent.path,
        1 + historyIndex,
      );

      if (index != -1) {
        historyStack = historyStack.sublist(0, index);
      }
    }

    historyStack.add(dir);
    historyIndex = historyStack.length - 1;

    currentDirectory = dir;

    if (!dirListStream.containsKey(dir.path)) {
      dirListStream[dir.path] = dirList(dir);
    }

    setState(() {});
  }

  void historyBack() {
    historyIndex -= 1;
    currentDirectory = historyStack[historyIndex] as Directory;

    setState(() {});
  }

  void historyForward() {
    historyIndex += 1;
    currentDirectory = historyStack[historyIndex] as Directory;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Material(
            type: MaterialType.card,
            color: theme.dialogBackgroundColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FMIconButton(
                  child: const Icon(Icons.arrow_back),
                  onTap: historyIndex == 0 ? null : historyBack,
                ),
                FMIconButton(
                  child: const Icon(Icons.arrow_forward),
                  onTap: (1 + historyIndex == historyStack.length) ? null : historyForward,
                ),
                Flexible(
                  child: Center(
                    child: SizedBox(
                      height: 32.0,
                      child: CurrentPathTitle(dir: currentDirectory),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FileSystemEntity>>(
                stream: dirListStream[currentDirectory.path],
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const LinearProgressIndicator();
                  }

                  var entities = snapshot.data!;

                  if (entities.isEmpty) {
                    return Center(
                      child: Text(
                        'Empty folder',
                        style: theme.textTheme.headline4,
                      ),
                    );
                  }

                  if (!showHidden) {
                    entities = entities.where((entity) {
                      if (entity.name[0] == '.') {
                        return false;
                      }

                      return true;
                    }).toList(growable: false);
                  }

                  final screenWidth = MediaQuery.of(context).size.width;

                  int columnItems = 6;

                  if (screenWidth >= 1600) {
                    columnItems = 20;
                  } else if (screenWidth >= 1280) {
                    columnItems = 12;
                  } else if (screenWidth >= 896) {
                    columnItems = 10;
                  } else if (screenWidth >= 600) {
                    columnItems = 8;
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnItems,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                    ),
                    itemCount: entities.length,
                    itemBuilder: (context, index) {
                      final entity = entities[index];

                      if (entity is Directory) {
                        return FolderWidget(
                          dir: entity,
                          onTap: onDirClicked,
                        );
                      }

                      if (entity is File) {
                        return FileWidget(
                          file: entity,
                        );
                      }

                      return Transform.rotate(
                        angle: .456,
                        child: Center(
                          child: Text(
                            'implement',
                            style: theme.textTheme.caption,
                          ),
                        ),
                      );
                    },
                  );
                }),
          ),
          Container(
            color: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: showHidden,
                      onChanged: (value) {
                        setState(() {
                          showHidden = value!;
                        });
                      },
                    ),
                    const Text('Show Hidden?'),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
