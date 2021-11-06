import 'dart:async';
import 'dart:io';

import 'package:file_manager/env.dart';
import 'package:file_manager/fse_view_type.dart';
import 'package:file_manager/utils.dart';
import 'package:file_manager/widgets/context_menu.dart';
import 'package:file_manager/widgets/current_path_title.dart';
import 'package:file_manager/widgets/dir_list_event.dart';
import 'package:file_manager/widgets/file.dart';
import 'package:file_manager/widgets/folder.dart';
import 'package:file_manager/widgets/folder_global_context_menu.dart';
import 'package:file_manager/widgets/fse_grid_view.dart';
import 'package:file_manager/widgets/fse_list_view.dart';
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
  final String? initialPath;

  const Home({
    Key? key,
    this.initialPath,
  }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final bodyFocusNode = FocusNode();
  final searchTextController = TextEditingController();
  final searchFocusNode = FocusNode();

  final dirListController = ReplaySubject<DirListEvent>(size: 1);

  var historyStack = <FileSystemEntity>[
    Directory(kHome),
  ];

  var historyIndex = 0;

  StreamSubscription? folderWatcherSubscription;

  late Directory _currentDirectory;
  Directory get currentDirectory => _currentDirectory;

  set currentDirectory(Directory dir) {
    searchTextController.clear();
    onDirChanged(dir);

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

  final fseViewType = ValueNotifier(FseViewType.grid);

  @override
  void initState() {
    super.initState();

    if (widget.initialPath != null) {
      historyStack.add(Directory(widget.initialPath!));
    }

    historyIndex = historyStack.length - 1;

    currentDirectory = historyStack.last as Directory;
    onDirChanged(currentDirectory);

    HardwareKeyboard.instance.addHandler(keyPressed);

    searchTextController.addListener(() => setState(() {}));
  }

  void onDirChanged(Directory dir) {
    dirListController.add(
      DirListLoadedEvent(sortEntities(dir.listSync())),
    );
  }

  void onDirWatcherCalled(FileSystemEvent event) async {
    if (event is FileSystemCreateEvent || event is FileSystemDeleteEvent) {
      if (path.basename(event.path)[0] == '.' && !showHidden) {
        return;
      }
    }

    if (event is FileSystemCreateEvent) {
      final entities = dirListController.currentItems[0] as List<FileSystemEntity>;

      dirListController.add(
        DirListChangedEvent(
          sortEntities([
            ...entities,
            event.isDirectory ? Directory(event.path) : File(event.path),
          ]),
        ),
      );
    } else if (event is FileSystemDeleteEvent) {
      final entities = dirListController.currentItems[0] as List<FileSystemEntity>;

      final index = entities.indexWhere((entity) => entity.path == event.path);

      if (index != -1) {
        dirListController.add(DirListChangedEvent(
          <FileSystemEntity>[
            ...entities.sublist(0, index),
            ...entities.sublist(1 + index),
          ],
        ));
      }
    } else if (event is FileSystemModifyEvent) {
      final entities = dirListController.currentItems[0] as List<FileSystemEntity>;

      final index = entities.indexWhere((entity) => entity.path == event.path);

      if (index != -1) {
        entities[index] = event.isDirectory ? Directory(event.path) : File(event.path);

        dirListController.add(
          DirListChangedEvent(sortEntities(entities)),
        );
      }
    } else if (event is FileSystemMoveEvent) {
      final entities = dirListController.currentItems[0] as List<FileSystemEntity>;

      final index = entities.indexWhere((entity) => entity.path == event.path);

      if (index != -1) {
        if (event.destination == null) {
          dirListController.add(
            DirListChangedEvent(
              sortEntities(<FileSystemEntity>[
                ...entities.sublist(0, index),
                ...entities.sublist(1 + index),
              ]),
            ),
          );
        } else {
          entities[index] = event.isDirectory ? Directory(event.destination!) : File(event.destination!);
          dirListController.add(
            DirListChangedEvent(sortEntities(entities)),
          );
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

  void onFSEClick(FileSystemEntity fse) {
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

    if (FocusScope.of(context).hasFocus && keyChar != null && allowedEntityRegExp.hasMatch(keyChar)) {
      searchFocusNode.requestFocus();
    } else if (event.logicalKey == LogicalKeyboardKey.escape && searchFocusNode.hasFocus) {
      bodyFocusNode.requestFocus();
      // searchFocusNode.unfocus();
      searchTextController.clear();
    }

    return false;
  }

  void onFileDoubleClicked(File file) async {
    try {
      await Process.run('xdg-open', [file.path]);
    } catch (_) {}
  }

  bool isFseSelected(String path) => selectedFse.containsKey(path);

  @override
  void dispose() {
    bodyFocusNode.dispose();
    searchFocusNode.dispose();
    searchTextController.dispose();
    HardwareKeyboard.instance.removeHandler(keyPressed);
    folderWatcherSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: bodyFocusNode.requestFocus,
      child: Scaffold(
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
                          child: ValueListenableBuilder<FseViewType>(
                            valueListenable: fseViewType,
                            builder: (context, value, child) {
                              if (value == FseViewType.grid) {
                                return const Icon(Icons.grid_view);
                              }

                              return const Icon(Icons.view_list);
                            },
                          ),
                          onTap: () {
                            fseViewType.value = fseViewType.value.next;
                          },
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
                  child: Focus(
                    focusNode: bodyFocusNode,
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
                            child: StreamBuilder<DirListEvent>(
                              stream: dirListController,
                              initialData: const DirListLoadingEvent(),
                              builder: (context, snapshot) {
                                if (snapshot.data is DirListLoadingEvent) {
                                  return const LinearProgressIndicator();
                                }

                                final data = snapshot.data;
                                late List<FileSystemEntity> entities;

                                if (data is DirListLoadedEvent) {
                                  entities = data.entities;
                                } else if (data is DirListChangedEvent) {
                                  entities = data.entities;
                                }

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

                                return ValueListenableBuilder(
                                  valueListenable: fseViewType,
                                  builder: (context, viewType, child) {
                                    if (viewType == FseViewType.grid) {
                                      return FseGridView(
                                        entities: entities,
                                        onDirDoubleClick: onDirClicked,
                                        onFileDoubleClick: onFileDoubleClicked,
                                        onClick: onFSEClick,
                                        isSelected: isFseSelected,
                                      );
                                    }

                                    return FseListView(
                                      entities: entities,
                                      onDirDoubleClick: onDirClicked,
                                      onFileDoubleClick: onFileDoubleClicked,
                                      onClick: onFSEClick,
                                      isSelected: isFseSelected,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
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
      ),
    );
  }
}
