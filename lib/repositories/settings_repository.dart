import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/model/app_settings.dart';
import 'package:flutter/material.dart';

class SettingsRepository {
  static const String _settingsKey = 'app_settings';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString != null) {
      return _parseSettings(jsonString);
    } else {
      return AppSettings(
        themeMode: ThemeMode.system,
        username: 'Player',
        notificationsEnabled: true,
        soundsEnabled: true,
        defaultLobbyTime: 10,
        maxPlayers: 10,
        cameraQuality: CameraQuality.medium,
      );
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = _settingsToJson(settings);
    await prefs.setString(_settingsKey, jsonString);
  }

  AppSettings _parseSettings(String jsonString) {
    final Map<String, dynamic> json = {
      'themeMode': ThemeMode.system,
      'username': 'Player',
      'notificationsEnabled': true,
      'soundsEnabled': true,
      'defaultLobbyTime': 10,
      'maxPlayers': 10,
      'cameraQuality': 'medium',
    };

    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      username: json['username'] ?? 'Player',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundsEnabled: json['soundsEnabled'] ?? true,
      defaultLobbyTime: json['defaultLobbyTime'] ?? 10,
      maxPlayers: json['maxPlayers'] ?? 10,
      cameraQuality: CameraQuality.values[json['cameraQuality'] ?? 1],
    );
  }

  String _settingsToJson(AppSettings settings) {
    return '{}';
  }
}