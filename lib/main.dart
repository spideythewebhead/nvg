import 'package:collection/collection.dart';
import 'package:file_manager/db_manager.dart';
import 'package:file_manager/prefs_manager.dart';
import 'package:file_manager/widgets/context_menu_root.dart';
import 'package:file_manager/widgets/home.dart';
import 'package:flutter/material.dart';

void main(List<String> args) async {
  await Future.wait([
    PrefsManager.init(),
    DbManager.init(),
  ]);

  runApp(
    FileManagerApp(
      args: args,
    ),
  );
}

class FileManagerApp extends StatelessWidget {
  final List<String> args;

  const FileManagerApp({
    Key? key,
    required this.args,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.blue.shade600,
          primaryVariant: Colors.green.shade700,
          secondaryVariant: Colors.blue.shade800,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(Colors.blue.shade600),
        ),
        textTheme: const TextTheme(
          bodyText1: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
          bodyText2: TextStyle(
            fontSize: 14.0,
          ),
          caption: TextStyle(fontSize: 14.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88.0, 44.0),
            shape: const StadiumBorder(),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            enableFeedback: true,
            minimumSize: MaterialStateProperty.all(const Size(88.0, 44.0)),
            shape: MaterialStateProperty.all(const StadiumBorder()),
            backgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.hovered)) {
                return Colors.blue.shade800;
              }
            }),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            // primary: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(88.0, 44.0),
            shape: const StadiumBorder(),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 20.0,
        ),
      ),
      home: ContextMenuRoot(
        child: Home(
          initialPath: args.firstOrNull,
        ),
      ),
    );
  }
}
