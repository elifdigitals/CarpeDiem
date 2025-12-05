import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onStore;
  final int userId;

  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onStore,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final token = await AuthService().getToken();

    final res = await http.get(
      Uri.parse("http://10.0.2.2:8000/profile/${widget.userId}"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    setState(() {
      profile = jsonDecode(res.body);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profile == null) {
      return Scaffold(body: Center(child: Text("Ошибка загрузки профиля")));
    }

    // ====== Маппинг данных с бэка ======
    final userStats = {
      'nickname': profile!['full_name'] ?? "User",
      'level': profile!['level'] ?? 1,
      'totalScore': profile!['total_score'] ?? 0,
      'gamesPlayed': profile!['games_played'] ?? 0,
      'gamesWon': profile!['games_won'] ?? 0,
      'photosTaken': profile!['photos_taken'] ?? 0,
      'challengesCompleted': profile!['challenges_completed'] ?? 0,
      'winRate': profile!['win_rate'] ?? 0,
      'currentExp': profile!['exp_current'] ?? 0,
      'nextLevelExp': profile!['exp_next'] ?? 1000,
    };

    final recentGames = List<Map<String, dynamic>>.from(
      profile!['recent_games'] ?? [],
    );

    final achievements = List<Map<String, dynamic>>.from(
      profile!['achievements'] ?? [],
    );

    double expPercent = userStats['nextLevelExp'] == 0
        ? 0
        : (userStats['currentExp'] / userStats['nextLevelExp']);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEFF6FF),
              Color(0xFFEEF2FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ===== USER CARD =====
                        _buildUserCard(userStats, expPercent),

                        SizedBox(height: 16),

                        // ===== TABS =====
                        _buildTabs(context, userStats, recentGames, achievements),

                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: widget.onBack, icon: Icon(Icons.arrow_back)),
          Text("Профиль",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          IconButton(onPressed: widget.onStore, icon: Icon(Icons.settings)),
        ],
      ),
    );
  }

  // ======= USER CARD =======
  Widget _buildUserCard(Map<String, dynamic> userStats, double expPercent) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('📸', style: TextStyle(fontSize: 28)),
                  ),
                ),
                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userStats['nickname'],
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 16, color: Colors.yellow.shade300),
                          SizedBox(width: 6),
                          Text(
                            'Уровень ${userStats['level']}',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                TextButton.icon(
                  onPressed: widget.onStore,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(Icons.workspace_premium, size: 18),
                  label: Text("Премиум"),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Experience bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Опыт: ${userStats['currentExp']}/${userStats['nextLevelExp']}",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "${(expPercent * 100).round()}%",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: expPercent,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== TABS (Stats / Games / Achievements) ======
  Widget _buildTabs(
      BuildContext context,
      Map<String, dynamic> stats,
      List<Map<String, dynamic>> games,
      List<Map<String, dynamic>> achievements,
      ) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: [
                Tab(text: "Статистика"),
                Tab(text: "Игры"),
                Tab(text: "Награды"),
              ],
            ),
          ),

          SizedBox(height: 12),

          SizedBox(
            height: 520,
            child: TabBarView(
              children: [
                _buildStatsTab(context, stats),
                _buildGamesTab(context, games),
                _buildAchievementsTab(context, achievements),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====== STATS TAB ======
  Widget _buildStatsTab(BuildContext context, Map<String, dynamic> s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events,
                    color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text("Общая статистика", style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: GridView(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                children: [
                  _statTile("${s['totalScore']}", "Общий счёт",
                      Theme.of(context).primaryColor.withOpacity(0.06)),
                  _statTile("${s['gamesPlayed']}", "Игр сыграно",
                      Theme.of(context).primaryColor.withOpacity(0.12)),
                  _statTile("${s['gamesWon']}", "Побед",
                      Theme.of(context).primaryColor.withOpacity(0.18)),
                  _statTile("${s['winRate']}%", "Процент побед",
                      Theme.of(context).primaryColor.withOpacity(0.24)),
                  _statTile("${s['photosTaken']}", "Фотографий",
                      Theme.of(context).primaryColor.withOpacity(0.12)),
                  _statTile("${s['challengesCompleted']}", "Заданий",
                      Theme.of(context).primaryColor.withOpacity(0.18)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== GAMES TAB ======
  Widget _buildGamesTab(BuildContext context, List<Map<String, dynamic>> games) {
    if (games.isEmpty) {
      return Center(child: Text("Нет игр"));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt,
                    color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text("Последние игры", style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 12),

            Expanded(
              child: ListView.separated(
                itemCount: games.length,
                separatorBuilder: (_, __) => SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final game = games[index];

                  final pos = game['position'] ?? 4;
                  final emoji = pos == 1
                      ? "🏆"
                      : pos == 2
                      ? "🥈"
                      : pos == 3
                      ? "🥉"
                      : "🎮";

                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    game['location'] ?? "",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(width: 6),
                                  Text(emoji, style: TextStyle(fontSize: 18)),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${game['date']} • ${game['players'] ?? 0} игроков",
                                style: TextStyle(color: Colors.grey.shade600),
                              )
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${game['score'] ?? 0}",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "#$pos место",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== ACHIEVEMENTS TAB ======
  Widget _buildAchievementsTab(
      BuildContext context, List<Map<String, dynamic>> achievements) {
    if (achievements.isEmpty) {
      return Center(child: Text("Нет достижений"));
    }

    Color rarityColor(String rarity) {
      switch (rarity) {
        case 'common':
          return Colors.grey.shade300;
        case 'rare':
          return Colors.blue.shade100;
        case 'epic':
          return Colors.purple.shade100;
        case 'legendary':
          return Colors.yellow.shade200;
        default:
          return Colors.grey.shade300;
      }
    }

    Color rarityTextColor(String rarity) {
      switch (rarity) {
        case 'common':
          return Colors.grey.shade800;
        case 'rare':
          return Colors.blue.shade800;
        case 'epic':
          return Colors.purple.shade800;
        case 'legendary':
          return Colors.orange.shade900;
        default:
          return Colors.grey.shade800;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.track_changes,
                    color: Theme.of(context).primaryColor),
                SizedBox(width: 8),
                Text("Достижения", style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 12),

            Expanded(
              child: GridView.builder(
                itemCount: achievements.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemBuilder: (context, index) {
                  final ach = achievements[index];
                  final unlocked = ach['unlocked'] ?? false;
                  final rarity = ach['rarity'] ?? "common";

                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: unlocked ? Colors.white : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: unlocked
                            ? Theme.of(context)
                            .primaryColor
                            .withOpacity(0.2)
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          unlocked ? ach['icon'] ?? "✨" : "🔒",
                          style: TextStyle(fontSize: 30),
                        ),
                        SizedBox(height: 8),
                        Text(
                          ach['name'] ?? "",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: unlocked
                                ? Colors.grey.shade900
                                : Colors.grey.shade500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: rarityColor(rarity),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            rarity,
                            style: TextStyle(
                              fontSize: 12,
                              color: rarityTextColor(rarity),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small helper
  Widget _statTile(String value, String label, Color bg) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
