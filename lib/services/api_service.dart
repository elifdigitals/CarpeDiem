import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<String> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': email,
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
    final uri = Uri.parse('$baseUrl/register');
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
      final data = jsonDecode(response.body);
      if (data.containsKey('access_token')) {
        return data['access_token'];
      }

      return await login(email, password);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  static Future<String> getLobbies() async {
    final uri = Uri.parse('$baseUrl/lobbies');
    final response = await http.(uri);

    if (response.statusCode == 200) {
          print('Response data: ${response.body}');
        } else {
          print('Request failed with status: ${response.statusCode}.');
        }
  }
}
