import 'package:flutter/material.dart';

// ProfileScreen: full widget as provided by the user, converted to Dart.
class ProfileScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onStore;

  const ProfileScreen({Key? key, required this.onBack, required this.onStore})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ============================================
    // USER DATA
    // ============================================
    final userStats = {
      'nickname': 'CyberSaid',
      'level': 12,
      'totalScore': 15420,
      'gamesPlayed': 47,
      'gamesWon': 18,
      'photosTaken': 342,
      'challengesCompleted': 89,
      'winRate': 38,
      'currentExp': 750,
      'nextLevelExp': 1000,
    };

    // ============================================
    // RECENT GAMES
    // ============================================
    final recentGames = [
      {
        "date": "Сегодня",
        "location": "Парк Горького",
        "position": 2,
        "players": 8,
        "score": 850,
      },
      {
        "date": "Вчера",
        "location": "ТРЦ Афимолл",
        "position": 1,
        "players": 6,
        "score": 920,
      },
      {
        "date": "2 дня назад",
        "location": "МГУ",
        "position": 4,
        "players": 12,
        "score": 650,
      },
      {
        "date": "3 дня назад",
        "location": "Красная площадь",
        "position": 1,
        "players": 10,
        "score": 1100,
      },
    ];

    // ============================================
    // ACHIEVEMENTS
    // ============================================
    final achievements = [
      {
        "name": "Первая победа",
        "icon": "🏆",
        "rarity": "common",
        "unlocked": true,
      },
      {
        "name": "Мастер селфи",
        "icon": "🤳",
        "rarity": "rare",
        "unlocked": true,
      },
      {
        "name": "Быстрая реакция",
        "icon": "⚡",
        "rarity": "common",
        "unlocked": true,
      },
      {
        "name": "Коллекционер",
        "icon": "📸",
        "rarity": "epic",
        "unlocked": false,
      },
      {
        "name": "Легенда CarpeDiem",
        "icon": "👑",
        "rarity": "legendary",
        "unlocked": false,
      },
      {
        "name": "Социальная звезда",
        "icon": "⭐",
        "rarity": "rare",
        "unlocked": true,
      },
    ];

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

    double expPercent =
        (userStats['currentExp'] as int) / (userStats['nextLevelExp'] as int);

    return Scaffold(
      // Gradient background similar to the Tailwind design
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF),
              Color(0xFFEEF2FF),
            ], // subtle primary gradient
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // User Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                        child: Text(
                                          '📸',
                                          style: TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    // Name & level
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userStats['nickname'] as String,
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Colors.yellow.shade300,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Уровень ${userStats['level']}',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Premium button
                                    TextButton.icon(
                                      onPressed: onStore,
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withOpacity(0.12),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.workspace_premium,
                                        size: 18,
                                      ),
                                      label: Text('Премиум'),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 12),

                                // Level progress
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Опыт: ${userStats['currentExp']}/${userStats['nextLevelExp']}',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        Text(
                                          '${(expPercent * 100).round()}%',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        minHeight: 8,
                                        value: expPercent,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.2),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Tabs
                        DefaultTabController(
                          length: 3,
                          initialIndex: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TabBar(
                                  labelColor: Theme.of(context).primaryColor,
                                  unselectedLabelColor: Colors.black54,
                                  indicatorColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  tabs: [
                                    Tab(text: 'Статистика'),
                                    Tab(text: 'Игры'),
                                    Tab(text: 'Награды'),
                                  ],
                                ),
                              ),

                              SizedBox(height: 12),

                              Container(
                                // Tab content white card
                                child: SizedBox(
                                  height:
                                      520, // give TabBarView a fixed height so it can scroll internally
                                  child: TabBarView(
                                    children: [
                                      // ======= STATS TAB =======
                                      Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.emoji_events,
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Общая статистика',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),

                                              // Grid of statistics (2 columns)
                                              Expanded(
                                                child: GridView(
                                                  physics:
                                                      NeverScrollableScrollPhysics(),
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 2,
                                                        mainAxisSpacing: 10,
                                                        crossAxisSpacing: 10,
                                                        childAspectRatio: 2.2,
                                                      ),
                                                  children: [
                                                    _statTile(
                                                      '${(userStats['totalScore'] as int).toString()}',
                                                      'Общий счёт',
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.06),
                                                    ),
                                                    _statTile(
                                                      '${userStats['gamesPlayed']}',
                                                      'Игр сыграно',
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.12),
                                                    ),
                                                    _statTile(
                                                      '${userStats['gamesWon']}',
                                                      'Побед',
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.18),
                                                    ),
                                                    _statTile(
                                                      '${userStats['winRate']}%',
                                                      'Процент побед',
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.24),
                                                    ),
                                                    _statTile(
                                                      '${userStats['photosTaken']}',
                                                      'Фотографий',
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.12),
                                                    ),
                                                    _statTile(
                                                      '${userStats['challengesCompleted']}',
                                                      'Заданий',
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.18),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // ======= GAMES TAB =======
                                      Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.camera_alt,
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Последние игры',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),

                                              Expanded(
                                                child: ListView.separated(
                                                  itemCount: recentGames.length,
                                                  separatorBuilder: (_, __) =>
                                                      SizedBox(height: 8),
                                                  itemBuilder: (context, index) {
                                                    final game =
                                                        recentGames[index];
                                                    final pos =
                                                        game['position'] as int;
                                                    final emoji = pos == 1
                                                        ? '🏆'
                                                        : pos == 2
                                                        ? '🥈'
                                                        : pos == 3
                                                        ? '🥉'
                                                        : '🎮';

                                                    return Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.grey.shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                      game['location']
                                                                          as String,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Text(
                                                                      emoji,
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  '${game['date']} • ${game['players']} игроков',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade600,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Text(
                                                                '${game['score']}',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).primaryColor,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 4,
                                                              ),
                                                              Text(
                                                                '#${game['position']} место',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade600,
                                                                ),
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
                                      ),

                                      // ======= ACHIEVEMENTS TAB =======
                                      Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.track_changes,
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Достижения',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),

                                              Expanded(
                                                child: GridView.builder(
                                                  itemCount:
                                                      achievements.length,
                                                  gridDelegate:
                                                      SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 2,
                                                        mainAxisSpacing: 8,
                                                        crossAxisSpacing: 8,
                                                        childAspectRatio: 1.4,
                                                      ),
                                                  itemBuilder: (context, index) {
                                                    final ach =
                                                        achievements[index];
                                                    final unlocked =
                                                        ach['unlocked'] as bool;
                                                    final rarity =
                                                        ach['rarity'] as String;

                                                    return Container(
                                                      padding: EdgeInsets.all(
                                                        10,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: unlocked
                                                            ? Colors.white
                                                            : Colors
                                                                  .grey
                                                                  .shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          color: unlocked
                                                              ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .primaryColor
                                                                    .withOpacity(
                                                                      0.2,
                                                                    )
                                                              : Colors
                                                                    .grey
                                                                    .shade200,
                                                          width: 2,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            unlocked
                                                                ? ach['icon']
                                                                      as String
                                                                : '🔒',
                                                            style: TextStyle(
                                                              fontSize: 30,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            ach['name']
                                                                as String,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: unlocked
                                                                  ? Colors
                                                                        .grey
                                                                        .shade900
                                                                  : Colors
                                                                        .grey
                                                                        .shade500,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  rarityColor(
                                                                    rarity,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              rarity,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    rarityTextColor(
                                                                      rarity,
                                                                    ),
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
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

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

  // Header widget with back and settings buttons
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onBack, icon: Icon(Icons.arrow_back)),
          Text(
            'Профиль',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.settings)),
        ],
      ),
    );
  }

  // small helper for stat tiles
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
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
