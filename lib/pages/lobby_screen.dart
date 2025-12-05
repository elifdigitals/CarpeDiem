import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create_lobby_screen.dart';
import 'login_screen.dart';
import 'join_lobby_screen.dart';
import 'setting_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import '../services/lobby_api.dart';
import 'lobby_detail_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late Future<Map<String, dynamic>> _lobbiesFuture;

  @override
  void initState() {
    super.initState();
    _loadLobbies();
  }

  void _loadLobbies() {
    setState(() {
      _lobbiesFuture = LobbyApi.getLobbies();
    });
  }

  Future<void> _openBishkekMap() async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=Bishkek');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Не удалось открыть карту');
      }
    } catch (e) {
      debugPrint('Ошибка запуска карты: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CarpeDiem',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B21B6),
                        ),
                      ),
                      Text(
                        'Бишкек, Центр',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      final auth = AuthService();
                      final logged = await auth.isLoggedIn();

                      if (!context.mounted) return;

                      if (logged) {
                        final userId = await auth.getUserId();
                        if (userId != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(
                                userId: userId,
                                onBack: () => Navigator.pop(context),
                                onStore: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    icon: FutureBuilder<bool>(
                      future: AuthService().isLoggedIn(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Text('…');
                        return Text(
                          snap.data! ? '🧑‍🚀' : '👤',
                          style: const TextStyle(fontSize: 24),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- MAP SECTION ---
            GestureDetector(
              onTap: _openBishkekMap,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD8C9FF), Color(0xFFBFA3FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            color: Color(0xFF5B21B6),
                            size: 60,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Открыть карту Бишкека',
                            style: TextStyle(
                                color: Color(0xFF4C1D95),
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          Text(
                            'Нажмите, чтобы увидеть зону игры',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      top: 20,
                      left: 30,
                      child: _MapDot(color: Color(0xFF8B5CF6)),
                    ),
                    const Positioned(
                      top: 70,
                      right: 40,
                      child: _MapDot(color: Color(0xFF7C3AED)),
                    ),
                    const Positioned(
                      bottom: 20,
                      left: 120,
                      child: _MapDot(color: Color(0xFFA78BFA)),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                            Icons.open_in_new,
                            color: Colors.white,
                            size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- ACTION BUTTONS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final userId = await AuthService().getUserId();
                        if (userId != null && context.mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateLobbyScreen(),
                            ),
                          );
                          // Обновляем список после возврата
                          _loadLobbies();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Создать лобби',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const JoinLobbyScreen(),
                          ),
                        );
                        _loadLobbies();
                      },
                      icon: const Icon(Icons.groups, color: Color(0xFF5B21B6)),
                      label: const Text(
                        'Присоединиться к игре',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF5B21B6),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- NEARBY GAMES (CONNECTED TO BACKEND) ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Игры поблизости',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        // Кнопка обновления
                        IconButton(
                          onPressed: _loadLobbies,
                          icon: const Icon(Icons.refresh, color: Color(0xFF5B21B6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Список игр с сервера
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _lobbiesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Ошибка: ${snapshot.error}"));
                        } else if (!snapshot.hasData || snapshot.data!['status'] == 'error') {
                          return Center(child: Text(snapshot.data?['message'] ?? "Ошибка загрузки"));
                        }

                        final List lobbies = snapshot.data!['data'];

                        if (lobbies.isEmpty) {
                          return const Center(
                            child: Text(
                              "Нет активных игр",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            _loadLobbies();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: lobbies.length,
                            itemBuilder: (context, index) {
                              return _GameCard(lobbies[index]);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Map<String, dynamic> game;
  const _GameCard(this.game);

  @override
  Widget build(BuildContext context) {
    final String name = game["lobby_name"] ?? "Без названия";
    final String mode = game["mode"] ?? "Обычный";
    final int timeLimit = game["time_limit"] ?? 0;
    // players приходит как список [ID, ID], нам нужна длина
    final int playersCount = (game["players"] as List?)?.length ?? 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          mode,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5B21B6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$playersCount игроков',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$timeLimit мин',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final userId = await AuthService().getUserId();
                if (userId != null && context.mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LobbyDetailScreen(lobbyId: game["lobby_id"]),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapDot extends StatelessWidget {
  final Color color;
  const _MapDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}