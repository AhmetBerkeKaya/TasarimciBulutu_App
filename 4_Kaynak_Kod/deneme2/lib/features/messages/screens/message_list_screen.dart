// lib/features/messages/screens/message_list_screen.dart
import 'package:flutter/material.dart';

class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // SAHTE VERİ
    final conversations = [
      {'name': 'Ahmet Yılmaz', 'message': 'Harika, teklifinizi değerlendirip döneceğim.', 'time': '14:30', 'unread': 0},
      {'name': 'Zeynep Kaya (Yapı-Tek)', 'message': 'Portfolyonuzu inceledim, bir görüşme ayarlayalım.', 'time': '11:15', 'unread': 2},
      {'name': 'Mustafa Demir', 'message': 'Anlaştık, sözleşmeyi gönderiyorum.', 'time': 'Dün', 'unread': 0},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: ListView.separated(
        itemCount: conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16,),
        itemBuilder: (context, index) {
          final conv = conversations[index];
          final hasUnread = (conv['unread'] as int) > 0;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              child: Text((conv['name'] as String).substring(0, 1)), // İsmin baş harfi
            ),
            title: Text(conv['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              conv['message'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(conv['time'] as String, style: Theme.of(context).textTheme.bodySmall),
                if (hasUnread) ...[
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      conv['unread'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                ]
              ],
            ),
            onTap: () {
              // TODO: İlgili sohbet ekranını aç
            },
          );
        },
      ),
    );
  }
}