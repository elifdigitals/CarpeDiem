import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileEditScreen({super.key, required this.profile});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController name;
  late TextEditingController phone;
  late TextEditingController location;
  late TextEditingController birth;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.profile["full_name"]);
    phone = TextEditingController(text: widget.profile["phone"]);
    location = TextEditingController(text: widget.profile["location"]);
    birth = TextEditingController(text: widget.profile["birth_date"]);
  }

  Future<void> save() async {
    final token = await AuthService().getToken();
    final userId = await AuthService().getUserId();

    var req = http.MultipartRequest(
      'PUT',
      Uri.parse("http://10.0.2.2:8000/profile/update/$userId"),
    );

    req.headers["Authorization"] = "Bearer $token";

    req.fields["full_name"] = name.text;
    req.fields["phone"] = phone.text;
    req.fields["location"] = location.text;
    req.fields["birth_date"] = birth.text;

    final res = await req.send();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Изменить профиль")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: "Имя")),
            TextField(controller: phone, decoration: InputDecoration(labelText: "Телефон")),
            TextField(controller: location, decoration: InputDecoration(labelText: "Город")),
            TextField(controller: birth, decoration: InputDecoration(labelText: "Дата рождения")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: save,
              child: Text("Сохранить"),
            )
          ],
        ),
      ),
    );
  }
}
