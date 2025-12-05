import 'package:flutter/material.dart';
import 'lobby_room_screen.dart';
import '../services/lobby_api.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class JoinLobbyScreen extends StatefulWidget {
  const JoinLobbyScreen({super.key});

  @override
  State<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends State<JoinLobbyScreen> {
  final controller = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Подключиться к лобби")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Введите ID лобби",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : () async {
                final id = int.tryParse(controller.text);
                final userId = await AuthService().getUserId();
                if (id == null) return;

                setState(() => loading = true);

                final lobby = await LobbyApi.joinLobby(id, userId);

                setState(() => loading = false);

                if (lobby != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LobbyRoomScreen(lobbyId: id),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Лобби не найдено")),
                  );
                }
              },
              child: loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Присоединиться"),
            ),
          ],
        ),
      ),
    );
  }
}
