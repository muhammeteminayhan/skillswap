import 'package:dio/dio.dart';
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
            'id': (m['id'] ?? '').toString(),
            'name': (m['name'] ?? '').toString(),
            'description': (m['description'] ?? '').toString(),
          },
        )
        .toList();
  }

  Future<void> _openAddSkillPage() async {
    final created = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => AddSkillPage(api: widget.api)),
    );
    if (created == null) {
      return;
    }
    setState(() {
      offers.add(created);
    });
  }

  Future<void> _deleteSkill(int index) async {
    final id = offers[index]['id'];
    if (id == null || id.isEmpty) {
      setState(() => offers.removeAt(index));
      return;
    }
    await widget.api.deleteOfferSkill(int.parse(id));
    setState(() => offers.removeAt(index));
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
              onPressed: _openAddSkillPage,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Her yetenege kisa bir aciklama eklemen eslesme kalitesini artirir.',
        ),
        const SizedBox(height: 14),
        _skillSection(offers),
      ],
    );
  }

  Widget _skillSection(List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Expanded(
                child: Text(
                  'Yetenek Kartlari',
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
            return Dismissible(
              key: ValueKey('skill-${skill['id'] ?? i}'),
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
                  await _openEditSkillPage(skill);
                  return false;
                }
                if (direction == DismissDirection.endToStart) {
                  await _deleteSkill(i);
                  return true;
                }
                return false;
              },
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDEAE3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            skill['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (skill['description'] ?? '').isEmpty
                                ? 'Aciklama yok'
                                : skill['description']!,
                            style: const TextStyle(color: Color(0xFF4A5852)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.drag_handle, color: Color(0xFF94A49B)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _openEditSkillPage(Map<String, String> skill) async {
    final updated = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditSkillPage(api: widget.api, skill: skill),
      ),
    );
    if (updated == null) {
      return;
    }
    final index = offers.indexWhere((s) => s['id'] == updated['id']);
    if (index >= 0) {
      setState(() => offers[index] = updated);
    }
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
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class AddSkillPage extends StatefulWidget {
  const AddSkillPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<AddSkillPage> createState() => _AddSkillPageState();
}

class _AddSkillPageState extends State<AddSkillPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String error = '';
  bool saving = false;

  Future<void> _save() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    if (name.isEmpty) {
      setState(() => error = 'Yetenek adi zorunludur.');
      return;
    }
    setState(() {
      saving = true;
      error = '';
    });
    try {
      final created = await widget.api.addOfferSkill(
        name: name,
        description: description,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, created);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map && payload['message'] != null) {
        setState(() => error = payload['message'].toString());
      } else {
        setState(() => error = 'Kayit basarisiz oldu.');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Yetenek Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Yetenek Adi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Yetenek Detayi',
                border: OutlineInputBorder(),
              ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(saving ? 'Kaydediliyor...' : 'Yetenegi Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class EditSkillPage extends StatefulWidget {
  const EditSkillPage({super.key, required this.api, required this.skill});

  final ApiClient api;
  final Map<String, String> skill;

  @override
  State<EditSkillPage> createState() => _EditSkillPageState();
}

class _EditSkillPageState extends State<EditSkillPage> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  String error = '';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.skill['name'] ?? '');
    descriptionController = TextEditingController(
      text: widget.skill['description'] ?? '',
    );
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    if (name.isEmpty) {
      setState(() => error = 'Yetenek adi zorunludur.');
      return;
    }
    final id = widget.skill['id'];
    if (id == null || id.isEmpty) {
      setState(() => error = 'Yetenek kimligi bulunamadi.');
      return;
    }
    setState(() {
      saving = true;
      error = '';
    });
    try {
      final updated = await widget.api.updateOfferSkill(
        skillId: int.parse(id),
        name: name,
        description: description,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map && payload['message'] != null) {
        setState(() => error = payload['message'].toString());
      } else {
        setState(() => error = 'Guncelleme basarisiz oldu.');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yetenek Duzenle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Yetenek Adi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Yetenek Detayi',
                border: OutlineInputBorder(),
              ),
            ),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(saving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
