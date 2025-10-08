import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final String username;
  final bool notificationsEnabled;
  final bool soundsEnabled;
  final int defaultLobbyTime;
  final int maxPlayers;
  final CameraQuality cameraQuality;

  const AppSettings({
    required this.themeMode,
    required this.username,
    this.notificationsEnabled = true,
    this.soundsEnabled = true,
    this.defaultLobbyTime = 10,
    this.maxPlayers = 10,
    this.cameraQuality = CameraQuality.medium,
  });

  @override
  List<Object?> get props => [
    themeMode,
    username,
    notificationsEnabled,
    soundsEnabled,
    defaultLobbyTime,
    maxPlayers,
    cameraQuality,
  ];

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? username,
    bool? notificationsEnabled,
    bool? soundsEnabled,
    int? defaultLobbyTime,
    int? maxPlayers,
    CameraQuality? cameraQuality,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      username: username ?? this.username,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundsEnabled: soundsEnabled ?? this.soundsEnabled,
      defaultLobbyTime: defaultLobbyTime ?? this.defaultLobbyTime,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      cameraQuality: cameraQuality ?? this.cameraQuality,
    );
  }
}


enum CameraQuality { low, medium, high }