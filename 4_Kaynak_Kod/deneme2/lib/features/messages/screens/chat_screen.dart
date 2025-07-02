// lib/features/messages/screens/chat_screen.dart
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelen Kutusu'),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Kullanıcı ${index + 1}'),
            subtitle: const Text('Merhaba, projenizle ilgileniyorum...'),
            trailing: const Text('14:30'),
            onTap: () {},
          );
        },
      ),
    );
  }
}