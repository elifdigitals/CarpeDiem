// lobby_screen.dart

import 'package:flutter/material.dart';
import 'create_lobby_screen.dart';
import 'profile_screen.dart';
import 'lobby_detail_screen.dart';
import '../services/api_service.dart';


class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}


class _LobbyScreenState extends State<LobbyScreen> {
  List<dynamic> _lobbies = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLobbies();
  }

  Future<void> _loadLobbies() async {
    final result = await ApiService.getLobbies();
    setState(() {
      _loading = false;
      if (result['status'] == 'success') {
        _lobbies = result['data'] ?? result;
        print('📊 Loaded ${_lobbies.length} lobbies');
      } else {
        _errorMessage = result['message'];
        print('❌ Error loading lobbies: $_errorMessage');
      }
    });
  }

  void _refreshLobbies() {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    _loadLobbies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'CarpeDiem',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B21B6),
                        ),
                      ),
                      Text(
                        'Москва, Центр',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            onBack: () => Navigator.pop(context),
                            onStore: () {},
                          ),
                        ),
                      );
                    },
                    icon: const Text('👤', style: TextStyle(fontSize: 24)),
                  ),
                ],
              ),
            ),

            Container(
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
                          Icons.location_pin,
                          color: Color(0xFF5B21B6),
                          size: 60,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Интерактивная карта',
                          style: TextStyle(color: Color(0xFF4C1D95)),
                        ),
                        Text(
                          'Зона игры: Центр города',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6D28D9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 30,
                    child: _MapDot(color: const Color(0xFF8B5CF6)),
                  ),
                  Positioned(
                    top: 70,
                    right: 40,
                    child: _MapDot(color: const Color(0xFF7C3AED)),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 120,
                    child: _MapDot(color: const Color(0xFFA78BFA)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateLobbyScreen(
                              onLobbyCreated: _refreshLobbies,
                            ),
                          ),
                        );
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
                      onPressed: _refreshLobbies,
                      icon: const Icon(Icons.refresh, color: Color(0xFF5B21B6)),
                      label: const Text(
                        'Обновить список',
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

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshLobbies,
                      child: const Text('Попробовать снова'),
                    ),
                  ],
                ),
              )
                  : _lobbies.isEmpty
                  ? const Center(
                child: Text(
                  'Нет активных лобби',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Активные лобби',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._lobbies.map((lobby) => _GameCard(lobby)).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final dynamic lobby;
  const _GameCard(this.lobby);

  Future<void> _joinLobby(BuildContext context) async {
    final lobbyId = lobby['lobby_id'];
    final lobbyName = lobby['lobby_name'] ?? lobby['name'] ?? 'Unknown';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Присоединение к $lobbyName...')),
    );

    final result = await ApiService.joinLobby(lobbyId);

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Вы присоединились к $lobbyName!')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LobbyDetailScreen(lobbyData: lobby),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersCount = (lobby['players'] as List?)?.length ?? 0;
    final lobbyName = lobby['lobby_name'] ?? lobby['name'] ?? 'Лобби ${lobby['lobby_id']?.toString().substring(0, 8) ?? 'Unknown'}';
    final gameMode = lobby['mode'] ?? 'default';
    final hostId = lobby['host'] ?? 'Unknown';

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
                      Text(
                        lobbyName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                          _getModeDisplayName(gameMode),
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
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Хост: $hostId',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _joinLobby(context),
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

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'quick':
        return 'Быстрый';
      case 'family':
        return 'Семейный';
      case 'corporate':
        return 'Корпоративный';
      case 'weekly':
        return 'Недельный';
      default:
        return mode;
    }
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
