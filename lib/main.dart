import 'package:bg_monitor/keys.dart';
import 'package:bg_monitor/views/auth/login.dart';
import 'package:bg_monitor/views/bglist.dart';
import 'package:flutter/material.dart';

void main() => runApp(Startup());

class Startup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BG Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      navigatorKey: Keys.navigationKey,
      initialRoute: '/',
      routes: {
        "/": (_) => LoginScreen(),
        "/home": (_) => BGMonitor(),
      },
    );
  }
}
