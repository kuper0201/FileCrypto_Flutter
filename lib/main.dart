import 'package:flutter/material.dart';
import 'package:file_crypto/HomeView.dart';
import 'package:desktop_window/desktop_window.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DesktopWindow.setWindowSize(Size(400, 600));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeView(),
      darkTheme: ThemeData.dark(),
    );
  }
}