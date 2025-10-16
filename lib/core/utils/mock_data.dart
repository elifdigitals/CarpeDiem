import '../../domain/entities/room.dart';

List<Room> mockRooms = [
  Room(
    id: "1",
    name: "Flutter Study",
    privacy: RoomPrivacy.public,
    members: [],
    settings: RoomSettings(
      tags: ["study", "flutter"],
      category: "Study",
      descriptionMarkdown: "Комната для совместного изучения Flutter.",
    ),
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    autoDeleteAfter: null,
  ),
  Room(
    id: "2",
    name: "Chill & Music",
    privacy: RoomPrivacy.public,
    members: [],
    settings: RoomSettings(
      tags: ["music", "chill"],
      category: "Music",
      descriptionMarkdown: "Музыкальная комната, делимся треками!",
    ),
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    autoDeleteAfter: null,
  )
];