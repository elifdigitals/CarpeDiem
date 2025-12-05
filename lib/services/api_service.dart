import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static String? _authToken;
  static String? _currentUserId;
  static Map<String, dynamic>? _currentUserData;

  static String? get currentUserId => _currentUserId;
  static String? get authToken => _authToken;

  // Установка данных пользователя после авторизации
  static void setUserData(
    String token,
    String userId,
    Map<String, dynamic> userData,
  ) {
    _authToken = token;
    _currentUserId = userId;
    _currentUserData = {
      'user_id': userId,
      'username': userData['username'],
      'email': userData['email'],
    };
    print('🔑 User data set: ${_currentUserData}');
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
      print('🔐 Attempting login for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('📨 Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Сохраняем данные пользователя
        _authToken = result['access_token'];
        _currentUserId = result['user_id'].toString();
        _currentUserData = {
          'user_id': _currentUserId,
          'username': result['username'],
          'email': result['email'],
        };

        print('✅ Login successful, user_id: $_currentUserId');

        // Возвращаем в формате, который ожидает фронтенд
        return {
          'status': 'success',
          'data': {
            'token': _authToken,
            'user_id': _currentUserId,
            'username': result['username'],
            'email': result['email'],
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
      print('❌ Login error: $e');
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> register(
    String email,
    String username,
    String password,
  ) async {
    try {
      print('👤 Registering user: $username ($email)');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      print('📨 Register response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        _authToken = result['access_token'];
        _currentUserId = result['user_id'].toString();
        _currentUserData = {
          'user_id': _currentUserId,
          'username': result['username'],
          'email': result['email'],
        };

        print('✅ Registration successful, user_id: $_currentUserId');

        return {
          'status': 'success',
          'data': {
            'token': _authToken,
            'user_id': _currentUserId,
            'username': result['username'],
            'email': result['email'],
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
      print('❌ Register error: $e');
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
      print('🎯 Creating lobby: $name, mode: $mode');
      print(
        '📤 Sending POST to: $baseUrl/lobbies/create',
      ); // Добавлено для отладки

      // ИСПРАВЛЕНИЕ: меняем с /lobbies/ на /lobbies/create
      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/create'), // ← ВОТ ИСПРАВЛЕНИЕ
        headers: _getHeaders(),
        body: jsonEncode({'name': name, 'mode': mode, 'time_limit': timeLimit}),
      );

      print('📨 Create lobby response: ${response.statusCode}');
      print('📨 Create lobby body: ${response.body}');

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
      print('❌ Create lobby error: $e');
      return {'status': 'error', 'message': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLobbies() async {
    try {
      print('📋 Fetching lobbies...');

      // ИЗМЕНЕНИЕ: Обработка случая, когда возвращается список
      final response = await http.get(
        Uri.parse('$baseUrl/lobbies/'),
        headers: _getHeaders(),
      );

      print('📨 Get lobbies response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Если бэкенд возвращает список, оборачиваем его в нужный формат
        if (result is List) {
          return {'status': 'success', 'data': result};
        } else {
          // Если уже объект, возвращаем как есть
          return result;
        }
      } else {
        print('❌ Failed to get lobbies: ${response.body}');
        return {
          'status': 'error',
          'message': 'Failed to load lobbies: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Get lobbies error: $e');
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
      print('🎮 Joining lobby: $lobbyId');

      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/join'),
        headers: _getHeaders(),
      );

      print('📨 Join lobby response: ${response.statusCode}');

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
      print('❌ Join lobby error: $e');
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

  // =========== ПОЛЬЗОВАТЕЛЬ ===========
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      if (_currentUserId == null) {
        return {'status': 'error', 'message': 'Пользователь не авторизован'};
      }

      // ИЗМЕНЕНИЕ: Используем данные из памяти
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
        // ИЗМЕНЕНИЕ: Возвращаем как есть, т.к. бэкенд уже возвращает {status, data}
        return result;
      } else {
        return {'status': 'error', 'message': 'Ошибка загрузки статистики'};
      }
    } catch (e) {
      print('❌ Get user stats error: $e');
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
        // ИЗМЕНЕНИЕ: Возвращаем как есть
        return result;
      } else {
        return {'status': 'error', 'message': 'Ошибка загрузки игр'};
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
    print('👋 User logged out');
  }

  // =========== ВАЛИДАЦИЯ ТОКЕНА ===========
  static Future<bool> validateToken() async {
    if (_authToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/validate_token'),
        headers: _getHeaders(),
      );

      final result = jsonDecode(response.body);
      return result['status'] == 'success';
    } catch (e) {
      return false;
    }
  }

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
}
