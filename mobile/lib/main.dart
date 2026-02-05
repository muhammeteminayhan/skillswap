import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SkillSwapApp());
}

class SkillSwapApp extends StatelessWidget {
  const SkillSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillSwap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E8E3E)),
        scaffoldBackgroundColor: const Color(0xFFF4FAF5),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _resolveBaseUrl(),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  final Dio _dio;

  static String _resolveBaseUrl() {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  Future<Map<String, dynamic>> chat(String message) async {
    final response = await _dio.post('/api/chat', data: {
      'userId': 1,
      'message': message,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> requests() async {
    final response = await _dio.get('/api/requests/1');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> createRequest(String text) async {
    await _dio.post('/api/requests', data: {'userId': 1, 'text': text});
  }

  Future<List<Map<String, dynamic>>> messages() async {
    final response = await _dio.get('/api/messages/1');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> skills() async {
    final response = await _dio.get('/api/skills/1');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> updateSkills(List<String> offers, List<String> wants) async {
    await _dio.put('/api/skills/1', data: {'offers': offers, 'wants': wants});
  }

  Future<Map<String, dynamic>> profile() async {
    final response = await _dio.get('/api/profile/1');
    return Map<String, dynamic>.from(response.data as Map);
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ApiService api = ApiService();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(api: api),
      RequestsTab(api: api),
      MessagesTab(api: api),
      SkillsTab(api: api),
      ProfileTab(api: api),
    ];

    return Scaffold(
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'İstekler'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Mesajlar'),
          NavigationDestination(icon: Icon(Icons.build_outlined), label: 'Yetenekler'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.api});

  final ApiService api;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _controller = TextEditingController(
    text: 'Evimde tesisat işine ihtiyacım var, karşılığında elektrik işi yapabilirim.',
  );
  String _answer = 'AI asistanı ile konuşarak eşleşme bulabilirsin.';
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;

  Future<void> _send() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() => _loading = true);
    try {
      final data = await widget.api.chat(message);
      final suggestions = (data['suggestions'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _answer = (data['answer'] ?? '').toString();
        _suggestions = suggestions;
      });
    } catch (e) {
      setState(() => _answer = 'Hata: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SkillSwap AI Eşleştirme', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'İhtiyacını yaz',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _loading ? null : _send,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Eşleştiriliyor...' : 'AI ile eşleştir'),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB4DDBD)),
            ),
            child: Text(_answer),
          ),
          const SizedBox(height: 14),
          Text('Önerilen Eşleşmeler', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return Card(
                  child: ListTile(
                    title: Text('${item['name']} (${item['matchScore']}/100)'),
                    subtitle: Text('${item['location']} • ${item['reason']}'),
                    trailing: Text('Güven ${item['trustScore']}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key, required this.api});

  final ApiService api;

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  final TextEditingController _requestController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await widget.api.requests();
      setState(() => _items = items);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final text = _requestController.text.trim();
    if (text.isEmpty) return;
    await widget.api.createRequest(text);
    _requestController.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _requestController,
            decoration: const InputDecoration(
              labelText: 'Yeni takas isteği',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: _create, child: const Text('İstek oluştur')),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item['text']?.toString() ?? ''),
                          subtitle: Text('İstiyor: ${item['wantedSkill']} | Sunuyor: ${item['offeredSkill']}'),
                          trailing: Text(item['status']?.toString() ?? ''),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key, required this.api});

  final ApiService api;

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.api.messages();
    setState(() => _messages = items);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final item = _messages[index];
        final unread = item['unread'] == true;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: unread ? const Color(0xFF1E8E3E) : Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(item['from']?.toString() ?? ''),
            subtitle: Text(item['preview']?.toString() ?? ''),
            trailing: Text(item['time']?.toString() ?? ''),
          ),
        );
      },
    );
  }
}

class SkillsTab extends StatefulWidget {
  const SkillsTab({super.key, required this.api});

  final ApiService api;

  @override
  State<SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<SkillsTab> {
  final TextEditingController _offersController = TextEditingController();
  final TextEditingController _wantsController = TextEditingController();
  String _status = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.api.skills();
    final offers = (data['offers'] as List<dynamic>? ?? []).join(', ');
    final wants = (data['wants'] as List<dynamic>? ?? []).join(', ');
    setState(() {
      _offersController.text = offers;
      _wantsController.text = wants;
    });
  }

  Future<void> _save() async {
    final offers = _offersController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final wants = _wantsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      await widget.api.updateSkills(offers, wants);
      setState(() => _status = 'Kaydedildi.');
    } catch (e) {
      setState(() => _status = 'Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sunabildiğim Yetkinlikler', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          TextField(
            controller: _offersController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Elektrik - priz, Elektrik - avize montajı',
            ),
          ),
          const SizedBox(height: 12),
          Text('İhtiyaç Duyduğum Yetkinlikler', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          TextField(
            controller: _wantsController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Tesisat - su kaçağı, Doğalgaz - kombi bakımı',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Yetenekleri Kaydet')),
          const SizedBox(height: 8),
          Text(_status),
        ],
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.api});

  final ApiService api;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.api.profile();
    setState(() => _profile = data);
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_profile!['name']?.toString() ?? '', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(_profile!['title']?.toString() ?? ''),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 6),
              Text(_profile!['location']?.toString() ?? ''),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined),
              const SizedBox(width: 6),
              Text('Güven Puanı: ${_profile!['trustScore']}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(_profile!['bio']?.toString() ?? ''),
        ],
      ),
    );
  }
}
