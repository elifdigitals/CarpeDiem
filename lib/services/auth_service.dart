import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:app/exceptions/form_exceptions.dart';
import 'package:app/exceptions/secure_storage_exceptions.dart';
import 'package:app/model/user_model.dart';
import 'package:app/services/helper_service.dart';
import 'package:app/services/secure_storage_service.dart';

class AuthService {
  static const String loginPath = 'auth/login';
  static const String registerPath = 'auth/register';
  static const String passwordResetPath = 'auth/password/reset/';
  static const String passwordResetConfirmPath = 'auth/password/reset/confirm/';
  static const String refreshPath = 'token/refresh/';
  static const String verifyPath = 'token/verify/';
  static const String lobbyPath = 'lobby/lobby/';

  static Future<User> loadUser() async {
    final json = await SecureStorageService.storage.read(
      key: SecureStorageService.userKey,
    );
    if (json != null) {
      return User.fromJson(jsonDecode(json));
    } else {
      throw SecureStorageNotFoundException();
    }
  }

  static void saveUser(User user) async {
    await SecureStorageService.storage.write(
      key: SecureStorageService.userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  static Future<void> refreshToken(User user) async {
    print(HelperService.buildUri(loginPath));
    final response = await http.post(
      HelperService.buildUri(refreshPath),
      headers: HelperService.buildHeaders(),
      body: jsonEncode(
        {
          'refresh': user.refreshToken,
        },
      ),
    ).timeout(Duration(seconds: 10));

    final statusType = (response.statusCode / 100).floor() * 100;
    switch (statusType) {
      case 200:
        final json = jsonDecode(response.body);
        user.accessToken = json['access'];
        saveUser(user);
        break;
      case 400:
      case 300:
      case 500:
      default:
        throw Exception('Error contacting the server!');
    }
  }

  static Future<User> register({
    required String email,
    required String password,
    required String username
  }) async {
    final uri = HelperService.buildUri(registerPath);
    final headers = HelperService.buildHeaders();
    final body = jsonEncode({
      'username': username,
      'email': email,
      'password': password
    });

    print('=== REGISTER REQUEST ===');
    print('URL: $uri');
    print('Headers: $headers');
    print('Body: $body');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 10));

      print('=== REGISTER RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      final statusType = (response.statusCode / 100).floor() * 100;
      switch (statusType) {
        case 200:
        case 201:
          final json = jsonDecode(response.body);
          final user = User.fromJson(json);
          saveUser(user);
          return user;

        case 400:
          final json = jsonDecode(response.body);
          print('=== 400 ERROR DETAILS ===');
          print('Error JSON: $json');
          throw handleFormErrors(json);

        case 300:
        case 500:
        default:
          print('=== SERVER ERROR ===');
          print('Status: ${response.statusCode}');
          print('Body: ${response.body}');
          throw FormGeneralException(message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('=== NETWORK ERROR ===');
      print('Error: $e');
      rethrow;
    }
  }

  static Future<void> requestPasswordRecovery({
    required String email,
  }) async {
    final uri = HelperService.buildUri(passwordResetPath);
    final headers = HelperService.buildHeaders();
    final body = jsonEncode({'email': email});

    print('=== PASSWORD RESET REQUEST ===');
    print('URL: $uri');
    print('Body: $body');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 10));

      print('=== PASSWORD RESET RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      final statusType = (response.statusCode / 100).floor() * 100;
      switch (statusType) {
        case 200:
        case 201:
          return;
        case 400:
          final json = jsonDecode(response.body);
          throw handleFormErrors(json);
        case 300:
        case 500:
        default:
          throw FormGeneralException(message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('=== NETWORK ERROR ===');
      print('Error: $e');
      rethrow;
    }
  }

  
  static Future<void> confirmPasswordRecovery({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    final uri = HelperService.buildUri(passwordResetConfirmPath);
    final headers = HelperService.buildHeaders();
    final body = jsonEncode({
      'uid': uid,
      'token': token,
      'new_password1': newPassword,
      'new_password2': newPassword,
    });

    print('=== PASSWORD RESET CONFIRM REQUEST ===');
    print('URL: $uri');
    print('Body: $body');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(Duration(seconds: 10));

      print('=== PASSWORD RESET CONFIRM RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      final statusType = (response.statusCode / 100).floor() * 100;
      switch (statusType) {
        case 200:
        case 201:
          return;
        case 400:
          final json = jsonDecode(response.body);
          throw handleFormErrors(json);
        case 300:
        case 500:
        default:
          throw FormGeneralException(message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('=== NETWORK ERROR ===');
      print('Error: $e');
      rethrow;
  }
    }


  static Future<void> logout() async {
    await SecureStorageService.storage.delete(
      key: SecureStorageService.userKey,
    );
  }

  static Future<User> login({
    required String email,
    required String password,
  }) async {
    print(HelperService.buildUri(loginPath));
    print(jsonEncode({
      'email': email,
      'password': password,
    }));
    final response = await http.post(

      HelperService.buildUri(loginPath),
      headers: HelperService.buildHeaders(),
      body: jsonEncode(
        {
          'email': email,
          'password': password,
        },
      ),
    ).timeout(Duration(seconds: 10));

    final statusType = (response.statusCode / 100).floor() * 100;
    print('statusCode: ${response.statusCode}');
    print('body: ${response.body}');
    switch (statusType) {
      case 200:
        final json = jsonDecode(response.body);

        if (json.containsKey('access')) {
          json['access_token'] = json['access'];
        }

        final user = User.fromJson(json);
        saveUser(user);
        return user;

      case 400:
        final json = jsonDecode(response.body);
        throw handleFormErrors(json);

      case 300:

      case 500:
      default:
        throw FormGeneralException(message: 'Error contacting the server!');
    }
  }


}