// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static String? _authToken;
  static String? _currentUserId;
  static Map<String, dynamic>? _currentUserData;

  static String? get currentUserId => _currentUserId;
  static String? get authToken => _authToken;

  // Установка данных пользователя после авторизации
  // Инициализация ApiService: загрузка сохранённой сессии
  static const String _kTokenKey = 'carpediem_auth_token';
  static const String _kUserIdKey = 'carpediem_user_id';

  /// Load saved session (if any). Call this before `runApp`.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_kTokenKey);
      _currentUserId = prefs.getString(_kUserIdKey);
    } catch (e) {
      // If shared_preferences fails, keep in-memory state null
    }
  }

  /// Save session to persistent storage and update in-memory state
  static Future<void> setUserData(
    String token,
    String userId,
    Map<String, dynamic> userData,
  ) async {
    _authToken = token;
    _currentUserId = userId;
    _currentUserData = {
      'user_id': userId,
      'username': userData['username'],
      'email': userData['email'],
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, token);
      await prefs.setString(_kUserIdKey, userId);
    } catch (e) {
      // ignore persistent save errors (app still works in-memory)
    }
  }

  /// Clear session (logout)
  static Future<void> clearSession() async {
    _authToken = null;
    _currentUserId = null;
    _currentUserData = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTokenKey);
      await prefs.remove(_kUserIdKey);
    } catch (e) {
      // ignore
    }
  }

  // Получение заголовков с токеном
  static Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // =========== АВТОРИЗАЦИЯ ===========
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Сохраняем данные пользователя и persist в SharedPreferences
        final token = result['access_token'] ?? result['token'] ?? '';
        final userId = (result['user_id'] ?? result['id'] ?? '').toString();
        await setUserData(token, userId, {
          'username': result['username'] ?? '',
          'email': result['email'] ?? '',
        });

        return {
          'status': 'success',
          'data': {
            'token': token,
            'user_id': userId,
            'username': result['username'] ?? '',
            'email': result['email'] ?? '',
          },
        };
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Ошибка авторизации',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String email,
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        final token = result['access_token'] ?? result['token'] ?? '';
        final userId = (result['user_id'] ?? result['id'] ?? '').toString();
        await setUserData(token, userId, {
          'username': result['username'] ?? '',
          'email': result['email'] ?? '',
        });

        return {
          'status': 'success',
          'data': {
            'token': token,
            'user_id': userId,
            'username': result['username'] ?? '',
            'email': result['email'] ?? '',
          },
        };
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Ошибка регистрации',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  // =========== ЛОББИ ===========
  static Future<Map<String, dynamic>> createLobby(
    String name,
    String mode,
    int timeLimit,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/create'),
        headers: _getHeaders(),
        body: jsonEncode({'name': name, 'mode': mode, 'time_limit': timeLimit}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Ошибка создания лобби',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLobbies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lobbies/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final dynamic result = jsonDecode(response.body);

        // Обрабатываем разные форматы ответа
        if (result is List) {
          return {'status': 'success', 'data': result};
        } else if (result is Map<String, dynamic>) {
          return result;
        } else {
          return {'status': 'success', 'data': []};
        }
      } else {
        return {
          'status': 'error',
          'message': 'Failed to load lobbies: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLobbyDetails(String lobbyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lobbies/$lobbyId'),
        headers: _getHeaders(),
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

  static Future<Map<String, dynamic>> joinLobby(String lobbyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/join'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Ошибка присоединения',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> setReadyStatus(
    String lobbyId,
    bool isReady,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/ready'),
        headers: _getHeaders(),
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
        headers: _getHeaders(),
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

  // =========== COUNTDOWN SYNC ==========
  static Future<Map<String, dynamic>> startCountdown(String lobbyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/start_countdown'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        final result = jsonDecode(response.body);
        return {'status': 'error', 'message': result['detail'] ?? 'Ошибка'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCountdownStatus(String lobbyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lobbies/$lobbyId/countdown_status'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        return {'status': 'error', 'message': 'Ошибка получения статуса'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> leaveLobby(String lobbyId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/leave'),
        headers: _getHeaders(),
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
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> kickPlayer(
    String lobbyId,
    String playerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/kick'),
        headers: _getHeaders(),
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

  // =========== ПОИСК ПО КОДУ ===========
  static Future<Map<String, dynamic>> searchLobbyByCode(String code) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lobbies/search/${code.toUpperCase()}'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {'status': 'success', 'data': result};
      } else {
        final result = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': result['detail'] ?? 'Лобби не найдено',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  // =========== ПОЛЬЗОВАТЕЛЬ ===========
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      if (_currentUserId == null) {
        return {'status': 'error', 'message': 'Пользователь не авторизован'};
      }

      // Используем данные из памяти
      if (_currentUserData != null) {
        return {'status': 'success', 'data': _currentUserData};
      }

      // Если данных нет, пытаемся получить с сервера
      final response = await http.get(
        Uri.parse('$baseUrl/user/$_currentUserId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _currentUserData = result;
        return {'status': 'success', 'data': result};
      } else {
        return {
          'status': 'error',
          'message': 'Не удалось загрузить данные пользователя',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/stats'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        return {'status': 'error', 'message': 'Ошибка загрузки статистики'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserGames(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/games'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        return {'status': 'error', 'message': 'Ошибка загрузки игр'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  // =========== ЗАГРУЗКА ФОТО ===========
  static Future<Map<String, dynamic>> uploadPhoto(
    String lobbyId,
    File photoFile,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/photo/upload'),
      );

      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      request.fields['lobby_id'] = lobbyId;
      if (currentUserId != null) {
        request.fields['user_id'] = currentUserId!;
      }

      request.files.add(
        await http.MultipartFile.fromPath('photo', photoFile.path),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': result};
      } else {
        return {
          'status': 'error',
          'message': result['message'] ?? 'Ошибка загрузки фото',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  // =========== ВЫХОД ===========
  static void logout() {
    _authToken = null;
    _currentUserId = null;
    _currentUserData = null;
  }

  // =========== ВАЛИДАЦИЯ ТОКЕНА ===========
  static Future<bool> validateToken() async {
    if (_authToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/validate'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) return false;
      final result = jsonDecode(response.body);
      return result['status'] == 'success';
    } catch (e) {
      return false;
    }
  }
}
