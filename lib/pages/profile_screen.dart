class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({super.key, required this.userId});

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
    final data = await ApiService.getProfile(widget.userId);
    setState(() {
      profile = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text("Мой профиль")),
      body: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: profile!["photo"] != null
                ? NetworkImage(profile!["photo"])
                : null,
          ),
          Text(profile!["full_name"]),
          Text(profile!["location"]),
          Text(profile!["phone"]),
          Text(profile!["birth_date"]),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditProfileScreen(userId: widget.userId, profile: profile!),
                ),
              );
            },
            child: const Text("Редактировать"),
          )
        ],
      ),
    );
  }
}
