import 'package:flutter/material.dart';
import 'pages/welcome_screen.dart';

void main() {
  runApp(const CarpeDiemApp());
}

class CarpeDiemApp extends StatelessWidget {
  const CarpeDiemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarpeDiem',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
