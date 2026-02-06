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
  int creditBalance = 0;
  int pricePerCredit = 50;
  double platformFeeRate = 0.1;

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
        widget.api.creditBalance(),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final profile = results[1] as Map<String, dynamic>;
      final balance = results[2] as Map<String, dynamic>;
      setState(() {
        dashboard = data;
        profilePhotoUrl = profile['photoUrl']?.toString() ?? '';
        creditBalance = (balance['balance'] as num?)?.toInt() ?? 0;
        pricePerCredit = (balance['pricePerCredit'] as num?)?.toInt() ?? 50;
        platformFeeRate = (balance['platformFeeRate'] as num?)?.toDouble() ?? 0.1;
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
              ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
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
          _creditSummaryCard(),
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

  Widget _creditSummaryCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreditDetailPage(api: widget.api),
          ),
        ).then((_) => _load());
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDEAE3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: Color(0xFF1B9C6B)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Kredi Bakiyen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF6B7A72)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '$creditBalance',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('kredi'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '1 kredi = $pricePerCredit TL · Platform komisyonu %${(platformFeeRate * 100).toInt()}',
              style: const TextStyle(color: Color(0xFF4A5852)),
            ),
          ],
        ),
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

class CreditDetailPage extends StatefulWidget {
  const CreditDetailPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<CreditDetailPage> createState() => _CreditDetailPageState();
}

class _CreditDetailPageState extends State<CreditDetailPage> {
  int creditBalance = 0;
  int pricePerCredit = 50;
  double platformFeeRate = 0.1;
  List<Map<String, dynamic>> creditTransactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.api.creditBalance(),
      widget.api.creditTransactions(),
    ]);
    final balance = results[0] as Map<String, dynamic>;
    final transactions = results[1] as List<Map<String, dynamic>>;
    if (!mounted) return;
    setState(() {
      creditBalance = (balance['balance'] as num?)?.toInt() ?? 0;
      pricePerCredit = (balance['pricePerCredit'] as num?)?.toInt() ?? 50;
      platformFeeRate =
          (balance['platformFeeRate'] as num?)?.toDouble() ?? 0.1;
      creditTransactions = transactions;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kredi Detayi')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _creditSummaryCard(),
                const SizedBox(height: 12),
                _creditTransactionsCard(),
              ],
            ),
    );
  }

  Widget _creditSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFF1B9C6B)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kredi Bakiyen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton(
                onPressed: _openPurchaseCredits,
                child: const Text('Kredi Satin Al'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$creditBalance',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Text('kredi'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '1 kredi = $pricePerCredit TL · Platform komisyonu %${(platformFeeRate * 100).toInt()}',
            style: const TextStyle(color: Color(0xFF4A5852)),
          ),
        ],
      ),
    );
  }

  Widget _creditTransactionsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Islem Gecmisi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (creditTransactions.isEmpty)
            const Text(
              'Henuz kredi islemi yok.',
              style: TextStyle(color: Color(0xFF6B7A72)),
            )
          else
            ...creditTransactions.map(_transactionTile).toList(),
        ],
      ),
    );
  }

  Widget _transactionTile(Map<String, dynamic> txn) {
    final type = txn['type']?.toString() ?? '';
    final credits = (txn['credits'] as num?)?.toInt() ?? 0;
    final amount = (txn['amountTl'] as num?)?.toInt() ?? 0;
    final createdAt = txn['createdAt']?.toString() ?? '';
    String title = 'Kredi Islemi';
    if (type == 'PURCHASE') title = 'Kredi Satin Alimi';
    if (type == 'MATCH_PAYMENT') title = 'Takas Kredisi Odemesi';
    if (type == 'MATCH_INCOME') title = 'Takas Kazanci';
    if (type == 'LISTING_FEE') title = 'Ilan Komisyonu';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Row(
        children: [
          Icon(
            type == 'PURCHASE'
                ? Icons.add_circle_outline
                : type == 'MATCH_PAYMENT'
                    ? Icons.remove_circle_outline
                    : Icons.check_circle_outline,
            color: const Color(0xFF1B9C6B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (createdAt.isNotEmpty)
                  Text(
                    createdAt,
                    style: const TextStyle(
                      color: Color(0xFF6B7A72),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                credits == 0 ? '' : '${credits > 0 ? '+' : ''}$credits kredi',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                amount == 0 ? '' : '$amount TL',
                style: const TextStyle(color: Color(0xFF4A5852)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openPurchaseCredits() async {
    final controller = TextEditingController();
    int selected = 20;
    final purchased = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Kredi Satin Al'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: [10, 20, 40, 60].map((value) {
                  final active = selected == value;
                  return ChoiceChip(
                    label: Text('$value kredi'),
                    selected: active,
                    onSelected: (_) => setModalState(() => selected = value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ozel kredi miktari',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tutar: ${(selected * pricePerCredit)} TL',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Satin Al'),
            ),
          ],
        ),
      ),
    );
    if (purchased != true) return;
    final custom = int.tryParse(controller.text.trim());
    final credits = (custom != null && custom > 0) ? custom : selected;
    await widget.api.purchaseCredits(credits);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kredi satin alimi tamamlandi.')),
    );
    await _load();
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
