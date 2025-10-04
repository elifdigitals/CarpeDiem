import 'package:flutter/material.dart';

class LobbyListPage extends StatelessWidget {
  final List<Map<String, dynamic>> lobbies;

  const LobbyListPage({super.key, required this.lobbies});

  void _joinLobby(BuildContext context, Map<String, dynamic> lobby) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining "${lobby['name']}"...')),
    );
  }

  Widget _buildLobbyCard(BuildContext context, Map<String, dynamic> lobby, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Text(
            lobby['players'].split('/')[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lobby['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mode: ${lobby['mode']}',
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'by ${lobby['author']}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('⏱️ ${lobby['time']} • 👥 ${lobby['players']}'),
            Text('📍 ${lobby['location']}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _joinLobby(context, lobby),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Join'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Lobbies'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: lobbies.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No lobbies available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to create a lobby!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: lobbies.length,
        itemBuilder: (context, index) => _buildLobbyCard(context, lobbies[index], index),
      ),
    );
  }
}