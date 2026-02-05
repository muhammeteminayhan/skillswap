import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  List<Map<String, String>> offers = [];
  bool loading = true;
  String status = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.api.skills();
    setState(() {
      offers = _mapSkills(data['offers']);
      loading = false;
    });
  }

  List<Map<String, String>> _mapSkills(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (m) => {
            'name': (m['name'] ?? '').toString(),
            'description': (m['description'] ?? '').toString(),
          },
        )
        .toList();
  }

  void _addSkill(List<Map<String, String>> target) {
    setState(() => target.add({'name': '', 'description': ''}));
  }

  void _removeSkill(List<Map<String, String>> target, int index) {
    setState(() => target.removeAt(index));
  }

  Future<void> _save() async {
    final cleanOffers = offers
        .where((s) => (s['name'] ?? '').trim().isNotEmpty)
        .map(
          (s) => {
            'name': (s['name'] ?? '').trim(),
            'description': (s['description'] ?? '').trim(),
          },
        )
        .toList();

    await widget.api.updateSkills(cleanOffers, []);
    setState(() => status = 'Yetenekler ve aciklamalar kaydedildi.');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Yeteneklerim',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => _addSkill(offers),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Her yetenege kisa bir aciklama eklemen eslesme kalitesini artirir.',
        ),
        const SizedBox(height: 14),
        _skillSection('Yeteneklerim', offers),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Kaydet'),
        ),
        const SizedBox(height: 8),
        Text(status),
      ],
    );
  }

  Widget _skillSection(String title, List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3D48),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (items.isEmpty)
            const Text(
              'Henuz yetenek yok. Sag ustteki + butonu ile ekleyebilirsin.',
            ),
          ...List.generate(items.length, (i) {
            final skill = items[i];
            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF06323D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: skill['name'] ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Yetenek adi',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => skill['name'] = v,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: skill['description'] ?? '',
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Aciklama',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => skill['description'] = v,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _removeSkill(items, i),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Sil'),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
