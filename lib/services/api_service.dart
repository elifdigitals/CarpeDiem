import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const _storage = FlutterSecureStorage();


  static Future<void> saveSession(String token, int userId) async {
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_id', value: userId.toString());
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }


  static Future<String> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] ?? '';
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  static Future<String> register(String email, String username, String password) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);

      // return await login(email, password);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  static Future<void> createProfile({
    required int userId,
    required String fullName,
    required String birthDate,
    required String location,
    required String phone,
    required File photo,
  }) async {
    final uri = Uri.parse('$baseUrl/profile/$userId/create');

    var request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = userId.toString();
    request.fields['full_name'] = fullName;
    request.fields['birth_date'] = birthDate;
    request.fields['location'] = location;
    request.fields['phone'] = phone;


    var multipartFile = await http.MultipartFile.fromPath(
      'photo',
      photo.path,
    );
    request.files.add(multipartFile);

    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка создания профиля: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  static Future<String> getLobbies() async {
    final uri = Uri.parse('$baseUrl/lobbies');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      print('Response data: ${response.body}');
      return response.body;
    } else {
    print('Request failed with status: ${response.statusCode}.');
    return "";
    }
    Future<void> createLobby({
    required String baseUrl,
    required String lobbyName,
    required String selectedMode,
    required int timeLimit,
    }) async {
    final url = Uri.parse('$baseUrl/lobbies');

    final response = await http.post(
      url,
      headers: {
          'Content-Type': 'application/json',
      },
      body: jsonEncode({
          'lobbyName': lobbyName,
          'selectedMode': selectedMode,
          'timeLimit': timeLimit,
          }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Лобби успешно создано: ${response.body}');
    } else {
      print('Ошибка: ${response.statusCode} — ${response.body}');
      }
    }
  }
}