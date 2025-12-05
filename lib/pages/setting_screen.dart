import 'package:flutter/material.dart';

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
              // Здесь потом интегрируем твой logout
              Navigator.pop(context);
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
