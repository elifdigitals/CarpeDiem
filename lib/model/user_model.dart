import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:app/exceptions/user_exceptions.dart';
import 'package:app/services/auth_service.dart';

class User {
  final String id;
  String email;
  String username;
  String accessToken;
  String refreshToken;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.accessToken,
    required this.refreshToken,
  }) {
    // if (isValidRefreshToken()) {
    //   getNewToken();
    // } else {
    //   throw InvalidUserException();
    // }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    print('=== PARSING USER FROM JSON ===');
    print('JSON keys: ${json.keys}');

    // отладка
    final id = json['userId'] ?? json['username'] ?? 'unknown';
    final email = json['email'] ?? json['userEmail'] ?? '';
    final username = json['username'] ?? json['userUsername'] ?? '';
    final accessToken = json['access'] ?? json['access_token'] ?? '';
    final refreshToken = json['refresh'] ?? json['refresh_token'] ?? '';

    print('Parsed values:');
    print('id: $id');
    print('email: $email');
    print('username: $username');
    print('accessToken: ${accessToken.isNotEmpty ? "***" : "EMPTY"}');
    print('refreshToken: ${refreshToken.isNotEmpty ? "***" : "EMPTY"}');

    if (accessToken.isEmpty) {
      print('ERROR: No access token found in response');
      throw InvalidUserException();
    }

    return User(
      id: id,
      email: email,
      username: username,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  bool isValidRefreshToken() {
    try {
      if (refreshToken.isEmpty) return false;
      final jwtData = JwtDecoder.decode(refreshToken);
      return jwtData['exp'] > DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (e) {
      return false;
    }
  }

  void getNewToken() async {
    try {
      if (!isValidRefreshToken()) {
        print('Refresh token is invalid');
        return;
      }

      final jwtData = JwtDecoder.decode(accessToken);
      final expiryTime = jwtData['exp'] * 1000;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeUntilExpiry = expiryTime - currentTime;

      if (timeUntilExpiry > 0) {
        await Future.delayed(Duration(milliseconds: timeUntilExpiry));
      }

      await AuthService.refreshToken(this);
      getNewToken();
    } catch (e) {
      print('Error refreshing token: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'userEmail': email,
      'userUsername': username,
      "access": accessToken,
      "refresh": refreshToken,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}