import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_crypto/theme/app_theme.dart';
import 'package:file_crypto/HomeView.dart';
import 'package:desktop_window/desktop_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    DesktopWindow.setWindowSize(const Size(420, 680));
    DesktopWindow.setMinWindowSize(const Size(380, 600));
  }

  runApp(const FileCryptoApp());
}

class FileCryptoApp extends StatelessWidget {
  const FileCryptoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FileCrypto',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeView(),
      debugShowCheckedModeBanner: false,
    );
  }
}
