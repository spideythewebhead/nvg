import 'dart:async';
import 'dart:io';

import 'package:file_manager/env.dart';
import 'package:file_manager/utils.dart';
import 'package:file_manager/widgets/context_menu.dart';
import 'package:file_manager/widgets/current_path_title.dart';
import 'package:file_manager/widgets/file.dart';
import 'package:file_manager/widgets/folder.dart';
import 'package:file_manager/widgets/folder_global_context_menu.dart';
import 'package:file_manager/widgets/icon_button.dart';
import 'package:file_manager/widgets/side_nav.dart';
import 'package:file_manager/widgets/text_filtering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streams/streams.dart';
import 'package:file_manager/extensions.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';

class _HistoryForwardIntent extends Intent {
  const _HistoryForwardIntent();
}

class _HistoryBackwardIntent extends Intent {
  const _HistoryBackwardIntent();
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final searchTextController = TextEditingController();
  final searchFocusNode = FocusNode();

  var historyStack = <FileSystemEntity>[
    Directory(kHome),
  ];

  var historyIndex = 0;

  final dirListStream = <String, ReplaySubject<List<FileSystemEntity>>>{};

  StreamSubscription? folderWatcherSubscription;

  late Directory _currentDirectory;
  Directory get currentDirectory => _currentDirectory;

  set currentDirectory(Directory dir) {
    folderWatcherSubscription?.cancel();
    folderWatcherSubscription = dir.watch().listen(onDirWatcherCalled);

    _currentDirectory = dir;
    setState(() {});
  }

  var showHidden = false;

  var selectedFse = <String, FileSystemEntity>{};

  late final shortcutActions = {
    _HistoryBackwardIntent: CallbackAction<_HistoryBackwardIntent>(
      onInvoke: (intent) {
        if (historyIndex != 0) {
          historyBack();
        }
      },
    ),
    _HistoryForwardIntent: CallbackAction<_HistoryForwardIntent>(
      onInvoke: (intent) {
        if (1 + historyIndex != historyStack.length) {
          historyForward();
        }
      },
    )
  };

  @override
  void initState() {
    super.initState();

    currentDirectory = historyStack.first as Directory;
    dirListStream[_currentDirectory.path] = dirList(_currentDirectory);

    HardwareKeyboard.instance.addHandler(keyPressed);

    searchTextController.addListener(() => setState(() {}));
  }

  ReplaySubject<List<FileSystemEntity>> dirList(Directory dir) {
    final replay = ReplaySubject<List<FileSystemEntity>>(size: 1);

    final subFiles = <FileSystemEntity>[];

    late final StreamSubscription subscription;

    subscription = dir.list().listen((entity) {
      subFiles.add(entity);
    }, onDone: () {
      replay.add(subFiles..sortBy((entity) => entity.name));
      subscription.cancel();
    });

    return replay;
  }

  void onDirWatcherCalled(FileSystemEvent event) async {
    if (event is FileSystemCreateEvent || event is FileSystemDeleteEvent) {
      if (path.basename(event.path)[0] == '.' && !showHidden) {
        return;
      }
    }

    final streamController = dirListStream[currentDirectory.path]!;

    if (event is FileSystemCreateEvent) {
      final entities = streamController.currentItems[0];

      streamController.add(
        sortEntities([
          ...entities,
          event.isDirectory ? Directory(event.path) : File(event.path),
        ]),
      );
    } else if (event is FileSystemDeleteEvent) {
      final entities = streamController.currentItems[0];

      final index = entities.indexWhere((entity) => entity.path == event.path);

      if (index != -1) {
        streamController.add(
          <FileSystemEntity>[
            ...entities.sublist(0, index),
            ...entities.sublist(1 + index),
          ],
        );
      }
    } else if (event is FileSystemModifyEvent) {
      final entities = streamController.currentItems[0];

      final index = entities.indexWhere((entity) => entity.path == event.path);

      if (index != -1) {
        entities[index] = event.isDirectory ? Directory(event.path) : File(event.path);
        streamController.add(sortEntities(entities));
      }
    } else if (event is FileSystemMoveEvent) {
      final entities = streamController.currentItems[0];

      final index = entities.indexWhere((entity) => entity.path == event.path);

      if (index != -1) {
        if (event.destination == null) {
          streamController.add(
            sortEntities(<FileSystemEntity>[
              ...entities.sublist(0, index),
              ...entities.sublist(1 + index),
            ]),
          );
        } else {
          entities[index] = event.isDirectory ? Directory(event.destination!) : File(event.destination!);
          streamController.add(sortEntities(entities));
        }
      }
    }
  }

  List<FileSystemEntity> sortEntities(List<FileSystemEntity> entities) {
    return entities..sortBy((ent) => ent.path);
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

  void onFSETap(FileSystemEntity fse) {
    if (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft)) {
      selectedFse[fse.path] = fse;
      setState(() {});

      return;
    }

    selectedFse = {};
    setState(() {});
  }

  bool keyPressed(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final keyChar = event.character;

    if (FocusScope.of(context).hasPrimaryFocus && keyChar != null && allowedEntityRegExp.hasMatch(keyChar)) {
      searchFocusNode.requestFocus();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      searchFocusNode.unfocus();
      searchTextController.clear();
    }

    return false;
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    searchTextController.dispose();
    HardwareKeyboard.instance.removeHandler(keyPressed);
    folderWatcherSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): _HistoryBackwardIntent(),
          SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): _HistoryForwardIntent(),
        },
        child: Actions(
          actions: shortcutActions,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Material(
                  type: MaterialType.card,
                  color: theme.dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(8.0),
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
                            child: CurrentPathTitle(
                              dir: currentDirectory,
                              onTap: onDirClicked,
                            ),
                          ),
                        ),
                      ),
                      FMIconButton(
                        child: const Icon(Icons.search),
                        onTap: searchFocusNode.requestFocus,
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: TextFiltering(
                  controller: searchTextController,
                  focusNode: searchFocusNode,
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 250.0,
                        minHeight: double.infinity,
                      ),
                      child: SideNav(
                        onDirTap: onDirClicked,
                        selectedDir: currentDirectory,
                      ),
                    ),
                    Expanded(
                      child: ContextMenu(
                        builder: (_) {
                          return FolderGlobalContextMenu(
                            directory: currentDirectory,
                          );
                        },
                        child: LayoutBuilder(builder: (context, constraints) {
                          return StreamBuilder<List<FileSystemEntity>>(
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

                                if (searchTextController.text.isNotEmpty) {
                                  final regexp = RegExp(
                                    searchTextController.text.replaceAll('.', '\\.'),
                                    caseSensitive: false,
                                  );

                                  entities = entities.where((entity) {
                                    return regexp.hasMatch(entity.name);
                                  }).toList(growable: false);
                                }

                                final width = constraints.maxWidth;

                                late int columnItems;

                                if (width >= 1600) {
                                  columnItems = 16;
                                } else if (width >= 1280) {
                                  columnItems = 14;
                                } else if (width >= 800) {
                                  columnItems = 12;
                                } else if (width >= 600) {
                                  columnItems = 8;
                                } else if (width >= 400) {
                                  columnItems = 6;
                                } else if (width >= 250) {
                                  columnItems = 4;
                                } else {
                                  columnItems = 2;
                                }

                                return GridView.builder(
                                  padding: const EdgeInsets.all(8.0),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columnItems,
                                    mainAxisSpacing: 2.0,
                                    crossAxisSpacing: 2.0,
                                  ),
                                  itemCount: entities.length,
                                  itemBuilder: (context, index) {
                                    final entity = entities[index];

                                    if (entity is Directory) {
                                      return FolderWidget(
                                        key: Key(entity.path),
                                        dir: entity,
                                        onTap: onFSETap,
                                        onDoubleTap: onDirClicked,
                                        isSelected: selectedFse[entity.path] != null,
                                      );
                                    }

                                    if (entity is File) {
                                      return FileWidget(
                                        key: Key(entity.path),
                                        file: entity,
                                        onTap: onFSETap,
                                        isSelected: selectedFse[entity.path] != null,
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
                              });
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Material(
                  type: MaterialType.card,
                  color: theme.dialogBackgroundColor,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
