import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_manager/db_manager.dart';
import 'package:file_manager/env.dart';
import 'package:file_manager/extensions.dart';
import 'package:file_manager/fse_view_type.dart';
import 'package:file_manager/models/fav_item.dart';
import 'package:file_manager/noop.dart';
import 'package:file_manager/prefs_manager.dart';
import 'package:file_manager/utils.dart';
import 'package:file_manager/widgets/almost_terminal.dart';
import 'package:file_manager/widgets/context_menu.dart';
import 'package:file_manager/widgets/current_path_title.dart';
import 'package:file_manager/widgets/dir_list_event.dart';
import 'package:file_manager/widgets/folder_global_context_menu.dart';
import 'package:file_manager/widgets/fse_grid_view.dart';
import 'package:file_manager/widgets/fse_list_view.dart';
import 'package:file_manager/widgets/icon_button.dart';
import 'package:file_manager/widgets/self_resizable_widget.dart';
import 'package:file_manager/widgets/shortcuts_helper.dart';
import 'package:file_manager/widgets/side_nav.dart';
import 'package:file_manager/widgets/text_filtering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:streams/streams.dart';

class _HistoryForwardIntent extends Intent {
  const _HistoryForwardIntent();
}

class _HistoryBackwardIntent extends Intent {
  const _HistoryBackwardIntent();
}

class _ShowShortcutsIntent extends Intent {
  const _ShowShortcutsIntent();
}

class _ToggleTerminalIntent extends Intent {
  const _ToggleTerminalIntent();
}

class FileManager extends StatefulWidget {
  final Directory? initialDir;
  final ValueChanged<Directory> onDirChanged;

  const FileManager({
    Key? key,
    required this.onDirChanged,
    this.initialDir,
  }) : super(key: key);

  @override
  _FileManagerState createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  final bodyFocusNode = FocusNode();
  final searchTextController = TextEditingController();
  final searchFocusNode = FocusNode();

  late final prefsManager = PrefsManager.instance;
  late final dbManager = DbManager.instance;

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

    dbManager.favItemsBoxListenable.removeListener(onFavItemsChanged);
    folderWatcherSubscription?.cancel();
    folderWatcherSubscription = dir.watch().listen(onDirWatcherCalled);

    _currentDirectory = dir;
    updateState();
  }

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
    ),
    _ShowShortcutsIntent: CallbackAction<_ShowShortcutsIntent>(
      onInvoke: (intent) {
        ShortcutsHelper.show(context);
      },
    ),
    _ToggleTerminalIntent: CallbackAction<_ToggleTerminalIntent>(
      onInvoke: (intent) {
        isTerminalOpen = !isTerminalOpen;

        if (!isTerminalOpen) {
          bodyFocusNode.requestFocus();
        }

        updateState();
      },
    )
  };

  List<FileSystemEntity>? entitiesSnapshot;

  bool isTerminalOpen = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialDir != null) {
      historyStack.add(widget.initialDir!);
    }

    historyIndex = historyStack.length - 1;

    currentDirectory = historyStack.last as Directory;
    onDirChanged(currentDirectory);

    HardwareKeyboard.instance.addHandler(keyPressed);

    searchTextController.addListener(updateState);
    prefsManager.addListener(updateState);

    Future.microtask(() => FocusScope.of(context).requestFocus());
  }

  void updateState() {
    setState(noop);
  }

  void onDirChanged(Directory dir) {
    dirListController.add(
      DirListLoadedEvent(sortEntities(dir.listSync())),
    );
  }

  void onDirWatcherCalled(FileSystemEvent event) async {
    if (event is FileSystemCreateEvent || event is FileSystemDeleteEvent) {
      if (path.basename(event.path)[0] == '.' && !prefsManager.showHidden) {
        return;
      }
    }

    final lastEvent = dirListController.currentItems.first;
    late List<FileSystemEntity> entities;

    if (lastEvent is DirListLoadedEvent) {
      entities = lastEvent.entities;
    } else if (lastEvent is DirListChangedEvent) {
      entities = lastEvent.entities;
    } else {
      return;
    }

    if (event is FileSystemCreateEvent) {
      dirListController.add(
        DirListChangedEvent(
          sortEntities([
            ...entities,
            event.isDirectory ? Directory(event.path) : File(event.path),
          ]),
        ),
      );
    } else if (event is FileSystemDeleteEvent) {
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
      final index = entities.indexWhere((entity) => entity.path == event.path);

      if (index != -1) {
        entities[index] = event.isDirectory ? Directory(event.path) : File(event.path);

        dirListController.add(
          DirListChangedEvent(sortEntities(entities)),
        );
      }
    } else if (event is FileSystemMoveEvent) {
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

    if (dir != historyStack.firstOrNull) {
      historyStack.add(dir);
      historyIndex = historyStack.length - 1;
    }

    currentDirectory = dir;
    widget.onDirChanged(dir);
  }

  void historyBack() {
    historyIndex -= 1;
    currentDirectory = historyStack[historyIndex] as Directory;
    widget.onDirChanged(currentDirectory);

    setState(() {});
  }

  void historyForward() {
    historyIndex += 1;
    currentDirectory = historyStack[historyIndex] as Directory;
    widget.onDirChanged(currentDirectory);

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

    if (HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft)) {
      return false;
    }

    if (bodyFocusNode.hasPrimaryFocus && keyChar != null && allowedEntityRegExp.hasMatch(keyChar)) {
      searchFocusNode.requestFocus();
    } else if (event.logicalKey == LogicalKeyboardKey.escape &&
        (searchFocusNode.hasFocus || searchTextController.text.isNotEmpty)) {
      bodyFocusNode.requestFocus();
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

  void onFavClick() {
    if (_currentDirectory == kFavouritesFolder) {
      return;
    }

    _currentDirectory = kFavouritesFolder;

    folderWatcherSubscription?.cancel();

    onFavItemsChanged();
    dbManager.favItemsBoxListenable.addListener(onFavItemsChanged);
    updateState();
  }

  void onFavItemsChanged() {
    final entities = DbManager
        .instance
        .favItemsBoxListenable
        .value //
        .values
        .map<FileSystemEntity>((val) {
      if (val.type == FavItemType.directory) {
        return Directory(val.path);
      }

      return File(val.path);
    }).toList(growable: false);

    dirListController.add(DirListChangedEvent(entities));
  }

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
      onTap: () {
        bodyFocusNode.requestFocus();
        searchTextController.clear();
      },
      child: Scaffold(
        body: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): _HistoryBackwardIntent(),
            SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): _HistoryForwardIntent(),
            SingleActivator(LogicalKeyboardKey.question, shift: true): _ShowShortcutsIntent(),
            SingleActivator(LogicalKeyboardKey.f1, alt: true): _ToggleTerminalIntent(),
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
                          child: prefsManager.fseViewType == FseViewType.grid
                              ? const Icon(Icons.grid_view)
                              : const Icon(Icons.view_list),
                          onTap: () {
                            prefsManager.changeFseViewType(prefsManager.fseViewType.next);
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
                            onFavClick: onFavClick,
                          ),
                        ),
                        Expanded(
                          child: ContextMenu(
                            builder: currentDirectory == kFavouritesFolder
                                ? null
                                : (_) {
                                    return FolderGlobalContextMenu(
                                      directory: currentDirectory,
                                    );
                                  },
                            child: Stack(
                              fit: StackFit.passthrough,
                              children: [
                                Positioned.fill(
                                  child: Column(
                                    children: [
                                      Center(
                                        child: TextFiltering(
                                          controller: searchTextController,
                                          focusNode: searchFocusNode,
                                          onEnterPressed: () {
                                            if ((entitiesSnapshot?.length ?? 0) == 1) {
                                              final FileSystemEntity entity = entitiesSnapshot![0];

                                              if (entity is Directory) {
                                                onDirClicked(entity);
                                              } else {
                                                onFileDoubleClicked(entity as File);
                                              }

                                              bodyFocusNode.requestFocus();
                                            }
                                          },
                                        ),
                                      ),
                                      Flexible(
                                        child: StreamBuilder<DirListEvent>(
                                          stream: dirListController,
                                          initialData: const DirListLoadingEvent(),
                                          builder: (context, snapshot) {
                                            if (snapshot.data is DirListLoadingEvent) {
                                              entitiesSnapshot = null;
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

                                            if (!prefsManager.showHidden) {
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

                                            entitiesSnapshot = entities;

                                            if (prefsManager.fseViewType == FseViewType.grid) {
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
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: SelfResizableWidget(
                                    visible: isTerminalOpen,
                                    child: AlmostTerminal(
                                      directory: currentDirectory,
                                      open: isTerminalOpen,
                                    ),
                                  ),
                                ),
                              ],
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
                          const ShowShortcutsHelper(),
                          const SizedBox(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: prefsManager.showHidden,
                                onChanged: (value) {
                                  prefsManager.changeShowHidden(value!);
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
