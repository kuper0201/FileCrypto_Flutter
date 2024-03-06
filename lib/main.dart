import 'package:flutter/material.dart';
import 'package:file_crypto/HomeView.dart';

void main() {
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