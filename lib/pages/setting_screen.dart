import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'welcome_screen.dart';
import 'profile_edit_screen.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool soundEffectsEnabled = true;
  bool darkModeEnabled = false;
  double volumeLevel = 0.7;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          _sectionTitle("Application"),

          SwitchListTile(
            title: const Text("Enable notifications"),
            value: notificationsEnabled,
            onChanged: (val) {
              setState(() => notificationsEnabled = val);
            },
          ),

          SwitchListTile(
            title: const Text("Sound effects"),
            value: soundEffectsEnabled,
            onChanged: (val) {
              setState(() => soundEffectsEnabled = val);
            },
          ),

          ListTile(
            title: const Text("Volume"),
            subtitle: Slider(
              value: volumeLevel,
              onChanged: (value) {
                setState(() => volumeLevel = value);
              },
            ),
          ),

          const Divider(),
          _sectionTitle("Interface"),

          SwitchListTile(
            title: const Text("Dark mode"),
            value: darkModeEnabled,
            onChanged: (val) {
              setState(() => darkModeEnabled = val);
            },
          ),

          ListTile(
            title: const Text("Language"),
            subtitle: const Text("English"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Пока заглушка
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Language selection coming soon")),
              );
            },
          ),

          const Divider(),
          _sectionTitle("Account"),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log out", style: TextStyle(color: Colors.red)),
            onTap: () {
              AuthService().logout();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text("Edit profile", style: TextStyle(color: Colors.blue)),
            onTap: () async {
              setState(() => _isLoading = true);

              try {
                final userId = await AuthService().getUserId();

                if (userId != null) {
                  final profileData = await ApiService.getProfile(userId);

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileEditScreen(profile: profileData),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("User ID not found")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error loading profile: $e")),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}
