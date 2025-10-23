import 'package:flutter/material.dart';

class GreetingPage extends StatelessWidget {
  const GreetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurpleAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('📸', style: TextStyle(fontSize: 60),),
            Text('CarpeDiem', style: TextStyle(color: Colors.white, fontSize: 40)),
            Text('Лови момент! Играй с друзьями'),
            ElevatedButton(onPressed: () => {Navigator.pushNamed(context, '/login')}, child: Text('Начать игру'))
          ],
        )
      ),
    );
  }
}
