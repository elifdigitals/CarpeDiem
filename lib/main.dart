import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'dart:io';

import 'screens/login/login_page.dart';
import 'screens/lobby/lobby_create_page.dart';
import 'screens/lobby/lobby_list_page.dart';

import 'repositories/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsRepository().loadSettings();
  final cameras = await availableCameras();
  final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
    orElse: () => cameras.first,
  );

  runApp(MyApp(camera: backCamera));
}

class MyApp extends StatelessWidget {
  // final AppSettings initialSettings;
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarpeDiem',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;

  const MyHomePage({super.key, required this.camera});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<Map<String, dynamic>> _lobbies = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller?.initialize();

    setState(() {
      _addSampleLobbies();
    });
  }

  void _addSampleLobbies() {
    _lobbies.addAll([
      {
        'name': 'Quick Match',
        'mode': 'Quick Match',
        'author': 'Anon',
        'players': '3/10',
        'time': '5 min',
        'location': 'Ala-Too University',
        'createdAt': DateTime.now().subtract(const Duration(minutes: 30)),
      },
      {
        'name': 'Championship Round',
        'mode': 'Championship Round',
        'author': 'ProPlayer',
        'players': '7/10',
        'time': '15 min',
        'location': 'Ala-Too University',
        'createdAt': DateTime.now().subtract(const Duration(minutes: 15)),
      },
    ]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openCamera() async {
    try {
      await _initializeControllerFuture;
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPreviewPage(controller: _controller!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error (Initialization): $e')),
      );
    }
  }

  void _openLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _createLobby() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LobbyCreatePage()),
    );

    if (result != null) {
      setState(() {
        _lobbies.insert(0, result);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lobby "${result['name']}" is created! 🎮')),
      );
    }
  }

  void _viewAllLobbies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyListPage(lobbies: _lobbies),
      ),
    );
  }

  void _joinLobby(Map<String, dynamic> lobby) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining "${lobby['name']}"...')),
    );
  }

  Widget _buildLobbyCard(Map<String, dynamic> lobby, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Text(
            lobby['players'].split('/')[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lobby['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mode: ${lobby['mode']}',
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'by ${lobby['author']}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            lobby['location'],
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _joinLobby(lobby),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Join'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('CarpeDiem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 20),
            tooltip: "Sign in",
            onPressed: _openLoginPage,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Lobbies',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_lobbies.length > 3)
                  TextButton(
                    onPressed: _viewAllLobbies,
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),

          if (_lobbies.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No active lobbies',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create the first lobby!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _lobbies.length > 3000 ? 3000 : _lobbies.length,
                itemBuilder: (context, index) => _buildLobbyCard(_lobbies[index], index),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createLobby,
        tooltip: 'Create a lobby',
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Main')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _openCamera,
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('list of lobbies')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CameraPreviewPage extends StatefulWidget {
  final CameraController controller;

  const CameraPreviewPage({super.key, required this.controller});

  @override
  _CameraPreviewPageState createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  String? _imagePath;

  void _takePicture() async {
    try {
      final XFile picture = await widget.controller.takePicture();

      await GallerySaver.saveImage(
        picture.path,
        albumName: 'CarpeDiem',
      ).then((bool? success) {
        if (success == true) {
          setState(() {
            _imagePath = picture.path;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📸')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera")),
      body: Column(
        children: <Widget>[
          Expanded(
            child: CameraPreview(widget.controller),
          ),
          if (_imagePath != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Image.file(File(_imagePath!)),
                  const SizedBox(height: 10),
                  const Text(
                    '📸',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        tooltip: 'Take a photo',
        child: const Icon(Icons.camera),
      ),
    );
  }
}
