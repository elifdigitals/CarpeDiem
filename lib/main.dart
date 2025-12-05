import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'pages/welcome_screen.dart';
import 'pages/lobby_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userId = await AuthService().getUserId();


  runApp(CarpeDiemApp(isLoggedIn: userId != null,));
}

class CarpeDiemApp extends StatelessWidget {

  final bool isLoggedIn;
  const CarpeDiemApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarpeDiem',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: isLoggedIn ? const LobbyScreen() : const WelcomeScreen(),
    );
  }
}
