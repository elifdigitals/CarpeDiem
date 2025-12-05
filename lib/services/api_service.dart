import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  // ДОБАВЛЕНО: Хранение данных пользователя
  static int? currentUserId;
  static String? accessToken;

  // ДОБАВЛЕНО: Сохранение данных аутентификации
  static void setAuthData(int userId, String token) {
    currentUserId = userId;
    accessToken = token;
    print(
      '🔐 Auth data saved: user_id=$userId, token=${token.substring(0, 20)}...',
    );
  }

  // ИСПРАВЛЕНО: Использовать currentUserId вместо хардкода
  static Future<Map<String, dynamic>> createLobby(
    String name,
    String mode,
    int timeLimit,
  ) async {
    try {
      print('🔄 Sending request to: $baseUrl/lobbies/create');
      print('👤 Using user_id: ${currentUserId ?? "NOT SET"}');

      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'host_id': currentUserId ?? 1,
          'mode': mode,
          'name': name,
          'time_limit': timeLimit,
        }),
      );

      print('📨 Response status: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': json.decode(response.body)};
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ИСПРАВЛЕНО: Правильное приведение типов
  static Future<Map<String, dynamic>> getLobbies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/lobbies/'));

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is Map<String, dynamic> && data.containsKey('status')) {
          return data;
        } else if (data is List<dynamic>) {
          return {'status': 'success', 'data': data};
        } else if (data is Map<String, dynamic>) {
          return {'status': 'success', 'data': data};
        } else {
          return {'status': 'success', 'data': data};
        }
      } else {
        return {'status': 'error', 'message': 'Failed to load lobbies'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ДОБАВЛЕНО: Сохранять auth data после регистрации
  static Future<Map<String, dynamic>> register(
    String email,
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );
      print('📨 Registration response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['user_id'] != null &&
            responseData['access_token'] != null) {
          setAuthData(responseData['user_id'], responseData['access_token']);
        }
        return {'status': 'success', 'data': responseData};
      } else {
        return {'status': 'error', 'message': 'Registration failed'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // ДОБАВЛЕНО: Сохранять auth data после входа
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final userId = responseData['user_id'] ?? 1;
        setAuthData(userId, responseData['access_token']);
        return {'status': 'success', 'data': responseData};
      } else {
        return {'status': 'error', 'message': 'Login failed'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // НОВЫЙ МЕТОД: Получить статистику пользователя
  static Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId/stats'));

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': json.decode(response.body)};
      } else {
        return {'status': 'error', 'message': 'Failed to load user stats'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // НОВЫЙ МЕТОД: Получить игры пользователя
  static Future<Map<String, dynamic>> getUserGames(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId/games'));

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': json.decode(response.body)};
      } else {
        return {'status': 'error', 'message': 'Failed to load user games'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // НОВЫЙ МЕТОД: Получить текущего пользователя
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/auth/current_user'));

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': json.decode(response.body)};
      } else {
        return {'status': 'error', 'message': 'Failed to load current user'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }
}
