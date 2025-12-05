import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/lobby_api.dart';
import '../services/auth_service.dart';

/// Объединённый экран лобби:
/// - показывает игроков / чат / камеру (как в LobbyDetailScreen)
/// - динамически подгружает данные через LobbyApi.getLobbyDetails (как в ActiveLobbyScreen)
/// - поддерживает leaveLobby, startGame, setReadyStatus через LobbyApi
/// - периодически обновляет список игроков
class LobbyDetailScreen extends StatefulWidget {
  /// Передайте либо `initialLobbyData`, либо `lobbyId` (рекомендуется lobbyId).
  final String? lobbyId;
  final Map<String, dynamic>? initialLobbyData;

  const LobbyDetailScreen({
    super.key,
    this.lobbyId,
    this.initialLobbyData,
  }) : assert(lobbyId != null || initialLobbyData != null,
  'Нужно передать lobbyId или initialLobbyData');

  @override
  State<LobbyDetailScreen> createState() => _LobbyDetailScreenState();
}

class _LobbyDetailScreenState extends State<LobbyDetailScreen> {
  // --- camera related ---
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _showCamera = false;
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();

  // --- lobby / UI state ---
  Map<String, dynamic>? _lobbyData;
  List<dynamic> _players = [];
  bool _loading = true;
  String? _errorMessage;
  int _activeTab = 0;
  Timer? _refreshTimer;
  bool _iAmReady = false;
  bool _startingGame = false;

  final List<String> _chatMessages = [
    'Игрок1: Всем привет!',
    'Игрок2: Готовы начинать?',
    'Хост: Ждем еще 2 игроков',
  ];

  @override
  void initState() {
    super.initState();
    // установить начальные данные если есть
    if (widget.initialLobbyData != null) {
      _lobbyData = Map<String, dynamic>.from(widget.initialLobbyData!);
      _players = (_lobbyData?['players'] as List<dynamic>?) ?? [];
      _loading = false;
    }
    _initializeCamera();
    // загрузить актуальные данные
    _loadLobbyData();
    // периодическое обновление (каждые 3 секунды)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadLobbyData(silent: true);
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final firstCamera = cameras.first;
      _cameraController = CameraController(firstCamera, ResolutionPreset.high);
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      // не ломаем экран — просто логируем
      debugPrint('Ошибка инициализации камеры: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    try {
      _cameraController?.dispose();
    } catch (_) {}
    super.dispose();
  }

  // ---------------------
  // API / state methods
  // ---------------------
  Future<void> _loadLobbyData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final lobbyId = widget.lobbyId ?? (_lobbyData?['id']?.toString());
      if (lobbyId == null) {
        throw Exception('lobbyId не задан');
      }

      final response = await LobbyApi.getLobbyDetails(lobbyId);

      if (response['status'] == 'success') {
        final data = Map<String, dynamic>.from(response['data']);
        final playersIds = (data['players'] as List<dynamic>?) ?? [];
        // преобразуем если сервер уже возвращает объекты — используем как есть
        final playersList = playersIds.map((p) {
          if (p is Map) return p;
          return p;
        }).toList();

        if (mounted) {
          setState(() {
            _lobbyData = data;
            _players = playersList;
            _loading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Ошибка загрузки данных';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _leaveLobby() async {
    final lobbyId = widget.lobbyId ?? _lobbyData?['id']?.toString();
    if (lobbyId == null) {
      Navigator.pop(context);
      return;
    }
    final res = await LobbyApi.leaveLobby(lobbyId);
    if (res['status'] == 'success') {
      _refreshTimer?.cancel();
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Не удалось покинуть лобби')),
      );
    }
  }

  Future<void> _toggleReadyStatus() async {
    final lobbyId = widget.lobbyId ?? _lobbyData?['id']?.toString();
    if (lobbyId == null) return;

    setState(() => _iAmReady = true);
    final response = await LobbyApi.setReadyStatus(lobbyId, true);
    if (mounted && response['status'] != 'success') {
      setState(() => _iAmReady = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Ошибка')),
      );
    }
  }

  Future<void> _startGame() async {
    final lobbyId = widget.lobbyId ?? _lobbyData?['id']?.toString();
    if (lobbyId == null) return;
    setState(() => _startingGame = true);
    final res = await LobbyApi.startGame(lobbyId);
    if (mounted) {
      if (res['status'] == 'success') {
        setState(() {
          _startingGame = false;
        });
        _showCameraPlaceholder();
      } else {
        setState(() => _startingGame = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Не удалось начать игру')),
        );
      }
    }
  }

  void _showCameraPlaceholder() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Игра началась!'),
        content: const Text('Экран камеры будет доступен после старта игры.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))
        ],
      ),
    );
  }

  // ---------------------
  // camera & gallery
  // ---------------------
  Future<void> _takePhoto() async {
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = File(image.path);
        _showCamera = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фото сохранено!')));
    } catch (e) {
      debugPrint('Ошибка при съемке фото: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _capturedImage = File(image.path);
      });
    }
  }

  void _toggleCamera() => setState(() => _showCamera = !_showCamera);

  void _sendMessage(String message) {
    setState(() {
      _chatMessages.add('Вы: $message');
    });
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

  bool get _iAmHost {
    final host = _lobbyData?['host'];
    final myId = AuthService().getUserId();
    return host != null && myId != null && host.toString() == myId.toString();
  }

  // ---------------------
  // build UI
  // ---------------------
  @override
  Widget build(BuildContext context) {
    final lobby = _lobbyData ?? widget.initialLobbyData ?? {};
    final players = _players;
    final isHost = _iAmHost;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lobby['lobby_name']?.toString() ?? 'Лобби',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${players.length} игроков • ${lobby['mode'] ?? ''}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (isHost)
                    ElevatedButton(
                      onPressed: _startingGame ? null : _startGame,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      child: _startingGame ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Начать игру'),
                    ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _TabButton(title: 'Игроки', isActive: _activeTab == 0, onTap: () => setState(() => _activeTab = 0)),
                  _TabButton(title: 'Чат', isActive: _activeTab == 1, onTap: () => setState(() => _activeTab = 1)),
                  _TabButton(title: 'Камера', isActive: _activeTab == 2, onTap: () => setState(() => _activeTab = 2)),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadLobbyData, child: const Text('Повторить')),
                  ],
                ),
              )
                  : IndexedStack(
                index: _activeTab,
                children: [
                  // Players tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Участники лобби', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...players.map((p) {
                          // p может быть int id или Map
                          final playerId = p is Map ? p['user_id'] ?? p['id'] ?? '' : p;
                          final username = p is Map ? (p['username'] ?? 'Игрок $playerId') : 'Игрок $playerId';
                          final email = p is Map ? (p['email'] ?? '') : '';
                          final isCurrentUser = AuthService().getUserId()?.toString() == playerId?.toString();
                          final isHostPlayer = _lobbyData?['host']?.toString() == playerId?.toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isHostPlayer ? const Color(0xFF7C3AED) : Colors.grey[300]!, width: isHostPlayer ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isCurrentUser ? const Color(0xFF7C3AED) : Colors.grey[300],
                                  child: Text(username.toString().isNotEmpty ? username.toString()[0] : '?', style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(username.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text(isHostPlayer ? 'Хост' : 'Игрок', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ]),
                                ),
                                if (_iAmHost && !isHostPlayer)
                                  IconButton(
                                    onPressed: () {
                                      // можно вызвать LobbyApi.kickPlayer если есть
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Игрок $playerId кикнут (заглушка)')));
                                    },
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 24),
                        const Text('Настройки лобби', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                            _SettingItem(icon: Icons.access_time, title: 'Лимит времени', value: '${_lobbyData?['time_limit'] ?? '-'} минут'),
                            _SettingItem(icon: Icons.gamepad, title: 'Режим', value: _lobbyData?['mode']?.toString() ?? 'Стандартный'),
                            _SettingItem(icon: Icons.people, title: 'Макс. игроков', value: '${_lobbyData?['max_players'] ?? '8'}'),
                          ]),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Покинуть лобби?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final lobbyId = _lobbyData?['id']?.toString();
                                        if (lobbyId != null && lobbyId.isNotEmpty) {
                                          await LobbyApi.leaveLobby(lobbyId);
                                          Navigator.pop(ctx);

                                        } else {
                                          Navigator.pop(ctx);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Выйти'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text('Покинуть лобби', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chat tab
                  Column(children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _chatMessages[index].startsWith('Вы:') ? const Color(0xFFEDE9FE) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_chatMessages[index]),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(hintText: 'Введите сообщение...', border: InputBorder.none),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) _sendMessage(value);
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              final controller = TextEditingController();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Отправить сообщение'),
                                  content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Введите сообщение')),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                                    TextButton(
                                      onPressed: () {
                                        if (controller.text.trim().isNotEmpty) {
                                          _sendMessage(controller.text);
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: const Text('Отправить'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.send, color: Color(0xFF7C3AED)),
                          ),
                        ],
                      ),
                    ),
                  ]),

                  // Camera tab
                  Column(children: [
                    if (_showCamera && _isCameraInitialized && _cameraController != null)
                      Expanded(child: CameraPreview(_cameraController!))
                    else if (_capturedImage != null)
                      Expanded(child: Image.file(_capturedImage!, fit: BoxFit.cover))
                    else
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Нажмите кнопку ниже, чтобы сделать фото', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        IconButton(onPressed: _pickImageFromGallery, icon: const Icon(Icons.photo_library, size: 30), tooltip: 'Выбрать из галереи'),
                        ElevatedButton(
                          onPressed: _showCamera ? _takePhoto : _toggleCamera,
                          style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(20), backgroundColor: const Color(0xFF7C3AED)),
                          child: Icon(_showCamera ? Icons.camera : Icons.camera_alt, size: 30, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _capturedImage = null;
                            _showCamera = false;
                          }),
                          icon: const Icon(Icons.delete, size: 30, color: Colors.red),
                          tooltip: 'Удалить фото',
                        ),
                      ]),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.title, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF7C3AED) : Colors.transparent, width: 2)),
          ),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: isActive ? const Color(0xFF7C3AED) : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [Icon(icon, color: const Color(0xFF7C3AED)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))), Text(value, style: const TextStyle(color: Colors.grey))]),
    );
  }
}
