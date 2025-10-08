import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'settings_event.dart';
import 'settings_state.dart';
import 'package:app/model/app_settings.dart';
import 'package:app/repositories/settings_repository.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository settingsRepository;

  SettingsBloc({required this.settingsRepository}) : super(SettingsLoading()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateUsername>(_onUpdateUsername);
    on<UpdateNotificationSettings>(_onUpdateNotificationSettings);
    on<UpdateSoundSettings>(_onUpdateSoundSettings);
    on<UpdateLobbySettings>(_onUpdateLobbySettings);
    on<UpdateCameraQuality>(_onUpdateCameraQuality);
    on<ResetToDefaults>(_onResetToDefaults);
  }

  Future<void> _onLoadSettings(
      LoadSettings event,
      Emitter<SettingsState> emit,
      ) async {
    try {
      final settings = await settingsRepository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onUpdateThemeMode(
      UpdateThemeMode event,
      Emitter<SettingsState> emit,
      ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedSettings = currentState.settings.copyWith(
        themeMode: event.themeMode,
      );

      await settingsRepository.saveSettings(updatedSettings);
      emit(SettingsLoaded(updatedSettings));
    }
  }

  Future<void> _onUpdateUsername(
      UpdateUsername event,
      Emitter<SettingsState> emit,
      ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedSettings = currentState.settings.copyWith(
        username: event.username,
      );

      await settingsRepository.saveSettings(updatedSettings);
      emit(SettingsLoaded(updatedSettings));
    }
  }

  Future<void> _onUpdateNotificationSettings(
      UpdateNotificationSettings event,
      Emitter<SettingsState> emit,
      ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedSettings = currentState.settings.copyWith(
        notificationsEnabled: event.enabled,
      );

      await settingsRepository.saveSettings(updatedSettings);
      emit(SettingsLoaded(updatedSettings));
    }
  }

  Future<void> _onUpdateSoundSettings(
      UpdateSoundSettings event,
      Emitter<SettingsState> emit,
      ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedSettings = currentState.settings.copyWith(
        soundsEnabled: event.enabled,
      );

      await settingsRepository.saveSettings(updatedSettings);
      emit(SettingsLoaded(updatedSettings));
    }
  }

  Future<void> _onUpdateLobbySettings(
      UpdateLobbySettings event,
      Emitter<SettingsState> emit,
      ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedSettings = currentState.settings.copyWith(
        defaultLobbyTime: event.defaultTime,
        maxPlayers: event.maxPlayers,
      );

      await settingsRepository.saveSettings(updatedSettings);
      emit(SettingsLoaded(updatedSettings));
    }
  }

  Future<void> _onUpdateCameraQuality(
      UpdateCameraQuality event,
      Emitter<SettingsState> emit,
      ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedSettings = currentState.settings.copyWith(
        cameraQuality: event.quality,
      );

      await settingsRepository.saveSettings(updatedSettings);
      emit(SettingsLoaded(updatedSettings));
    }
  }

  Future<void> _onResetToDefaults(
      ResetToDefaults event,
      Emitter<SettingsState> emit,
      ) async {
    final defaultSettings = AppSettings(
      themeMode: ThemeMode.system,
      username: 'Player',
      notificationsEnabled: true,
      soundsEnabled: true,
      defaultLobbyTime: 10,
      maxPlayers: 10,
      cameraQuality: CameraQuality.medium,
    );

    await settingsRepository.saveSettings(defaultSettings);
    emit(SettingsLoaded(defaultSettings));
  }
}