import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'pages/welcome_screen.dart';
import 'pages/lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isLogged = await ApiService.isLoggedIn();

  runApp(CarpeDiemApp(initialScreen: isLogged ? const LobbyScreen() : const WelcomeScreen()));
}

class CarpeDiemApp extends StatelessWidget {
  final Widget initialScreen;
  const CarpeDiemApp({super.key, required this.initialScreen});

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
