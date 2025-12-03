import 'dart:convert';
import 'package:http/http.dart' as http;

class LobbyApi {
  static const String baseUrl = 'http://10.0.2.2:8000'; // поменяй

  static Future<Map<String, dynamic>?> createLobby({
    required int userId,
    required String name,
    required String mode,
    required int time,
  }) async {
    final url = Uri.parse("$baseUrl/lobbies/create");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "host_id": userId,
        "lobby_name": name,
        "selected_mode": mode,
        "time_limit": time,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else{
      throw Exception('Ошибка сети: $Exception\n${response.body}');
      return null;
    }

  }

  static Future<List<dynamic>> getLobbies() async {
    final url = Uri.parse("$baseUrl/lobbies");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> joinLobby(int lobbyId, int? userId) async {
    final url = Uri.parse("$baseUrl/lobbies/$lobbyId/join");
    final res = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLobby(int lobbyId) async {
    final url = Uri.parse("$baseUrl/lobbies/$lobbyId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }
}
