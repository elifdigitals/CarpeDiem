// api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:async';


class ApiService {
  static final _client = http.Client();
  static const String baseUrl = 'http://192.168.0.100:8000';

  static int? currentUserId;
  static String? accessToken;
  static String? username;

  static Map<String, String> _headersWithAuth() {
    final headers = {'Content-Type': 'application/json'};
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  static void setAuthData(int userId, String token, String? userUsername) {
    currentUserId = userId;
    accessToken = token;
    username = userUsername;
    print(
      '🔐 Auth data saved: user_id=$userId, username=$userUsername, token=${token.substring(0, 20)}...',
    );
  }

  static Future<Map<String, dynamic>> createLobby(
      String lobby_name,
      String selected_mode,
      int timeLimit,
      ) async {
    try {
      print('🔄 Sending request to: $baseUrl/lobbies/create');
      print('👤 Using accessToken: ${accessToken?.substring(0, 20) ?? "NOT SET"}');

      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/create'),
        headers: _headersWithAuth(),
        body: json.encode({
          'lobby_name': lobby_name,
          'selected_mode': selected_mode,
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
          'message': 'HTTP Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> joinLobby(String lobbyId) async {
    try {
      print('🔄 Joining lobby: $baseUrl/lobbies/$lobbyId/join');
      print('👤 Using accessToken: ${accessToken?.substring(0, 20) ?? "NOT SET"}');

      final response = await http.post(
        Uri.parse('$baseUrl/lobbies/$lobbyId/join'),
        headers: _headersWithAuth(),
      );

      print('📨 Join lobby response status: ${response.statusCode}');
      print('📨 Join lobby response body: ${response.body}');

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': json.decode(response.body)};
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLobbies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lobbies/'),
        headers: _headersWithAuth(),
      );

      print('📨 Get lobbies response status: ${response.statusCode}');
      print('📨 Get lobbies response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return {'status': 'success', 'data': data};
      } else {
        return {
          'status': 'error',
          'message': 'Failed to load lobbies: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadPhoto(
      File imageFile,
      String lobbyId,
      ) async {
    try {
      print('🔄 Uploading photo to lobby: $lobbyId');
      print('👤 Using accessToken: ${accessToken?.substring(0, 20) ?? "NOT SET"}');

      // Создаем multipart запрос
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/photos/$lobbyId/upload'),
      );

      // Добавляем заголовок авторизации
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Проверяем существование файла
      if (!await imageFile.exists()) {
        print('❌ File does not exist: ${imageFile.path}');
        return {'status': 'error', 'message': 'File does not exist'};
      }

      // Получаем размер файла
      final fileLength = await imageFile.length();
      print('📁 File size: ${fileLength} bytes');

      // Добавляем файл
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: 'photo_${DateTime.now().microsecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      print('📤 Sending request to: ${request.url}');

      // Отправляем запрос с таймаутом
      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload timed out after 30 seconds');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('📨 Upload photo response status: ${response.statusCode}');
      print('📨 Upload photo response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {'status': 'success', 'data': responseData};
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('❌ Photo upload error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
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
        body: json.encode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );

      print('📨 Registration response status: ${response.statusCode}');
      print('📨 Registration response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['user_id'] != null &&
            responseData['access_token'] != null) {
          setAuthData(
            responseData['user_id'],
            responseData['access_token'],
            responseData['username'],
          );
        }
        return {'status': 'success', 'data': responseData};
      } else {
        final errorData = json.decode(response.body);
        return {
          'status': 'error',
          'message': errorData['detail'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

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

      print('📨 Login response status: ${response.statusCode}');
      print('📨 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final userId = responseData['user_id'] ?? 1;
        setAuthData(
          userId,
          responseData['access_token'],
          responseData['username'],
        );
        return {'status': 'success', 'data': responseData};
      } else {
        final errorData = json.decode(response.body);
        return {
          'status': 'error',
          'message': errorData['detail'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> leaveLobby(String lobbyId) async {
    try {
      print('🔄 Leaving lobby: $baseUrl/lobbies/$lobbyId/leave');
      print('👤 Using accessToken: ${accessToken?.substring(0, 20) ?? "NOT SET"}');

      final response = await http.delete(
        Uri.parse('$baseUrl/lobbies/$lobbyId/leave'),
        headers: _headersWithAuth(),
      );

      print('📨 Leave lobby response status: ${response.statusCode}');
      print('📨 Leave lobby response body: ${response.body}');

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': json.decode(response.body)};
      } else {
        return {
          'status': 'error',
          'message': 'HTTP Error ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ Network error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/current_user'),
        headers: _headersWithAuth(),
      );

      print('📨 Current user response status: ${response.statusCode}');
      print('📨 Current user response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {'status': 'success', 'data': responseData};
      } else {
        return {
          'status': 'error',
          'message': 'Failed to load current user: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserStats(int userId) async {
    return {'status': 'error', 'message': 'Endpoint not implemented'};
  }

  static Future<Map<String, dynamic>> getUserGames(int userId) async {
    return {'status': 'error', 'message': 'Endpoint not implemented'};
  }
}
