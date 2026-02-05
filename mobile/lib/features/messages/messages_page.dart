import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    widget.api.messages().then((data) => setState(() => messages = data));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Mesajlar', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        ...messages.map((m) {
          final unread = m['unread'] == true;
          return Card(
            color: const Color(0xFF083D49),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: unread ? const Color(0xFF24C58E) : Colors.grey,
                child: Text(_initialOf(m['from']?.toString() ?? 'K')),
              ),
              title: Text(m['from']?.toString() ?? ''),
              subtitle: Text(m['preview']?.toString() ?? ''),
              trailing: Text(m['time']?.toString() ?? ''),
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
