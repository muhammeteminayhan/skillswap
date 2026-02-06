import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    super.key,
    required this.api,
    required this.otherUserId,
    required this.otherName,
    this.otherPhotoUrl,
  });

  final ApiClient api;
  final int otherUserId;
  final String otherName;
  final String? otherPhotoUrl;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final TextEditingController controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool sending = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.chatThread(otherUserId: widget.otherUserId);
      setState(() => messages = data);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _send() async {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      sending = true;
      error = '';
    });
    try {
      await widget.api.sendDirectMessage(
        toUserId: widget.otherUserId,
        body: text,
      );
      controller.clear();
      await _load();
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map && payload['message'] != null) {
        setState(() => error = payload['message'].toString());
      } else {
        setState(() => error = 'Mesaj gonderilemedi.');
      }
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.api.currentUserId();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE8F6EF),
              backgroundImage:
                  widget.otherPhotoUrl == null || widget.otherPhotoUrl!.isEmpty
                  ? null
                  : NetworkImage(widget.otherPhotoUrl!),
              child:
                  widget.otherPhotoUrl == null || widget.otherPhotoUrl!.isEmpty
                  ? Text(_initial(widget.otherName))
                  : null,
            ),
            const SizedBox(width: 8),
            Text(widget.otherName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final mine =
                          ((m['senderUserId'] as num?)?.toInt() ?? -1) == me;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: mine
                                ? const Color(0xFF1B9C6B)
                                : const Color(0xFFF1F7F4),
                            borderRadius: BorderRadius.circular(12),
                            border: mine
                                ? null
                                : Border.all(color: const Color(0xFFDDEAE3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['body']?.toString() ?? '',
                                style: TextStyle(
                                  color: mine
                                      ? const Color(0xFFF7FFFB)
                                      : const Color(0xFF1C1F1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m['createdAt']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mine
                                      ? const Color(0xFFD7F4E6)
                                      : const Color(0xFF6B7A72),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Mesaj yaz...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: sending ? null : _send,
                    child: Text(sending ? '...' : 'Gonder'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _initial(String text) {
  if (text.isEmpty) {
    return 'K';
  }
  return text.substring(0, 1).toUpperCase();
}
