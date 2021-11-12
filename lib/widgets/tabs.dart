import 'package:file_manager/widgets/home.dart';
import 'package:file_manager/widgets/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class AppTabs extends StatelessWidget {
  final List<TabModel> tabs;
  final int activeTab;
  final ValueChanged<TabModel> onTabClick;

  const AppTabs({
    Key? key,
    required this.tabs,
    required this.activeTab,
    required this.onTabClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0,
      child: ListView.separated(
        itemCount: tabs.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 4.0),
        itemBuilder: (context, index) {
          return _Tab(
            model: tabs[index],
            isActive: index == activeTab,
            onClick: onTabClick,
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 2.0),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final TabModel model;
  final bool isActive;
  final ValueChanged<TabModel> onClick;

  const _Tab({
    Key? key,
    required this.model,
    required this.isActive,
    required this.onClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(6.0),
        ),
      ),
      elevation: 8.0,
      child: InkWell(
        onTap: () => onClick(model),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(6.0),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isActive ? const Border(bottom: BorderSide(color: Colors.white)) : const Border(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 88.0,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      model.name,
                      style: isActive
                          ? TextStyle(
                              color: theme.colorScheme.primary,
                            )
                          : const TextStyle(),
                    ),
                  ),
                ),
              ),
              FMIconButton(
                child: const Icon(Icons.close),
                onTap: () {},
                iconSize: 16.0,
              )
            ],
          ),
        ),
      ),
    );
  }
}
