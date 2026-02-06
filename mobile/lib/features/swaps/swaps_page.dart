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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openTimelinePage,
              icon: const Icon(Icons.timeline),
              label: const Text('Takas Surecini Gor'),
            ),
          ),
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
      return matchesQuery && matchesStatus;
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
                        try {
                          await widget.api.acceptSwapMatch(matchId);
                          if (!mounted) return;
                          _load();
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kredi yetersiz. Once kredi tamamla.'),
                            ),
                          );
                        }
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

  void _openTimelinePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SwapTimelinePage(api: widget.api),
      ),
    );
  }

  Future<void> _openProfile(int userId) async {
    final data = await widget.api.profileById(userId);
    final reviews = await widget.api.swapReviewsForUser(userId);
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
              if (reviews.isNotEmpty) ...[
                const Text(
                  'Yorumlar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ...reviews.take(3).map(_reviewCard).toList(),
                if (reviews.length > 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserReviewsPage(
                              api: widget.api,
                              userId: userId,
                              userName: data['name']?.toString() ?? 'Kullanici',
                            ),
                          ),
                        );
                      },
                      child: const Text('Tum yorumlari gor'),
                    ),
                  ),
              ],
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

  Widget _reviewCard(Map<String, dynamic> review) {
    final ratingValue = (review['rating'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review['fromName']?.toString() ?? 'Kullanici',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              final filled = i < ratingValue;
              return Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFF4B000),
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            review['comment']?.toString() ?? '',
            style: const TextStyle(color: Color(0xFF4A5852)),
          ),
          const SizedBox(height: 4),
          Text(
            review['createdAt']?.toString() ?? '',
            style: const TextStyle(color: Color(0xFF6B7A72), fontSize: 12),
          ),
        ],
      ),
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

class SwapTimelinePage extends StatefulWidget {
  const SwapTimelinePage({super.key, required this.api});

  final ApiClient api;

  @override
  State<SwapTimelinePage> createState() => _SwapTimelinePageState();
}

class _SwapTimelinePageState extends State<SwapTimelinePage> {
  List<Map<String, dynamic>> matches = [];
  bool loading = true;
  String filter = 'Tumu';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.api.swapMatches();
    setState(() {
      matches = list;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Takas Sureci')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip('Tumu'),
                _chip('Devam Eden'),
                _chip('Tamamlanmis'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filtered().length,
                      itemBuilder: (context, i) {
                        final item = _filtered()[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(_titleFromMatch(item)),
                            subtitle: Text(
                              'Durum: ${_statusLabel(item['status']?.toString())}',
                            ),
                            trailing: OutlinedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SwapMatchDetailPage(
                                      api: widget.api,
                                      match: item,
                                      onUpdated: _load,
                                    ),
                                  ),
                                );
                                _load();
                              },
                              child: const Text('Detay'),
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

  Widget _chip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: filter == label,
      onSelected: (_) => setState(() => filter = label),
    );
  }

  List<Map<String, dynamic>> _filtered() {
    final list = List<Map<String, dynamic>>.from(matches);
    if (filter == 'Devam Eden') {
      return list
          .where((m) => _statusLabel(m['status']?.toString()) == 'Aktif')
          .toList();
    }
    if (filter == 'Tamamlanmis') {
      return list
          .where((m) => _statusLabel(m['status']?.toString()) == 'Tamamlandi')
          .toList();
    }
    return list;
  }

  String _statusLabel(String? raw) {
    final value = (raw ?? '').toUpperCase();
    if (value == 'ACCEPTED') return 'Aktif';
    if (value == 'DONE') return 'Tamamlandi';
    if (value == 'PENDING') return 'Bekliyor';
    return 'Bekliyor';
  }

  String _titleFromMatch(Map<String, dynamic> item) {
    final wanted = item['myWanted']?.toString() ?? 'Genel destek';
    final offered = item['myOffered']?.toString() ?? 'Genel destek';
    return 'Ihtiyacim: $wanted. Karsiliginda $offered sunuyorum.';
  }
}

class _SwapMatchDetailPageState extends State<SwapMatchDetailPage> {
  Map<String, dynamic>? profile;
  int rating = 5;
  final TextEditingController commentController = TextEditingController();
  List<Map<String, dynamic>> reviews = [];
  int creditBalance = 0;
  int pricePerCredit = 50;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadReviews();
    _loadCreditBalance();
  }

  Future<void> _loadProfile() async {
    final otherId = (widget.match['otherUserId'] as num?)?.toInt() ?? 0;
    if (otherId == 0) return;
    final data = await widget.api.profileById(otherId);
    if (!mounted) return;
    setState(() => profile = data);
  }

  Future<void> _loadReviews() async {
    final matchId = (widget.match['matchId'] as num?)?.toInt() ?? 0;
    if (matchId == 0) return;
    final data = await widget.api.swapReviewsForMatch(matchId);
    if (!mounted) return;
    setState(() => reviews = data);
  }

  Future<void> _loadCreditBalance() async {
    final data = await widget.api.creditBalance();
    if (!mounted) return;
    setState(() {
      creditBalance = (data['balance'] as num?)?.toInt() ?? 0;
      pricePerCredit = (data['pricePerCredit'] as num?)?.toInt() ?? 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusRaw = (widget.match['status']?.toString() ?? '').toUpperCase();
    final statusText = _statusText(statusRaw);
    final acceptedByMe = widget.match['acceptedByMe'] == true;
    final acceptedByOther = widget.match['acceptedByOther'] == true;
    final doneByMe = widget.match['doneByMe'] == true;
    final matchId = (widget.match['matchId'] as num?)?.toInt() ?? 0;
    final myReview = reviews.firstWhere(
      (r) => (r['fromUserId'] as num?)?.toInt() == widget.api.currentUserId(),
      orElse: () => {},
    );
    final hasMyReview = myReview.isNotEmpty;
    final canReview =
        statusRaw == 'DONE' && widget.match['canReview'] == true && !hasMyReview;
    final photoUrl = profile?['photoUrl']?.toString() ?? '';
    final otherName = widget.match['otherName']?.toString() ?? 'Kullanici';
    final otherTitle = profile?['title']?.toString() ?? '';
    final otherLocation = profile?['location']?.toString() ?? '';
    final trustScore = profile?['trustScore']?.toString() ?? '-';
    final myCredit = (widget.match['myCredit'] as num?)?.toInt() ?? 0;
    final otherCredit = (widget.match['otherCredit'] as num?)?.toInt() ?? 0;
    final creditDiff = (widget.match['creditDiff'] as num?)?.toInt() ?? 0;
    final fairness = (widget.match['fairnessPercent'] as num?)?.toInt() ?? 100;
    final creditRequiredByMe = widget.match['creditRequiredByMe'] == true;
    final requiredCredits = (widget.match['requiredCredits'] as num?)?.toInt() ?? 0;
    final requiredAmount = (widget.match['requiredAmountTl'] as num?)?.toInt() ??
        (requiredCredits * pricePerCredit);
    final platformFee =
        (widget.match['platformFeeAmountTl'] as num?)?.toInt() ?? 0;
    final payout =
        (widget.match['payoutAmountTl'] as num?)?.toInt() ?? requiredAmount;
    final hasEnoughCredits = !creditRequiredByMe || creditBalance >= requiredCredits;
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
          _creditInfoCard(
            myCredit: myCredit,
            otherCredit: otherCredit,
            diff: creditDiff,
            fairness: fairness,
            creditRequiredByMe: creditRequiredByMe,
            requiredCredits: requiredCredits,
            requiredAmount: requiredAmount,
            platformFee: platformFee,
            payout: payout,
            hasEnoughCredits: hasEnoughCredits,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: matchId == 0 || acceptedByMe || !hasEnoughCredits
                    ? null
                    : () async {
                        try {
                          await widget.api.acceptSwapMatch(matchId);
                          widget.onUpdated();
                          if (context.mounted) Navigator.pop(context);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kredi yetersiz. Once kredi tamamla.'),
                            ),
                          );
                        }
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
          if (!hasEnoughCredits && creditRequiredByMe) ...[
            const SizedBox(height: 8),
            Text(
              'Takas onayi icin $requiredCredits kredi gerekli. Kredi tamamla.',
              style: const TextStyle(color: Color(0xFFB76A00)),
            ),
          ],
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
                    await _loadReviews();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yorumun kaydedildi.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Yorumu Gonder'),
                ),
              ],
            ),
          if (!canReview && myReview.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Yorumun (degistirilemez)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            _reviewCard(myReview),
          ],
          if (reviews.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Bu Takas Yorumlari',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...reviews.map(_reviewCard).toList(),
          ],
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

  Widget _creditInfoCard({
    required int myCredit,
    required int otherCredit,
    required int diff,
    required int fairness,
    required bool creditRequiredByMe,
    required int requiredCredits,
    required int requiredAmount,
    required int platformFee,
    required int payout,
    required bool hasEnoughCredits,
  }) {
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
          const Text(
            'Kredi Dengesi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('Senin hizmetin: $myCredit kredi')),
              Expanded(child: Text('Karsi taraf: $otherCredit kredi')),
            ],
          ),
          const SizedBox(height: 4),
          Text('Mevcut kredin: $creditBalance kredi'),
          const SizedBox(height: 6),
          Text('Fark: $diff kredi'),
          Text('Adalet skoru: %$fairness'),
          if (diff > 0) ...[
            const SizedBox(height: 6),
            Text(
              creditRequiredByMe
                  ? 'Bu takasta $requiredCredits kredi tamamlaman gerekiyor.'
                  : 'Karsi tarafin $requiredCredits kredi tamamlamasi gerekiyor.',
              style: const TextStyle(color: Color(0xFF4A5852)),
            ),
            const SizedBox(height: 6),
            Text('Tutar: $requiredAmount TL'),
            Text('Platform hizmet bedeli: $platformFee TL'),
            Text('Karsi tarafa giden: $payout TL'),
          ],
          if (creditRequiredByMe && diff > 0) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                await widget.api.purchaseCredits(requiredCredits);
                await _loadCreditBalance();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kredi satin alimi tamamlandi.')),
                  );
                }
              },
              icon: const Icon(Icons.credit_card),
              label: const Text('Kredi Tamamla'),
            ),
            if (!hasEnoughCredits)
              const Text(
                'Kredi bakiyen yetersiz.',
                style: TextStyle(color: Color(0xFFB76A00)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final ratingValue = (review['rating'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review['fromName']?.toString() ?? 'Kullanici',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              final filled = i < ratingValue;
              return Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFF4B000),
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            review['comment']?.toString() ?? '',
            style: const TextStyle(color: Color(0xFF4A5852)),
          ),
          const SizedBox(height: 4),
          Text(
            review['createdAt']?.toString() ?? '',
            style: const TextStyle(color: Color(0xFF6B7A72), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class UserReviewsPage extends StatefulWidget {
  const UserReviewsPage({
    super.key,
    required this.api,
    required this.userId,
    required this.userName,
  });

  final ApiClient api;
  final int userId;
  final String userName;

  @override
  State<UserReviewsPage> createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends State<UserReviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.api.swapReviewsForUser(widget.userId);
    if (!mounted) return;
    setState(() {
      reviews = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.userName} Yorumlari')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: reviews.isEmpty
                  ? const [
                      Center(child: Text('Henuz yorum bulunmuyor.')),
                    ]
                  : reviews.map(_reviewCard).toList(),
            ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final ratingValue = (review['rating'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review['fromName']?.toString() ?? 'Kullanici',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              final filled = i < ratingValue;
              return Icon(
                filled ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFF4B000),
                size: 18,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            review['comment']?.toString() ?? '',
            style: const TextStyle(color: Color(0xFF4A5852)),
          ),
          const SizedBox(height: 4),
          Text(
            review['createdAt']?.toString() ?? '',
            style: const TextStyle(color: Color(0xFF6B7A72), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
