import 'package:flutter/material.dart';
import 'package:file_crypto/EncryptView.dart';
import 'package:file_crypto/DecryptView.dart';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

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
  _HomeViewState() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  int _selectedIndex = 0;  
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