import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:app/model/app_settings.dart';


abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;

  const UpdateThemeMode({required this.themeMode});

  @override
  List<Object> get props => [themeMode];
}

class UpdateUsername extends SettingsEvent {
  final String username;

  const UpdateUsername({required this.username});

  @override
  List<Object> get props => [username];
}

class UpdateNotificationSettings extends SettingsEvent {
  final bool enabled;

  const UpdateNotificationSettings({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

class UpdateSoundSettings extends SettingsEvent {
  final bool enabled;

  const UpdateSoundSettings({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

class UpdateLobbySettings extends SettingsEvent {
  final int defaultTime;
  final int maxPlayers;

  const UpdateLobbySettings({
    required this.defaultTime,
    required this.maxPlayers,
  });

  @override
  List<Object> get props => [defaultTime, maxPlayers];
}

class UpdateCameraQuality extends SettingsEvent {
  final CameraQuality quality;

  const UpdateCameraQuality({required this.quality});

  @override
  List<Object> get props => [quality];
}

class ResetToDefaults extends SettingsEvent {}