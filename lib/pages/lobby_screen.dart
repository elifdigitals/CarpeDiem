// lib/pages/lobby_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'create_lobby_screen.dart';
import 'profile_screen.dart';
import 'active_lobby_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLobbies();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_loading && !_searching) {
        _loadLobbies(silent: true);
      }
    });
  }

  Future<void> _loadLobbies({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    final result = await ApiService.getLobbies();
    if (mounted) {
      if (result['status'] == 'success') {
        setState(() {
          _lobbies = result['data'] ?? result;
          _loading = false;
        });
      } else {
        if (!silent) {
          setState(() {
            _errorMessage = result['message'];
            _loading = false;
          });
        } else {
          // silent: don't override UI loading state, but update data if available
          if (result['data'] != null) {
            setState(() => _lobbies = result['data']);
          }
        }
      }
    }
  }

  Future<void> _searchLobbyByCode() async {
    final code = _searchController.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите 6-значный код лобби'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _searching = true;
    });

    final result = await ApiService.searchLobbyByCode(code);

    if (mounted) {
      setState(() {
        _searching = false;
      });

      if (result['status'] == 'success') {
        final lobby = result['data'];
        _showLobbyDialog(lobby);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Лобби не найдено'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLobbyDialog(Map<String, dynamic> lobby) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Лобби найдено: ${lobby['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Код: ${lobby['code']}'),
            Text('Режим: ${_getModeDisplayName(lobby['mode'])}'),
            Text(
                'Игроков: ${lobby['players_count'] ?? lobby['players'].length}'),
            Text('Хост: ${lobby['host_username']}'),
            const SizedBox(height: 16),
            if (lobby['players'] != null)
              Text(
                'Игроки: ${lobby['players'].map((p) => p['username']).join(', ')}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinLobby(lobby['lobby_id'], lobby);
            },
            child: const Text('Присоединиться'),
          ),
        ],
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

  Future<void> _joinLobby(
      String lobbyId, Map<String, dynamic>? lobbyData) async {
    if (lobbyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: ID лобби не найден')),
      );
      return;
    }

    final result = await ApiService.joinLobby(lobbyId);

    if (result['status'] == 'success') {
      if (!mounted) return;

      // Переходим на экран активного лобби
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveLobbyScreen(
            lobbyId: lobbyId,
            lobbyName: lobbyData?['name'] ?? 'Лобби',
            mode: lobbyData?['mode'] ?? 'default',
            timeLimit: lobbyData?['time_limit'] ?? 15,
            isHost: false,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ ${result['message'] ?? 'Ошибка при присоединении'}',
          ),
        ),
      );
      // Если ошибка "уже в лобби", обновляем список
      if (result['message']?.contains('already in this lobby') == true) {
        _loadLobbies();
      }
    }
  }

  void _refreshLobbies() {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }
    _loadLobbies();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Список лобби обновлен'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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

            // Поисковая строка
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Введите 6-значный код лобби',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF6B7280)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) => setState(() {}),
                      onSubmitted: (value) => _searchLobbyByCode(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _searching ? null : _searchLobbyByCode,
                      icon: _searching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Карта (упрощенная версия)
            Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD8C9FF), Color(0xFFBFA3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
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
            ),

            const SizedBox(height: 16),

            // Кнопки действий
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

            // Список лобби
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.group,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Нет активных лобби',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Создайте свое или используйте поиск',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                                  ..._lobbies.map(
                                      (lobby) => _GameCard(lobby, _joinLobby)),
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

class _GameCard extends StatefulWidget {
  final dynamic lobby;
  final Function(String, Map<String, dynamic>?) onJoin;

  const _GameCard(this.lobby, this.onJoin);

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final playersCount = widget.lobby['players_count'] ??
        (widget.lobby['players'] as List?)?.length ??
        0;
    final lobbyName = widget.lobby['name'] ??
        'Лобби ${widget.lobby['lobby_id']?.toString().substring(0, 8) ?? 'Unknown'}';
    final hostUsername = widget.lobby['host_username'] ??
        widget.lobby['host_id']?.toString() ??
        'Unknown';
    final lobbyCode = widget.lobby['code'] ?? '';

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
                      Expanded(
                        child: Text(
                          lobbyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (lobbyCode.isNotEmpty)
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
                            lobbyCode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
                        'Хост: $hostUsername',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Показываем готовых игроков
                  if (widget.lobby['players'] != null)
                    _buildPlayersReadyStatus(widget.lobby['players']),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _joining
                  ? null
                  : () async {
                      setState(() => _joining = true);
                      await widget.onJoin(
                          widget.lobby['lobby_id'], widget.lobby);
                      if (mounted) {
                        setState(() => _joining = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                disabledBackgroundColor: Colors.grey,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
              ),
              child: _joining
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersReadyStatus(List<dynamic> players) {
    final readyCount = players.where((p) => p['is_ready'] == true).length;
    final totalCount = players.length;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: readyCount == totalCount ? Colors.green : Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$readyCount/$totalCount готовы',
          style: TextStyle(
            fontSize: 12,
            color: readyCount == totalCount ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}
