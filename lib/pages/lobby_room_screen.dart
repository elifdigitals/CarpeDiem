import 'package:flutter/material.dart';
import '../services/lobby_api.dart';

class LobbyRoomScreen extends StatefulWidget {
  final int lobbyId;
  const LobbyRoomScreen({required this.lobbyId, super.key});

  @override
  State<LobbyRoomScreen> createState() => _LobbyRoomScreenState();
}

class _LobbyRoomScreenState extends State<LobbyRoomScreen> {
  Map<String, dynamic>? lobby;

  @override
  void initState() {
    super.initState();
    loadLobby();
  }

  Future<void> loadLobby() async {
    final data = await LobbyApi.getLobby(widget.lobbyId);
    setState(() => lobby = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Лобби #${widget.lobbyId}")),
      body: lobby == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lobby!["lobbyName"] ?? "Без названия",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("Режим: ${lobby!["selectedMode"]}"),
            Text("Лимит времени: ${lobby!["timeLimit"]} мин"),
            SizedBox(height: 20),

            Text("Игроки:", style: TextStyle(fontSize: 18)),
            SizedBox(height: 12),

            Expanded(
              child: ListView(
                children: (lobby!["players"] ?? [])
                    .map<Widget>((p) => ListTile(
                  leading: Icon(Icons.person),
                  title: Text(p["nickname"] ?? "Игрок"),
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
