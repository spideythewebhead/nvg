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
          primary: Colors.green.shade500,
          secondary: Colors.deepPurpleAccent,
          primaryVariant: Colors.green.shade700,
          secondaryVariant: Colors.deepPurpleAccent.shade700,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(Colors.deepPurpleAccent),
        ),
        textTheme: const TextTheme(
          bodyText1: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
          ),
          bodyText2: TextStyle(
            fontSize: 14.0,
          ),
          caption: TextStyle(fontSize: 12.0),
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
                return Colors.deepPurpleAccent;
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
