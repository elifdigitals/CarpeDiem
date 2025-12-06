import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ActiveLobbyScreen extends StatefulWidget {
  final String lobbyId;
  final String lobbyName;
  final String mode;
  final int timeLimit;
  final bool isHost;

  const ActiveLobbyScreen({
    super.key,
    required this.lobbyId,
    required this.lobbyName,
    required this.mode,
    required this.timeLimit,
    required this.isHost,
  });

  @override
  State<ActiveLobbyScreen> createState() => _ActiveLobbyScreenState();
}

class _ActiveLobbyScreenState extends State<ActiveLobbyScreen> {
  List<Map<String, dynamic>> _players = [];
  dynamic _hostId;
  bool _loading = true;
  bool _iAmReady = false;
  bool _startingGame = false;
  bool _gameStarted = false;
  String? _errorMessage;
  Timer? _refreshTimer;
  String? _hostUsername;
  String? _lobbyCode;

  @override
  void initState() {
    super.initState();
    _loadLobbyData();
    // Обновляем данные каждые 3 секунды
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_gameStarted && mounted) {
        _loadLobbyData(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLobbyData({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    }

    try {
      final response = await ApiService.getLobbyDetails(widget.lobbyId);

      if (mounted && response['status'] == 'success') {
        final data = response['data'];

        // Получаем данные игроков — поддерживаем разные форматы (List<int> или List<Map>)
        final rawPlayers = (data['players'] as List<dynamic>?) ?? [];
        final playersList = rawPlayers.map<Map<String, dynamic>>((p) {
          if (p is Map<String, dynamic>) return p;
          // если бекенд присылает только id (int/string), нормализуем
          return {
            'user_id': p,
            'username': null,
            'is_ready': false,
          };
        }).toList();

        // Сохраняем host_id, если есть
        _hostId = data['host_id'] ?? data['host'];

        // Получаем информацию о лобби
        _hostUsername = data['host_username'];
        _lobbyCode = data['code'];

        // Проверяем, готов ли текущий пользователь
        final currentUserId = ApiService.currentUserId;
        _iAmReady = playersList
            .where((player) => player['user_id'].toString() == currentUserId)
            .any((player) => player['is_ready'] == true);

        setState(() {
          _players = playersList;
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = response['message'];
          _loading = false;
        });
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleReadyStatus() async {
    if (_iAmReady) return;

    setState(() => _iAmReady = true);

    final response = await ApiService.setReadyStatus(
      widget.lobbyId,
      true,
    );

    if (mounted && response['status'] != 'success') {
      setState(() => _iAmReady = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Ошибка')),
      );
    }
  }

  Future<void> _startGame() async {
    if (!mounted) return;

    setState(() => _startingGame = true);

    final response = await ApiService.startGame(widget.lobbyId);

    if (mounted) {
      if (response['status'] == 'success') {
        setState(() {
          _gameStarted = true;
          _startingGame = false;
        });

        // Переходим к экрану камеры
        _showCameraPlaceholder();
      } else {
        setState(() => _startingGame = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? 'Не удалось начать игру')),
        );
      }
    }
  }

  void _showCameraPlaceholder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Игра началась!'),
        content: const Text(
            'Экран камеры будет доступен после подключения image_picker.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveLobby() async {
    _refreshTimer?.cancel();

    final response = await ApiService.leaveLobby(widget.lobbyId);

    if (mounted) {
      if (response['status'] == 'success') {
        // Возвращаемся с флагом обновления
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Ошибка выхода')),
        );
      }
    }
  }

  bool _areAllPlayersReady() {
    if (_players.isEmpty) return false;
    return _players.length >= 2 && _players.every((p) => p['is_ready'] == true);
  }

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'quick':
        return 'Быстрый матч';
      case 'family':
        return 'Семейный';
      case 'corporate':
        return 'Корпоративный';
      case 'weekly':
        return 'Недельный челлендж';
      default:
        return mode;
    }
  }

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из лобби?'),
        content: const Text('Вы действительно хотите покинуть лобби?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      await _leaveLobby();
      return false; // Не закрываем экран, _leaveLobby сделает это
    }
    return false; // Не закрываем экран
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6FF),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _onWillPop,
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF5B21B6)),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.lobbyName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B21B6),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_lobbyCode != null)
                            Text(
                              'Код: $_lobbyCode',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadLobbyData,
                      icon: const Icon(Icons.refresh, color: Color(0xFF5B21B6)),
                    ),
                  ],
                ),
              ),

              // Main Content
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
                                  onPressed: _loadLobbyData,
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Lobby Info Card
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.gamepad,
                                                color: Color(0xFF7C3AED)),
                                            const SizedBox(width: 8),
                                            Text(
                                              _getModeDisplayName(widget.mode),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF5B21B6),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _infoChip(
                                              Icons.timer,
                                              '${widget.timeLimit} мин',
                                              const Color(0xFFEDE9FE),
                                            ),
                                            _infoChip(
                                              Icons.people,
                                              '${_players.length} игроков',
                                              const Color(0xFFEDE9FE),
                                            ),
                                            _infoChip(
                                              Icons.star,
                                              widget.isHost ? 'Хост' : 'Игрок',
                                              const Color(0xFFEDE9FE),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (_hostUsername != null)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.person,
                                                  size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Хост: $_hostUsername',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Players Section
                                const Text(
                                  'Игроки в лобби',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Expanded(
                                  child: _players.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Ожидание игроков...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: _players.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final player = _players[index];
                                            final userId = player['user_id'];
                                            final username =
                                                player['username'] ??
                                                    'Игрок #$userId';
                                            final isReady =
                                                player['is_ready'] == true;
                                            final isMe = userId?.toString() ==
                                                ApiService.currentUserId
                                                    ?.toString();
                                            final isHost = _hostId != null &&
                                                userId?.toString() ==
                                                    _hostId.toString();

                                            return Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isMe
                                                      ? const Color(0xFF7C3AED)
                                                      : Colors.grey.shade300,
                                                  width: isMe ? 2 : 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  // Аватар с индикатором готовности
                                                  Stack(
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFFEDE9FE),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            username
                                                                .substring(0, 1)
                                                                .toUpperCase(),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Color(
                                                                  0xFF5B21B6),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (isReady)
                                                        Positioned(
                                                          right: 0,
                                                          bottom: 0,
                                                          child: Container(
                                                            width: 12,
                                                            height: 12,
                                                            decoration:
                                                                const BoxDecoration(
                                                              color:
                                                                  Colors.green,
                                                              shape: BoxShape
                                                                  .circle,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .white,
                                                                  spreadRadius:
                                                                      2,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Text(
                                                              username,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            if (isHost)
                                                              Container(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        left:
                                                                            6),
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: const Color(
                                                                      0xFFFFF3CD),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              4),
                                                                ),
                                                                child:
                                                                    const Text(
                                                                  'Хост',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Color(
                                                                        0xFF856404),
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        Text(
                                                          'ID: $userId',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isReady)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFF10B981),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.check,
                                                              size: 14,
                                                              color:
                                                                  Colors.white),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'Готов',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  if (isMe && !_iAmReady)
                                                    ElevatedButton(
                                                      onPressed:
                                                          _toggleReadyStatus,
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF7C3AED),
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 16,
                                                          vertical: 8,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                      ),
                                                      child:
                                                          const Text('Готов'),
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),

                                const SizedBox(height: 24),

                                // Action Buttons
                                if (widget.isHost && _areAllPlayersReady())
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          _startingGame ? null : _startGame,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF10B981),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: _startingGame
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Начать игру',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),

                                if (!widget.isHost && !_iAmReady)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _toggleReadyStatus,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF7C3AED),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text(
                                        'Я готов',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),

                                if (_iAmReady)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFF10B981)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: const Color(0xFF10B981)),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Вы готовы! Ожидание других игроков...',
                                          style: TextStyle(
                                            color: Color(0xFF065F46),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF5B21B6)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5B21B6),
            ),
          ),
        ],
      ),
    );
  }
}
