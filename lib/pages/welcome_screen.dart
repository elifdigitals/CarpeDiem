import 'package:flutter/material.dart';
import 'login_screen.dart';  // ← ДОБАВИТЬ ЭТУ СТРОЧКУ
import 'register_screen.dart'; // ← ДОБАВИТЬ ЭТУ СТРОЧКУ
import 'lobby_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 191, 137, 225),
              Color.fromARGB(255, 181, 137, 212),
              Color.fromARGB(255, 180, 111, 218),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📸', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'CarpeDiem',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Лови момент! Играй с друзьями!',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  _feature('🎯', 'Фоточелленджи в реальном времени'),
                  const SizedBox(height: 16),
                  _feature('🗺️', 'Игры на ограниченной территории'),
                  const SizedBox(height: 16),
                  _feature('🏆', 'Рейтинги и достижения'),
                  const SizedBox(height: 40),

                  // КНОПКА РЕГИСТРАЦИИ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color.fromARGB(255, 180, 111, 218),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 6,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Зарегистрироваться',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // КНОПКА ВХОДА
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Войти',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _feature(String emoji, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}