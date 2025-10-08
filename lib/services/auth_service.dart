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
  static const String refreshPath = 'token/refresh/';
  static const String verifyPath = 'token/verify/';

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
      value: user.toJson(),
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
    print(HelperService.buildUri(registerPath));
    print(jsonEncode({
      'email': email,
      'password': password,
      'username': username
    }));
    final response = await http.post(

      HelperService.buildUri(registerPath),
      headers: HelperService.buildHeaders(),
      body: jsonEncode(
        {
          'username': username,
          'email': email,
          'password': password

        },
      ),
    ).timeout(Duration(seconds: 10));
    print('statusCode: ${response.statusCode}');
    print('body: ${response.body}');

    final statusType = (response.statusCode / 100).floor() * 100;
    switch (statusType) {
      case 200:
        final json = jsonDecode(response.body);
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