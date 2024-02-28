import 'package:file_crypto/EncryptView.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

import 'EncryptView.dart';
import 'DecryptView.dart';

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
 
  static const String _title = 'Flutter Code Sample';
 
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: _title,
      home: HomeView(),
    );
  }
}
 
class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);
 
  @override
  State<HomeView> createState() => _HomeViewState();
}
 
class _HomeViewState extends State<HomeView> {
 
  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold
  );
  
  final List<Widget> _widgetOptions = <Widget>[
    EncryptView(),
    DecryptView()
  ];
 
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
 
  // 메인 위젯
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_outline),
            label: 'Encrypt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_open_outlined),
            label: 'Decrypt',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightGreen,
        onTap: _onItemTapped,
      ),
    );
  }
 
  @override
  void initState() {
    //해당 클래스가 호출되었을떄
    super.initState();
 
  }
 
  @override
  void dispose() {
    super.dispose();
  }
    
}