import 'package:flutter/material.dart';

import '../../core/models/auth_session.dart';
import '../../core/network/api_client.dart';
import '../profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final ApiClient api;
  final AuthSession session;
  final VoidCallback onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? dashboard;
  String profilePhotoUrl = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.api.dashboard(),
        widget.api.profile(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final profile = results[1] as Map<String, dynamic>;
      setState(() {
        dashboard = data;
        profilePhotoUrl = profile['photoUrl']?.toString() ?? '';
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = dashboard ?? {};
    final stats = (data['quickStats'] as List<dynamic>? ?? []);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['welcomeText'] ?? 'Tekrar Hos Geldin'} 👋',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.session.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF4A5852),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () async {
                  final shouldLogout = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfilePage(api: widget.api, session: widget.session),
                    ),
                  );
                  if (shouldLogout == true) {
                    widget.onLogout();
                  }
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE8F6EF),
                  backgroundImage: profilePhotoUrl.isEmpty
                      ? null
                      : NetworkImage(profilePhotoUrl),
                  child: profilePhotoUrl.isEmpty
                      ? const Icon(Icons.person_rounded, color: Colors.black54)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _gradientPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yapay Zeka Destekli Eslestirme',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gemini + Embedding Destekli Eslestirme Modlari',
                  style: TextStyle(color: Color(0xFF4A5852)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiChatPage(api: widget.api),
                      ),
                    ),
                    icon: const Icon(Icons.support_agent_rounded),
                    label: const Text('Destek Asistani'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Hizli Istatistikler',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...stats.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(m['title']?.toString() ?? ''),
                subtitle: Text(m['subtitle']?.toString() ?? ''),
                trailing: Text(
                  m['value']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _featureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _gradientPanel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F6EF), Color(0xFFF7FCFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: child,
    );
  }
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();

  String answer = 'AI asistan hazir.';
  List<Map<String, dynamic>> suggestions = [];
  List<dynamic> tips = [];
  bool loading = false;

  Future<void> _send() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty) {
      return;
    }

    setState(() => loading = true);
    try {
      final data = await widget.api.chat(msg);
      setState(() {
        answer = data['answer']?.toString() ?? '';
        suggestions = (data['suggestions'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        tips = data['copilotTips'] as List<dynamic>? ?? [];
      });
    } catch (e) {
      setState(() => answer = 'Hata: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Destek Asistani')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Istegini yaz',
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: loading ? null : _send,
              child: Text(loading ? 'Gonderiliyor...' : 'AI Eslestir'),
            ),
            const SizedBox(height: 12),
            _infoCard('Destek Asistan Yaniti', answer),
            const SizedBox(height: 8),
            if (tips.isNotEmpty)
              _infoCard('AI Onerileri', tips.map((e) => '• $e').join('\n')),
            const SizedBox(height: 10),
            const Text(
              'Eslesme Adaylari',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...suggestions.map(
              (m) {
                final bool isBoost = m['boost'] == true;
                return Card(
                  color: isBoost ? const Color(0xFFE6F7E6) : null,
                  child: ListTile(
                    title: Text(
                      isBoost
                          ? '${m['name']}'
                          : '${m['name']}  (%${m['matchScore']})',
                      style: isBoost
                          ? const TextStyle(fontWeight: FontWeight.w700)
                          : null,
                    ),
                    subtitle: isBoost
                        ? const Text('Onayli Profil')
                        : Text(
                            '${m['reason']}\nAnlamsal Skor: ${m['semanticScore']} | Adalet: %${m['fairnessPercent']}',
                          ),
                    trailing: isBoost
                        ? const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF2F7D32),
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF4A5852))),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );
  }
}

class ChainsPage extends StatefulWidget {
  const ChainsPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<ChainsPage> createState() => _ChainsPageState();
}

class _ChainsPageState extends State<ChainsPage> {
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    widget.api.chains().then((v) => setState(() => data = v));
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tips = data!['chainTips'] as List<dynamic>? ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Skill Chains')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Yetenek Zincirleri Nedir?\nBir kullanicinin sundugu hizmet digerinin ihtiyacini, onun sundugu hizmet de baska bir kisinin ihtiyacini karsiliyorsa zincir olusur. Bu sayede herkes karsiligini alir.',
              style: TextStyle(color: Color(0xFF4A5852)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statBox(
                    'Mevcut Zincir',
                    '${data!['availableChains']}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statBox('Aktif Zincir', '${data!['activeChains']}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if ((data!['availableChains'] as num? ?? 0) == 0)
              const Expanded(
                child: Center(
                  child: Text(
                    'Henuz zincir bulunamadi.\nYeni yetenek ekleyip tekrar dene.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: tips
                      .map(
                        (e) => ListTile(
                          leading: const Icon(Icons.link),
                          title: Text(e.toString()),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF1F7F4),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class QuantumPage extends StatefulWidget {
  const QuantumPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<QuantumPage> createState() => _QuantumPageState();
}

class _QuantumPageState extends State<QuantumPage> {
  bool realMatching = true;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final response = await widget.api.quantum(realMatching);
    setState(() => data = response);
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final matches = (data!['matches'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Kuantum Eslestirme')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kuantum Eslesme Senaryosu:\nBirden fazla olasi eslesme vardir. Sistem, en uygun olasiliklari hesaplar ve seni en yuksek uyuma yaklastirir.',
              style: TextStyle(color: Color(0xFF4A5852)),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: realMatching,
              onChanged: (value) {
                setState(() => realMatching = value);
                _load();
              },
              title: const Text('Kuantum Olasilik Modu'),
              subtitle: Text(data!['quantumState']?.toString() ?? ''),
            ),
            Text('Dolasiklik Sayisi: ${data!['entanglements']}'),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final m = matches[index];
                  return Card(
                    child: ListTile(
                      title: Text(m['name']?.toString() ?? ''),
                      subtitle: Text(
                        '${m['reason']}\nOlasilik: %${m['probability']}',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TalentsPage extends StatefulWidget {
  const TalentsPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<TalentsPage> createState() => _TalentsPageState();
}

class _TalentsPageState extends State<TalentsPage> {
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    widget.api.talents().then((v) => setState(() => data = v));
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final talents = (data!['talents'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Gizli Yetenek Kesfi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(data!['intro']?.toString() ?? ''),
            const SizedBox(height: 12),
            ...talents.map(
              (t) => Card(
                child: ListTile(
                  title: Text('${t['title']}  (%${t['matchPercent']})'),
                  subtitle: Text(t['description']?.toString() ?? ''),
                  trailing: FilledButton(
                    onPressed: () {},
                    child: const Text('Kesfet'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SemanticSearchPage extends StatefulWidget {
  const SemanticSearchPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<SemanticSearchPage> createState() => _SemanticSearchPageState();
}

class _SemanticSearchPageState extends State<SemanticSearchPage> {
  final TextEditingController _controller = TextEditingController(
    text: 'Tesisat',
  );
  int radius = 5;
  List<Map<String, dynamic>> results = [];
  bool loading = false;

  Future<void> _search() async {
    setState(() => loading = true);
    final data = await widget.api.semanticSearch(
      _controller.text.trim(),
      radius,
    );
    final items = (data['results'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    setState(() {
      results = items;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semantik Skill Arama')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Ne ariyorsun?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Yaricap:'),
                Expanded(
                  child: Slider(
                    value: radius.toDouble(),
                    min: 1,
                    max: 25,
                    divisions: 24,
                    label: '$radius km',
                    onChanged: (v) => setState(() => radius = v.toInt()),
                  ),
                ),
                Text('$radius km'),
                const SizedBox(width: 8),
                FilledButton(onPressed: _search, child: const Text('Ara')),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final item = results[i];
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${item['name']} - %${item['matchScore']}',
                            ),
                            subtitle: Text(item['reason']?.toString() ?? ''),
                            trailing: Text('${item['location']}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String initialOf(String input) {
  if (input.isEmpty) {
    return 'K';
  }
  return input.substring(0, 1).toUpperCase();
}
