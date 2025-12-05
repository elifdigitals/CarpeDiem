import 'dart:convert';
import 'package:http/http.dart' as http;

class LobbyApi {
  static const String baseUrl = 'http://10.0.2.2:8000'; // поменяй

  static Future<Map<String, dynamic>> createLobby({
    required int? userId,
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
      return {'status': 'success', 'data': json.decode(response.body)};
    } else{
      return {
        'status': 'error',
        'message': 'HTTP Error ${response.statusCode}: ${response.body}',
      };
    }

  }

  static Future<Map<String, dynamic>> getLobbies() async {
    final url = Uri.parse("$baseUrl/lobbies");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return {'status': 'success', 'data': json.decode(response.body)};
    }
    return {
      'status': 'error',
      'message': 'Failed to load lobbies: ${response.statusCode}'
    };
  }

  static Future<Map<String, dynamic>> joinLobby(int lobbyId) async {
    final url = Uri.parse("$baseUrl/lobbies/$lobbyId/join");
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),);

    if (response.statusCode == 200) {
      return {'status': 'success', 'data': json.decode(response.body)};
    }
    return {
      'status': 'error',
      'message': 'HTTP Error ${response.statusCode}: ${response.body}',
    };

  }

  static Future<Map<String, dynamic>> getLobby(int lobbyId) async {
    final url = Uri.parse("$baseUrl/lobbies/$lobbyId");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      return {'status': 'success', 'data': data};
    }
    return {
      'status': 'error',
      'message': 'Failed to load lobbies: ${response.statusCode}'
    };
  }
}
