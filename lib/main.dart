import 'package:file_manager/widgets/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const FileManagerApp());
}

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.black26,
          secondary: Colors.blue,
          primaryVariant: Colors.black38,
          secondaryVariant: Colors.deepOrange.shade600,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.all(Colors.blue),
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
                return Colors.deepOrange.shade600;
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
      ),
      home: const Home(),
    );
  }
}