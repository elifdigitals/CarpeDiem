import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onStore;

  const ProfileScreen({Key? key, required this.onBack, required this.onStore})
    : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _userStats;
  List<dynamic> _userGames = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (ApiService.currentUserId == null) {
      setState(() {
        _errorMessage = "Пользователь не авторизован";
        _loading = false;
      });
      return;
    }

    try {
      // Загружаем данные пользователя
      final userResponse = await ApiService.getCurrentUser();

      // Загружаем статистику
      final statsResponse = await ApiService.getUserStats(
        ApiService.currentUserId!,
      );

      // Загружаем игры
      final gamesResponse = await ApiService.getUserGames(
        ApiService.currentUserId!,
      );

      if (userResponse['status'] == 'success' &&
          statsResponse['status'] == 'success') {
        setState(() {
          _userData = userResponse['data'];
          _userStats = statsResponse['data'];
          _userGames = gamesResponse['status'] == 'success'
              ? gamesResponse['data']['games'] ?? []
              : [];
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Не удалось загрузить данные профиля";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Ошибка загрузки: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Content
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProfileData,
                              child: Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : Padding(
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
                                      colors: [
                                        Color(0xFF4F46E5),
                                        Color(0xFF7C3AED),
                                      ],
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
                                              color: Colors.white.withOpacity(
                                                0.15,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '👤',
                                                style: TextStyle(fontSize: 28),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          // Name & email
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _userData?['username'] ??
                                                      'Пользователь',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  _userData?['email'] ??
                                                      'Нет email',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
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
                                length: 2,
                                initialIndex: 0,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TabBar(
                                        labelColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        unselectedLabelColor: Colors.black54,
                                        indicatorColor: Theme.of(
                                          context,
                                        ).primaryColor,
                                        tabs: [
                                          Tab(text: 'Статистика'),
                                          Tab(text: 'Игры'),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Container(
                                      child: SizedBox(
                                        height: 400,
                                        child: TabBarView(
                                          children: [
                                            // ======= STATS TAB =======
                                            Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
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
                                                    Expanded(
                                                      child: GridView(
                                                        physics:
                                                            NeverScrollableScrollPhysics(),
                                                        gridDelegate:
                                                            SliverGridDelegateWithFixedCrossAxisCount(
                                                              crossAxisCount: 2,
                                                              mainAxisSpacing:
                                                                  10,
                                                              crossAxisSpacing:
                                                                  10,
                                                              childAspectRatio:
                                                                  2.2,
                                                            ),
                                                        children: [
                                                          _statTile(
                                                            (_userStats?['stats']['total_score'] ??
                                                                    0)
                                                                .toString(),
                                                            'Общий счёт',
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withOpacity(
                                                                  0.06,
                                                                ),
                                                          ),
                                                          _statTile(
                                                            (_userStats?['stats']['games_played'] ??
                                                                    0)
                                                                .toString(),
                                                            'Игр сыграно',
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withOpacity(
                                                                  0.12,
                                                                ),
                                                          ),
                                                          _statTile(
                                                            (_userStats?['stats']['games_won'] ??
                                                                    0)
                                                                .toString(),
                                                            'Побед',
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withOpacity(
                                                                  0.18,
                                                                ),
                                                          ),
                                                          _statTile(
                                                            '${_userStats?['stats']['win_rate'] ?? 0}%',
                                                            'Процент побед',
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withOpacity(
                                                                  0.24,
                                                                ),
                                                          ),
                                                          _statTile(
                                                            (_userStats?['stats']['photos_taken'] ??
                                                                    0)
                                                                .toString(),
                                                            'Фотографий',
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withOpacity(
                                                                  0.12,
                                                                ),
                                                          ),
                                                          _statTile(
                                                            (_userStats?['stats']['lobbies_created'] ??
                                                                    0)
                                                                .toString(),
                                                            'Создано лобби',
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withOpacity(
                                                                  0.18,
                                                                ),
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  12.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
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
                                                      child: _userGames.isEmpty
                                                          ? Center(
                                                              child: Text(
                                                                'Нет завершенных игр',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            )
                                                          : ListView.separated(
                                                              itemCount:
                                                                  _userGames
                                                                      .length,
                                                              separatorBuilder:
                                                                  (_, __) =>
                                                                      SizedBox(
                                                                        height:
                                                                            8,
                                                                      ),
                                                              itemBuilder: (context, index) {
                                                                final game =
                                                                    _userGames[index];
                                                                final pos =
                                                                    game['position']
                                                                        as int;
                                                                final emoji =
                                                                    pos == 1
                                                                    ? '🏆'
                                                                    : pos == 2
                                                                    ? '🥈'
                                                                    : pos == 3
                                                                    ? '🥉'
                                                                    : '🎯';

                                                                return Container(
                                                                  padding:
                                                                      EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            12,
                                                                        vertical:
                                                                            10,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade50,
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
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Row(
                                                                              children: [
                                                                                Text(
                                                                                  game['location'] ??
                                                                                      'Неизвестно',
                                                                                  style: TextStyle(
                                                                                    fontSize: 16,
                                                                                    fontWeight: FontWeight.w600,
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  width: 8,
                                                                                ),
                                                                                Text(
                                                                                  emoji,
                                                                                  style: TextStyle(
                                                                                    fontSize: 18,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            SizedBox(
                                                                              height: 4,
                                                                            ),
                                                                            Text(
                                                                              '${game['date']} • ${game['players']} игроков • ${game['mode']}',
                                                                              style: TextStyle(
                                                                                color: Colors.grey.shade600,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.end,
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
                                                                            height:
                                                                                4,
                                                                          ),
                                                                          Text(
                                                                            '#${game['position']} место',
                                                                            style: TextStyle(
                                                                              color: Colors.grey.shade600,
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
          IconButton(onPressed: widget.onBack, icon: Icon(Icons.arrow_back)),
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
