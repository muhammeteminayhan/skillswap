import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import 'chat_thread_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> conversations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.conversations();
      setState(() => conversations = data);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Mesajlar', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        if (conversations.isEmpty)
          const Text(
            'Henuz sohbet yok. Ilanlar sekmesinden bir kisiyle iletisime gec.',
          ),
        ...conversations.map((m) {
          final unreadCount = (m['unreadCount'] as num?)?.toInt() ?? 0;
          final photoUrl = m['otherPhotoUrl']?.toString() ?? '';
          return Card(
            child: ListTile(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatThreadPage(
                      api: widget.api,
                      otherUserId: (m['otherUserId'] as num).toInt(),
                      otherName: m['otherName']?.toString() ?? 'Kullanici',
                      otherPhotoUrl: photoUrl,
                    ),
                  ),
                );
                _load();
              },
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE8F6EF),
                backgroundImage: photoUrl.isEmpty
                    ? null
                    : NetworkImage(photoUrl),
                child: photoUrl.isEmpty
                    ? Text(_initialOf(m['otherName']?.toString() ?? 'K'))
                    : null,
              ),
              title: Text(m['otherName']?.toString() ?? ''),
              subtitle: Text(m['lastMessage']?.toString() ?? ''),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(m['lastAt']?.toString() ?? ''),
                  if (unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B9C6B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Color(0xFFF7FFFB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

String _initialOf(String input) {
  if (input.isEmpty) {
    return 'K';
  }
  return input.substring(0, 1).toUpperCase();
}
