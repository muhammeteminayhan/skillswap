import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../messages/chat_thread_page.dart';

class SwapsPage extends StatefulWidget {
  const SwapsPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<SwapsPage> createState() => _SwapsPageState();
}

class _SwapsPageState extends State<SwapsPage> {
  final TextEditingController needController = TextEditingController();
  List<Map<String, dynamic>> matches = [];
  List<Map<String, String>> offers = [];
  List<Map<String, String>> wants = [];
  Map<String, dynamic>? profile;
  bool loading = true;
  bool savingNeeds = false;
  String query = '';
  String statusFilter = 'Tumu';
  String timelineFilter = 'Tumu';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.api.swapMatches(),
      widget.api.skills(),
      widget.api.requestWants(),
      widget.api.profile(),
    ]);
    final list = results[0] as List<Map<String, dynamic>>;
    final skills = results[1] as Map<String, dynamic>;
    final wantsRaw = results[2] as List<String>;
    final profileData = results[3] as Map<String, dynamic>;
    setState(() {
      matches = list;
      offers = _mapSkills(skills['offers']);
      wants = wantsRaw
          .map((w) => {'id': w, 'name': w, 'description': ''})
          .toList();
      profile = profileData;
      loading = false;
    });
  }

  Future<void> _addNeedFromField() async {
    final text = needController.text.trim();
    if (text.isEmpty) return;
    await widget.api.addRequestWant(text);
    needController.clear();
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
    // Artik ihtiyaclar swap_requests tablosundan geliyor.
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
    await widget.api.addRequestWant(name);
    await _load();
  }

  Future<void> _deleteNeed(int index) async {
    final name = wants[index]['name'] ?? '';
    setState(() => wants.removeAt(index));
    if (name.isNotEmpty) {
      await widget.api.deleteRequestWant(name);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Takaslar',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          _summaryStrip(),
          const SizedBox(height: 10),
          _filterBar(),
          const SizedBox(height: 10),
          _notificationPanel(),
          const SizedBox(height: 12),
          _needsPanel(),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _matchesPanel(),
        ],
      ),
    );
  }

  Widget _matchesPanel() {
    final items = _filteredMatches();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eslestirilen Takaslar (${items.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text(
            'Henuz eslesen takas bulunamadi.',
            style: TextStyle(color: Color(0xFF6B7A72)),
          )
        else
          ListView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, i) => _matchCard(items[i]),
          ),
      ],
    );
  }

  Widget _summaryStrip() {
    final total = matches.length;
    final active = matches
        .where((e) => _matchStatusLabel(e['status']) == 'Aktif')
        .length;
    final pending = matches
        .where((e) => _matchStatusLabel(e['status']) == 'Bekliyor')
        .length;
    final done = matches
        .where((e) => _matchStatusLabel(e['status']) == 'Tamamlandi')
        .length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Row(
        children: [
          _statItem('Toplam', total.toString(), Icons.all_inclusive),
          _statItem('Bekleyen', pending.toString(), Icons.pending_actions),
          _statItem('Aktif', active.toString(), Icons.verified_outlined),
          _statItem('Tamam', done.toString(), Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1B9C6B), size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          Text(label, style: const TextStyle(color: Color(0xFF6B7A72))),
        ],
      ),
    );
  }

  Widget _filterBar() {
    final statuses = ['Tumu', 'Bekliyor', 'Aktif', 'Tamamlandi'];
    final timelines = ['Tumu', 'Teklif Edilen', 'Devam Eden', 'Gecmis'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Takas ara',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: timelines
              .map(
                (s) => ChoiceChip(
                  label: Text(s),
                  selected: timelineFilter == s,
                  onSelected: (_) => setState(() => timelineFilter = s),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: statuses
              .map(
                (s) => ChoiceChip(
                  label: Text(s),
                  selected: statusFilter == s,
                  onSelected: (_) => setState(() => statusFilter = s),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _notificationPanel() {
    final incoming = matches.where((m) {
      final status = _matchStatusLabel(m['status']?.toString());
      final acceptedByMe = m['acceptedByMe'] == true;
      final acceptedByOther = m['acceptedByOther'] == true;
      return status == 'Bekliyor' && !acceptedByMe && acceptedByOther;
    }).toList();
    if (incoming.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1D6B7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Takas Bildirimi (${incoming.length})',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...incoming.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item['otherName']?.toString() ?? 'Kullanici'),
              subtitle: Text(_titleFromMatch(item)),
              trailing: OutlinedButton(
                onPressed: () => _openMatchDetail(item),
                child: const Text('Teklifi Incele'),
              ),
              onTap: () => _openMatchDetail(item),
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
                  'İhtiyaçlarım',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.filledTonal(
                onPressed: savingNeeds ? null : () => _addOrEditNeed(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: needController,
            decoration: const InputDecoration(
              labelText: 'Yeni ihtiyac ekle',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addNeedFromField(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _addNeedFromField,
              child: const Text('Ihtiyac Ekle'),
            ),
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

  List<Map<String, dynamic>> _filteredMatches() {
    final list = _sortedMatches();
    return list.where((item) {
      final wanted = item['myWanted']?.toString().toLowerCase() ?? '';
      final offered = item['myOffered']?.toString().toLowerCase() ?? '';
      final other = item['otherName']?.toString().toLowerCase() ?? '';
      final status = _matchStatusLabel(item['status']?.toString());
      final acceptedByMe = item['acceptedByMe'] == true;
      final acceptedByOther = item['acceptedByOther'] == true;
      final matchesQuery = query.isEmpty
          ? true
          : wanted.contains(query) ||
              offered.contains(query) ||
              other.contains(query);
      final matchesStatus =
          statusFilter == 'Tumu' ? true : status == statusFilter;
      bool matchesTimeline = true;
      if (timelineFilter == 'Teklif Edilen') {
        matchesTimeline = status == 'Bekliyor' && !acceptedByMe && acceptedByOther;
      } else if (timelineFilter == 'Devam Eden') {
        matchesTimeline = status == 'Aktif';
      } else if (timelineFilter == 'Gecmis') {
        matchesTimeline = status == 'Tamamlandi';
      }
      return matchesQuery && matchesStatus && matchesTimeline;
    }).toList();
  }

  List<Map<String, dynamic>> _sortedMatches() {
    final list = List<Map<String, dynamic>>.from(matches);
    int rank(String status) {
      switch (_matchStatusLabel(status)) {
        case 'Bekliyor':
          return 0;
        case 'Aktif':
          return 1;
        case 'Tamamlandi':
          return 2;
        default:
          return 3;
      }
    }
    list.sort(
      (a, b) => rank(a['status']?.toString() ?? '')
          .compareTo(rank(b['status']?.toString() ?? '')),
    );
    return list;
  }

  String _titleFromMatch(Map<String, dynamic> item) {
    final wanted = item['myWanted']?.toString() ?? 'Genel destek';
    final offered = item['myOffered']?.toString() ?? 'Genel destek';
    return 'Ihtiyacim: $wanted. Karsiliginda $offered sunuyorum.';
  }

  String _matchStatusLabel(String? raw) {
    final value = (raw ?? '').toUpperCase();
    if (value == 'ACCEPTED') return 'Aktif';
    if (value == 'DONE') return 'Tamamlandi';
    if (value == 'PENDING') return 'Bekliyor';
    return 'Bekliyor';
  }

  Widget _statusBadge(String status) {
    Color color = const Color(0xFFE8F6EF);
    Color textColor = const Color(0xFF1B9C6B);
    if (status == 'Bekliyor') {
      color = const Color(0xFFFFF4E5);
      textColor = const Color(0xFFB76A00);
    } else if (status == 'Tamamlandi') {
      color = const Color(0xFFE9F0FF);
      textColor = const Color(0xFF3656B8);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }

  int _matchPercent(Map<String, dynamic> item) {
    int score = 40;
    if ((item['myWanted']?.toString() ?? '').isNotEmpty) score += 25;
    if ((item['myOffered']?.toString() ?? '').isNotEmpty) score += 25;
    final status = _matchStatusLabel(item['status']?.toString());
    if (status == 'Aktif') score += 5;
    if (status == 'Tamamlandi') score += 10;
    return score.clamp(0, 100);
  }

  String _reasonText(String wanted, String offered) {
    if (wanted.isNotEmpty && offered.isNotEmpty) {
      return 'Karsilikli ihtiyac ve yetenek uyumu var.';
    }
    if (wanted.isNotEmpty) {
      return 'Ihtiyac net, uygun aday bulunabilir.';
    }
    if (offered.isNotEmpty) {
      return 'Sunulan yetenekler eslesmeye uygun.';
    }
    return 'Daha iyi eslesme icin istegini detaylandir.';
  }

  Widget _matchCard(Map<String, dynamic> item) {
    final matchId = (item['matchId'] as num?)?.toInt() ?? 0;
    final status = _matchStatusLabel(item['status']?.toString());
    final percent = _matchPercent(item);
    final reason = _reasonText(
      item['myWanted']?.toString() ?? '',
      item['myOffered']?.toString() ?? '',
    );
    final acceptedByMe = item['acceptedByMe'] == true;
    final acceptedByOther = item['acceptedByOther'] == true;
    final doneByMe = item['doneByMe'] == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openMatchDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _titleFromMatch(item),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Istiyor: ${item['myWanted'] ?? '-'}\nSunuyor: ${item['myOffered'] ?? '-'}',
                style: const TextStyle(color: Color(0xFF4A5852)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE8F6EF),
                      color: const Color(0xFF1B9C6B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('%$percent'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Neden eslesti: $reason',
                style: const TextStyle(color: Color(0xFF6B7A72)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: matchId == 0 || acceptedByMe
                        ? null
                        : () async {
                            await widget.api.acceptSwapMatch(matchId);
                            if (!mounted) return;
                            _load();
                          },
                    icon: const Icon(Icons.handshake_outlined),
                    label: Text(
                      acceptedByOther ? 'Teklifi Kabul Et' : 'Teklif Et',
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (status == 'Aktif')
                    FilledButton.icon(
                      onPressed: matchId == 0 || !acceptedByMe || doneByMe
                          ? null
                          : () async {
                              await widget.api.doneSwapMatch(matchId);
                              if (!mounted) return;
                              _load();
                            },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Takas Tamam'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReview(int matchId, bool positive) async {
    final controller = TextEditingController();
    final rating = positive ? 5 : 2;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Degerlendirme'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Yorumun',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gonder'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    await widget.api.reviewSwapMatch(
      matchId: matchId,
      rating: rating,
      comment: controller.text.trim(),
    );
    if (!mounted) return;
    _load();
  }

  void _openMatchDetail(Map<String, dynamic> match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwapMatchDetailPage(
          api: widget.api,
          match: match,
          onUpdated: _load,
        ),
      ),
    );
  }

  Future<void> _openProfile(int userId) async {
    final data = await widget.api.profileById(userId);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final photoUrl = data['photoUrl']?.toString() ?? '';
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE8F6EF),
                    backgroundImage:
                        photoUrl.isEmpty ? null : NetworkImage(photoUrl),
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.black54)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name']?.toString() ?? 'Kullanici',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(data['title']?.toString() ?? ''),
                        Text(
                          data['location']?.toString() ?? '',
                          style: const TextStyle(color: Color(0xFF6B7A72)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data['bio']?.toString() ?? '',
                style: const TextStyle(color: Color(0xFF4A5852)),
              ),
              const SizedBox(height: 10),
              Text('Guven Skoru: ${data['trustScore'] ?? '-'}'),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SwapMatchDetailPage extends StatefulWidget {
  const SwapMatchDetailPage({
    super.key,
    required this.api,
    required this.match,
    required this.onUpdated,
  });

  final ApiClient api;
  final Map<String, dynamic> match;
  final VoidCallback onUpdated;

  @override
  State<SwapMatchDetailPage> createState() => _SwapMatchDetailPageState();
}

class _SwapMatchDetailPageState extends State<SwapMatchDetailPage> {
  Map<String, dynamic>? profile;
  int rating = 5;
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final otherId = (widget.match['otherUserId'] as num?)?.toInt() ?? 0;
    if (otherId == 0) return;
    final data = await widget.api.profileById(otherId);
    if (!mounted) return;
    setState(() => profile = data);
  }

  @override
  Widget build(BuildContext context) {
    final statusRaw = (widget.match['status']?.toString() ?? '').toUpperCase();
    final statusText = _statusText(statusRaw);
    final acceptedByMe = widget.match['acceptedByMe'] == true;
    final acceptedByOther = widget.match['acceptedByOther'] == true;
    final doneByMe = widget.match['doneByMe'] == true;
    final canReview = widget.match['canReview'] == true;
    final matchId = (widget.match['matchId'] as num?)?.toInt() ?? 0;
    final photoUrl = profile?['photoUrl']?.toString() ?? '';
    final otherName = widget.match['otherName']?.toString() ?? 'Kullanici';
    final otherTitle = profile?['title']?.toString() ?? '';
    final otherLocation = profile?['location']?.toString() ?? '';
    final trustScore = profile?['trustScore']?.toString() ?? '-';
    return Scaffold(
      appBar: AppBar(title: const Text('Takas Detayi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDEAE3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE8F6EF),
                  backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.black54)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (otherTitle.isNotEmpty) Text(otherTitle),
                      if (otherLocation.isNotEmpty)
                        Text(
                          otherLocation,
                          style: const TextStyle(color: Color(0xFF6B7A72)),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Guven: $trustScore',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FCFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDEAE3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ihtiyacim: ${widget.match['myWanted'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Karsiliginda: ${widget.match['myOffered'] ?? '-'}'),
                const SizedBox(height: 8),
                Text(
                  'Onun istedigi: ${widget.match['otherWanted'] ?? '-'}\nOnun sundugu: ${widget.match['otherOffered'] ?? '-'}',
                  style: const TextStyle(color: Color(0xFF4A5852)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _statusBadge(statusText),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: matchId == 0 || acceptedByMe
                    ? null
                    : () async {
                        await widget.api.acceptSwapMatch(matchId);
                        widget.onUpdated();
                        if (context.mounted) Navigator.pop(context);
                      },
                icon: const Icon(Icons.handshake_outlined),
                label: Text(
                  acceptedByOther ? 'Teklifi Kabul Et' : 'Takas Teklif Et',
                ),
              ),
              FilledButton.icon(
                onPressed:
                    matchId == 0 || !acceptedByMe || doneByMe || statusRaw != 'ACCEPTED'
                        ? null
                        : () async {
                            await widget.api.doneSwapMatch(matchId);
                            widget.onUpdated();
                            if (context.mounted) Navigator.pop(context);
                          },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Takas Tamam'),
              ),
              OutlinedButton.icon(
                onPressed: statusRaw != 'ACCEPTED'
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatThreadPage(
                              api: widget.api,
                              otherUserId:
                                  (widget.match['otherUserId'] as num).toInt(),
                              otherName:
                                  widget.match['otherName']?.toString() ?? 'Kullanici',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Mesaj'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (canReview)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Degerlendirme',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    final selected = value <= rating;
                    return IconButton(
                      onPressed: () => setState(() => rating = value),
                      icon: Icon(
                        selected ? Icons.star_rounded : Icons.star_border_rounded,
                        color: const Color(0xFFF4B000),
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Yorumun',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    await widget.api.reviewSwapMatch(
                      matchId: matchId,
                      rating: rating,
                      comment: commentController.text.trim(),
                    );
                    widget.onUpdated();
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Yorumu Gonder'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _statusText(String raw) {
    if (raw == 'ACCEPTED') return 'Aktif';
    if (raw == 'DONE') return 'Tamamlandi';
    if (raw == 'PENDING') return 'Bekliyor';
    return 'Bekliyor';
  }

  Widget _statusBadge(String status) {
    Color color = const Color(0xFFE8F6EF);
    Color textColor = const Color(0xFF1B9C6B);
    if (status == 'Bekliyor') {
      color = const Color(0xFFFFF4E5);
      textColor = const Color(0xFFB76A00);
    } else if (status == 'Tamamlandi') {
      color = const Color(0xFFE9F0FF);
      textColor = const Color(0xFF3656B8);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}
