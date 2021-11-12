import 'dart:io';

import 'package:file_manager/env.dart';
import 'package:file_manager/extensions.dart';
import 'package:file_manager/noop.dart';
import 'package:file_manager/widgets/file_manager.dart';
import 'package:file_manager/widgets/tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _NewTabIntent extends Intent {
  const _NewTabIntent();
}

class _CloseTabIntent extends Intent {
  const _CloseTabIntent();
}

class TabModel {
  final String name;

  TabModel(this.name);
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
  final tabs = <TabModel>[];
  final fileManagers = <FileManager>[];

  var nextTabId = 0;

  var activeTab = 0;

  @override
  void initState() {
    super.initState();

    if (widget.initialPath != null) {
      createTab(directory: Directory(widget.initialPath!));
    } else {
      createTab();
    }
  }

  void createTab({Directory? directory}) {
    tabs.add(TabModel((directory ?? Directory(kHome)).name));

    fileManagers.add(
      FileManager(
        key: ValueKey(nextTabId++),
        onDirChanged: onDirChanged,
        initialDir: directory,
      ),
    );
  }

  void onDirChanged(Directory dir) {
    tabs[activeTab] = TabModel(dir.name);

    updateState();
  }

  void updateState() {
    setState(noop);
  }

  void onTabClick(TabModel model) {
    final index = tabs.indexOf(model);
    activeTab = index;

    updateState();
  }

  void onCreateTab(_) {
    createTab();
    activeTab = tabs.length - 1;

    updateState();
  }

  void onCloseTab(int? index) {
    if (tabs.length == 1) {
      return;
    }

    index ??= activeTab;

    tabs.removeAt(index);

    if (index >= tabs.length) {
      activeTab = tabs.length - 1;
    }

    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.keyT, control: true): _NewTabIntent(),
          SingleActivator(LogicalKeyboardKey.keyW, control: true): _CloseTabIntent(),
        },
        child: Actions(
          actions: {
            _NewTabIntent: CallbackAction(onInvoke: onCreateTab),
            _CloseTabIntent: CallbackAction(onInvoke: (intent) => onCloseTab(null)),
          },
          child: Column(
            children: [
              AppTabs(
                tabs: tabs,
                activeTab: activeTab,
                onTabClick: onTabClick,
              ),
              Flexible(
                child: IndexedStack(
                  index: activeTab,
                  children: fileManagers,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
