import 'package:flutter/material.dart';

import '../../core/models/auth_session.dart';
import '../../core/network/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.api, required this.session});

  final ApiClient api;
  final AuthSession session;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    widget.api.profile().then((p) => setState(() => profile = p));
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final trustScore = (profile!['trustScore'] as num?)?.toInt() ?? 0;
    final tokenBalance = (profile!['tokenBalance'] as num?)?.toInt() ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A3D48),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile!['name']?.toString() ?? '',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.session.email,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  profile!['title']?.toString() ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  profile!['location']?.toString() ?? '',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard(
                'Guven Skoru',
                '$trustScore/100',
                Icons.verified_user_rounded,
              ),
              _statCard('Token Miktari', '$tokenBalance', Icons.stars_rounded),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            color: const Color(0xFF1E2E53),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Sinirsiz swipe, oncelikli eslesme, AI raporlari'),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BoostPage(api: widget.api),
                      ),
                    ),
                    child: const Text('Boost Paketleri'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout),
            label: const Text('Cikis Yap'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF083743),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF24C58E)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class BoostPage extends StatefulWidget {
  const BoostPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<BoostPage> createState() => _BoostPageState();
}

class _BoostPageState extends State<BoostPage> {
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    widget.api.boostPlans().then((v) => setState(() => data = v));
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final plans = (data!['plans'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Skill Boost')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(data!['description']?.toString() ?? ''),
          const SizedBox(height: 12),
          ...plans.map((p) {
            final benefits = (p['benefits'] as List<dynamic>? ?? []).join(
              '\n• ',
            );
            return Card(
              color: const Color(0xFF2B1E5A),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['title']}  ${p['price']}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• $benefits'),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Paketi Aktiflestir'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
