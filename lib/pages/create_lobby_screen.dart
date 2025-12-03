import 'package:flutter/material.dart';
import '../services/lobby_api.dart';
import 'lobby_room_screen.dart';

class CreateLobbyScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onCreateGame;
  final int? userId;

  const CreateLobbyScreen({this.onBack, this.onCreateGame, super.key, required this.userId});

  @override
  State<CreateLobbyScreen> createState() => _CreateLobbyScreenState();
}

class _CreateLobbyScreenState extends State<CreateLobbyScreen> {
  String lobbyName = "";
  String selectedMode = "quick";
  String timeLimit = "15";

  final gameModes = [
    {
      "id": "quick",
      "name": "Быстрый матч",
      "description": "15-30 мин",
      "icon": "⚡",
    },
    {
      "id": "family",
      "name": "Семейный",
      "description": "Без ограничений по возрасту",
      "icon": "👨‍👩‍👧‍👦",
    },
    {
      "id": "corporate",
      "name": "Корпоративный",
      "description": "Для команд",
      "icon": "🏢",
    },
    {
      "id": "weekly",
      "name": "Недельный челлендж",
      "description": "Долгосрочная игра",
      "icon": "📅",
    },
  ];

  final challenges = [
    "Найди игрока с улыбкой 😊",
    "Сфоткай кого-то с животным 🐕",
    "Найди человека в красном 🔴",
    "Сделай селфи с незнакомцем 🤳",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack ?? () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Создать лобби',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Название лобби",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: "Моя крутая игра",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              setState(() => lobbyName = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Выберите режим",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: gameModes.map((mode) {
                            final selected = selectedMode == mode['id'];
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => selectedMode = mode['id']!),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFEDE9FE)
                                      : Colors.white,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF7C3AED)
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      mode['icon']!,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mode['name']!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            mode['description']!,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF7C3AED),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.access_time, size: 18),
                            SizedBox(width: 4),
                            Text(
                              "Лимит времени",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ["10", "15", "30", "60"].map((time) {
                            final isSelected = timeLimit == time;
                            return Expanded(
                              child: Container(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      setState(() => timeLimit = time),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? const Color(0xFF7C3AED)
                                        : Colors.white,
                                    foregroundColor: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  child: Text("$timeм"),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.flag, size: 18),
                            SizedBox(width: 4),
                            Text(
                              "Дополнительные задания",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: challenges
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE9FE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                      color: Color(0xFF7C3AED),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: lobbyName.trim().isEmpty
                            ? null
                            : () async {
                          final lobby = await LobbyApi.createLobby(
                            userId: widget.userId,
                            name: lobbyName,
                            mode: selectedMode,
                            time: int.parse(timeLimit),
                          );

                          if (lobby != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LobbyRoomScreen(lobbyId: lobby['id']),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Ошибка создания лобби")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Создать игру",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {}, // TODO: share
                        icon: const Icon(Icons.share),
                        label: const Text("Поделиться ссылкой"),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7C3AED)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
