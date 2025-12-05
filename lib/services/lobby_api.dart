import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class LobbyApi {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<Map<String, dynamic>?> createLobby({
    required String name,
    required String mode,
    required int time,
  }) async {
    final url = Uri.parse("$baseUrl/lobbies/create");
    final token = await AuthService().getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизации отсутствует. Сначала войдите в систему.');
    }

    print('DEBUG: Отправка запроса с токеном: Bearer $token');

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "lobby_name": name,
        "selected_mode": mode,
        "time_limit": time,
      }),
    );

    print('DEBUG: Статус: ${response.statusCode}, Тело: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      // ИСПРАВЛЕНО: убрали $Exception
      throw Exception('Ошибка сети: ${response.statusCode}\n${response.body}  token:$token');
    }
  }

  // ИСПРАВЛЕНО: сделали асинхронной
  static Future<Map<String, String>> _headersWithAuth() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await AuthService().getToken(); // Добавили await
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ИСПРАВЛЕНО: сделали асинхронной
  static Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    final token = await AuthService().getToken(); // Добавили await

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> getLobbies() async {
    try {
      // ИСПРАВЛЕНО: await перед вызовом
      final response = await http.get(
        Uri.parse('$baseUrl/lobbies/'),
        headers: await _headersWithAuth(), // Добавили await
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return {'status': 'success', 'data': data};
      } else {
        return {
          'status': 'error',
          'message': '${json.decode(response.body)["error"]["message"]}'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>?> joinLobby(int lobbyId, int? userId) async {
    final url = Uri.parse("$baseUrl/lobbies/$lobbyId/join");
    final headers = await _getHeaders(); // Используем правильные заголовки

    final res = await http.post(
      url,
      headers: headers, // Используем заголовки с авторизацией
      body: jsonEncode({'user_id': userId}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLobby(int lobbyId) async {
    final url = Uri.parse("$baseUrl/lobbies/$lobbyId");
    final headers = await _getHeaders(); // Используем правильные заголовки

    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>> getLobbyDetails(String lobbyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lobbies/$lobbyId'),
        headers: await _getHeaders(), // Добавили await
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Ошибка загрузки лобби',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> setReadyStatus(
      String lobbyId,
      bool isReady,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/ready'),
        headers: await _getHeaders(), // Добавили await
        body: jsonEncode({'is_ready': isReady}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Ошибка установки статуса',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> startGame(String lobbyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/start'),
        headers: await _getHeaders(), // Добавили await
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Ошибка начала игры',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> leaveLobby(String lobbyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/leave'),
        headers: await _getHeaders(), // Добавили await
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Ошибка выхода из лобби',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> kickPlayer(
      String lobbyId,
      String playerId,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/kick'),
        headers: await _getHeaders(), // Добавили await
        body: jsonEncode({'player_id': playerId}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Ошибка исключения игрока',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}