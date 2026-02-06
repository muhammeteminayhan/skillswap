import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class SwapsPage extends StatefulWidget {
  const SwapsPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<SwapsPage> createState() => _SwapsPageState();
}

class _SwapsPageState extends State<SwapsPage> {
  final TextEditingController controller = TextEditingController();
  List<Map<String, dynamic>> items = [];
  List<Map<String, String>> offers = [];
  List<Map<String, String>> wants = [];
  Map<String, dynamic>? profile;
  bool loading = true;
  bool savingNeeds = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.api.requests(),
      widget.api.skills(),
      widget.api.profile(),
    ]);
    final list = results[0] as List<Map<String, dynamic>>;
    final skills = results[1] as Map<String, dynamic>;
    final profileData = results[2] as Map<String, dynamic>;
    setState(() {
      items = list;
      offers = _mapSkills(skills['offers']);
      wants = _mapSkills(skills['wants']);
      profile = profileData;
      loading = false;
    });
  }

  Future<void> _create() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    await widget.api.createRequest(text);
    controller.clear();
    await _load();
  }

  List<Map<String, String>> _mapSkills(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (m) => {
            'id': (m['id'] ?? '').toString(),
            'name': (m['name'] ?? '').toString(),
            'description': (m['description'] ?? '').toString(),
          },
        )
        .toList();
  }

  Future<void> _saveSkills() async {
    setState(() => savingNeeds = true);
    try {
      final updated = await widget.api.updateSkills(offers, wants);
      setState(() {
        offers = _mapSkills(updated['offers']);
        wants = _mapSkills(updated['wants']);
      });
    } finally {
      setState(() => savingNeeds = false);
    }
  }

  Future<void> _addOrEditNeed({Map<String, String>? existing, int? index}) async {
    final nameController = TextEditingController(text: existing?['name'] ?? '');
    final descController =
        TextEditingController(text: existing?['description'] ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Ihtiyac Ekle' : 'Ihtiyac Duzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Ihtiyac adi'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Aciklama'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      final item = {
        'id': existing?['id'] ?? '',
        'name': name,
        'description': descController.text.trim(),
      };
      if (index != null && index >= 0 && index < wants.length) {
        wants[index] = item;
      } else {
        wants.add(item);
      }
    });
    await _saveSkills();
  }

  Future<void> _deleteNeed(int index) async {
    setState(() => wants.removeAt(index));
    await _saveSkills();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Takas Istekleri',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          _completionPanel(),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Yeni istek',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _create,
            child: const Text('AI ile Istek Olustur'),
          ),
          const SizedBox(height: 8),
          _needsPanel(),
          const SizedBox(height: 12),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final requestId = (item['id'] as num?)?.toInt() ?? 0;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['text']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Istiyor: ${item['wantedSkill']}\nSunuyor: ${item['offeredSkill']}',
                                style: const TextStyle(color: Color(0xFF4A5852)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(item['status']?.toString() ?? ''),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: requestId == 0
                                        ? null
                                        : () => widget.api.sendSwapFeedback(
                                              requestId: requestId,
                                              success: true,
                                            ),
                                    icon: const Icon(Icons.thumb_up_alt_outlined),
                                    label: const Text('Basarili'),
                                  ),
                                  const SizedBox(width: 6),
                                  TextButton.icon(
                                    onPressed: requestId == 0
                                        ? null
                                        : () => widget.api.sendSwapFeedback(
                                              requestId: requestId,
                                              success: false,
                                            ),
                                    icon:
                                        const Icon(Icons.thumb_down_alt_outlined),
                                    label: const Text('Basarisiz'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _completionPanel() {
    final data = profile ?? {};
    final location = data['location']?.toString() ?? '';
    final title = data['title']?.toString() ?? '';
    final bio = data['bio']?.toString() ?? '';
    final checks = [
      location.isNotEmpty,
      title.isNotEmpty,
      bio.isNotEmpty,
      offers.isNotEmpty,
      wants.isNotEmpty,
    ];
    final completed = checks.where((v) => v).length;
    final percent =
        (completed / checks.length).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Takas Kalitesi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: const Color(0xFFE8F6EF),
            color: const Color(0xFF1B9C6B),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text('Profil tamamlanma: %${(percent * 100).round()}'),
          const SizedBox(height: 6),
          if (percent < 1)
            Text(
              'Eksikler: '
              '${location.isEmpty ? 'konum, ' : ''}'
              '${title.isEmpty ? 'unvan, ' : ''}'
              '${bio.isEmpty ? 'bio, ' : ''}'
              '${offers.isEmpty ? 'yetenek, ' : ''}'
              '${wants.isEmpty ? 'ihtiyac' : ''}',
              style: const TextStyle(color: Color(0xFF6B7A72)),
            ),
        ],
      ),
    );
  }

  Widget _needsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ihtiyaclarim',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.filledTonal(
                onPressed: savingNeeds ? null : () => _addOrEditNeed(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (wants.isEmpty)
            const Text('Henuz ihtiyac yok. + ile ekleyebilirsin.'),
          ...List.generate(wants.length, (index) {
            final item = wants[index];
            return Dismissible(
              key: ValueKey('need-${item['id'] ?? index}'),
              background: _swipeBackground(
                alignment: Alignment.centerLeft,
                color: const Color(0xFF1B9C6B),
                icon: Icons.edit,
                label: 'Duzenle',
              ),
              secondaryBackground: _swipeBackground(
                alignment: Alignment.centerRight,
                color: const Color(0xFFE45757),
                icon: Icons.delete,
                label: 'Sil',
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await _addOrEditNeed(existing: item, index: index);
                  return false;
                }
                if (direction == DismissDirection.endToStart) {
                  await _deleteNeed(index);
                  return true;
                }
                return false;
              },
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDEAE3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((item['description'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item['description'] ?? '',
                        style: const TextStyle(color: Color(0xFF4A5852)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: color,
      child: Row(
        mainAxisAlignment: alignment == Alignment.centerLeft
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
