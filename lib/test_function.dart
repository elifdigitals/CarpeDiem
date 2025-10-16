import 'package:flutter/material.dart';

class CreateRoomPage extends StatefulWidget {
  @override
  _CreateRoomPageState createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _maxUsersController = TextEditingController();
  bool _isPublic = true;
  String? _createdRoom;

  @override
  void dispose() {
    _roomNameController.dispose();
    _maxUsersController.dispose();
    super.dispose();
  }

  void _createRoom() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _createdRoom =
            "Room '
+ _roomNameController.text +
            "' created! Public: "+ _isPublic.toString() +
            ", Max users: "+ _maxUsersController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room created successfully!')), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Room')), 
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _roomNameController,
                decoration: InputDecoration(labelText: 'Room Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a room name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _maxUsersController,
                decoration: InputDecoration(labelText: 'Max Users'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter max users';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return 'Enter a valid user count';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: Text('Public Room'),
                value: _isPublic,
                onChanged: (val) => setState(() => _isPublic = val),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createRoom,
                child: Text('Create'),
              ),
              if (_createdRoom != null) ...[
                Divider(height: 32),
                Text(_createdRoom!, style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Для ручной проверки: вставьте этот виджет как начальный в MaterialApp
void testFunction() {
  runApp(MaterialApp(
    home: CreateRoomPage(),
  ));
}