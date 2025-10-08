import 'package:flutter/material.dart';
import 'package:app/screens/settings/bloc/settings_bloc.dart';
import 'package:app/screens/settings/bloc/settings_event.dart';
import 'package:app/screens/settings/bloc/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildProfileSection(),
          _buildAppearanceSection(),
          _buildGameSettingsSection(),
          // _buildNotificationsSection(),
          // _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // ListTile(
            //   leading: const Icon(Icons.person),
            //   title: const Text('Username'),
            //   subtitle: const Text('Current: Player123'),
            //   trailing: IconButton(
            //     icon: const Icon(Icons.edit),
            //     onPressed: () => _showUsernameDialog(context),
            //   ),
            // ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: const Text('user@example.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                if (state is SettingsLoaded) {
                  return ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Theme'),
                    subtitle: const Text('Choose app theme'),
                    trailing: DropdownButton<ThemeMode>(
                      value: state.settings.themeMode,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (theme) {
                        context.read<SettingsBloc>().add(
                          UpdateThemeMode(themeMode: theme!),
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSettingsSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Game Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Default Lobby Time'),
              subtitle: const Text('10 minutes'),
              trailing: DropdownButton<int>(
                value: 10,
                items: [5, 10, 15, 20].map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text('$time min'),
                  );
                }).toList(),
                onChanged: (time) {
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Max Players'),
              subtitle: const Text('10 players'),
              trailing: DropdownButton<int>(
                value: 10,
                items: [4, 6, 8, 10, 12].map((players) {
                  return DropdownMenuItem(
                    value: players,
                    child: Text('$players'),
                  );
                }).toList(),
                onChanged: (players) {
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}