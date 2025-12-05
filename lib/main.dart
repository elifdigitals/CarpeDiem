import 'package:flutter/material.dart';
import 'pages/welcome_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarpeDiem',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WelcomeScreen(), // ← ЗАПУСК С WELCOME SCREEN
      debugShowCheckedModeBanner: false,
    );
  }
}
