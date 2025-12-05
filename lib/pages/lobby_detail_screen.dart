import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class LobbyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lobbyData;

  const LobbyDetailScreen({super.key, required this.lobbyData});

  @override
  State<LobbyDetailScreen> createState() => _LobbyDetailScreenState();
}

class _LobbyDetailScreenState extends State<LobbyDetailScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _showCamera = false;
  File? _capturedImage;
  int _activeTab = 0;
  final ImagePicker _picker = ImagePicker();

  final List<String> _chatMessages = [
    'Игрок1: Всем привет!',
    'Игрок2: Готовы начинать?',
    'Хост: Ждем еще 2 игроков',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
      );

      await _cameraController.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Ошибка инициализации камеры: $e');
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (!_isCameraInitialized || !_cameraController.value.isInitialized) return;

    try {
      final XFile image = await _cameraController.takePicture();
      setState(() {
        _capturedImage = File(image.path);
        _showCamera = false;
      });

      // Здесь можно отправить фото на сервер
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фото сохранено!')),
      );
    } catch (e) {
      print('Ошибка при съемке фото: $e');
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

  void _toggleCamera() {
    setState(() {
      _showCamera = !_showCamera;
    });
  }

  void _leaveLobby() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Вы покинули лобби')),
    );
  }

  void _startGame() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Игра начинается!')),
    );
    // Здесь можно добавить логику начала игры
  }

  void _sendMessage(String message) {
    setState(() {
      _chatMessages.add('Вы: $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    final lobby = widget.lobbyData;
    final players = (lobby['players'] as List<dynamic>?) ?? [];
    final isHost = ApiService.currentUserId == lobby['host'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            // Шапка лобби
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lobby['lobby_name'] ?? 'Лобби',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${players.length} игроков • ${lobby['mode']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (isHost)
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                      ),
                      child: const Text('Начать игру'),
                    ),
                ],
              ),
            ),

            // Табы
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _TabButton(
                    title: 'Игроки',
                    isActive: _activeTab == 0,
                    onTap: () => setState(() => _activeTab = 0),
                  ),
                  _TabButton(
                    title: 'Чат',
                    isActive: _activeTab == 1,
                    onTap: () => setState(() => _activeTab = 1),
                  ),
                  _TabButton(
                    title: 'Камера',
                    isActive: _activeTab == 2,
                    onTap: () => setState(() => _activeTab = 2),
                  ),
                ],
              ),
            ),

            // Контент табов
            Expanded(
              child: IndexedStack(
                index: _activeTab,
                children: [
                  // Таб 1: Игроки
                  _buildPlayersTab(players, isHost),

                  // Таб 2: Чат
                  _buildChatTab(),

                  // Таб 3: Камера
                  _buildCameraTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersTab(List<dynamic> players, bool isHost) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Участники лобби',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...players.map((playerId) {
            final isCurrentUser = playerId == ApiService.currentUserId;
            final isHostPlayer = playerId == widget.lobbyData['host'];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHostPlayer
                      ? const Color(0xFF7C3AED)
                      : Colors.grey[300]!,
                  width: isHostPlayer ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isCurrentUser
                        ? const Color(0xFF7C3AED)
                        : Colors.grey[300],
                    child: Text(
                      playerId.toString()[0],
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Игрок $playerId',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          isHostPlayer ? 'Хост' : 'Игрок',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isHost && !isHostPlayer)
                    IconButton(
                      onPressed: () {
                        // Кикнуть игрока
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Игрок $playerId кикнут')),
                        );
                      },
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                    ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 24),
          const Text(
            'Настройки лобби',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.access_time,
                  title: 'Лимит времени',
                  value: '${widget.lobbyData['time_limit']} минут',
                ),
                _SettingItem(
                  icon: Icons.gamepad,
                  title: 'Режим',
                  value: widget.lobbyData['mode'] ?? 'Стандартный',
                ),
                _SettingItem(
                  icon: Icons.people,
                  title: 'Макс. игроков',
                  value: '8',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _leaveLobby,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Покинуть лобби',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _chatMessages[index].startsWith('Вы:')
                      ? const Color(0xFFEDE9FE)
                      : Colors.white,
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
                  decoration: const InputDecoration(
                    hintText: 'Введите сообщение...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _sendMessage(value);
                    }
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
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Введите сообщение',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
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
      ],
    );
  }

  Widget _buildCameraTab() {
    return Column(
      children: [
        if (_showCamera && _isCameraInitialized)
          Expanded(
            child: CameraPreview(_cameraController),
          )
        else if (_capturedImage != null)
          Expanded(
            child: Image.file(_capturedImage!, fit: BoxFit.cover),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Нажмите кнопку ниже, чтобы сделать фото',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library, size: 30),
                tooltip: 'Выбрать из галереи',
              ),
              ElevatedButton(
                onPressed: _showCamera ? _takePhoto : _toggleCamera,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: const Color(0xFF7C3AED),
                ),
                child: Icon(
                  _showCamera ? Icons.camera : Icons.camera_alt,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _capturedImage = null;
                    _showCamera = false;
                  });
                },
                icon: const Icon(Icons.delete, size: 30, color: Colors.red),
                tooltip: 'Удалить фото',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF7C3AED) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? const Color(0xFF7C3AED) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}