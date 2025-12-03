import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';


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
      await AuthStorage.saveUser(
        data["user_id"],
        data["access_token"],
      );

    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> register(
      String email,
      String username,
      String password,
      ) async {
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
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      await AuthStorage.saveUser(
        responseData["user_id"],
        responseData["access_token"],
      );
      return responseData as Map<String, dynamic>;
    } else {
      final error = responseData;
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
    final uri = Uri.parse('$baseUrl/profile/create');

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

  static Future<Map<String, dynamic>> getProfile(int userId) async {
    final uri = Uri.parse('$baseUrl/profile/$userId');
    final token = await AuthStorage.getToken();

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load profile");
    }
  }

  static Future<bool> updateProfile({
    required int userId,
    required String fullName,
    required String location,
    required String phone,
    required String birthDate,
    File? photoFile,
  }) async {
    final uri = Uri.parse('$baseUrl/profile/update/$userId');
    final token = await AuthStorage.getToken();

    final request = http.MultipartRequest("PUT", uri);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['full_name'] = fullName;
    request.fields['location'] = location;
    request.fields['phone'] = phone;
    request.fields['birth_date'] = birthDate;

    if (photoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('photo', photoFile.path),
      );
    }

    final response = await request.send();

    return response.statusCode == 200;
  }

  Future<File?> takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked == null) return null;

    return File(picked.path);
  }
}

class AuthStorage {
  static Future<void> saveUser(int userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setString('token', token);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}