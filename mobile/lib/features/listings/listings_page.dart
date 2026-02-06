import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../messages/chat_thread_page.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  List<Map<String, dynamic>> listings = [];
  bool loading = true;
  String query = '';
  String selectedProfession = 'Tumu';
  String selectedLocation = 'Tumu';
  bool onlyMine = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.listings();
      setState(() => listings = data);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateListingPage(api: widget.api)),
    );
    if (created == true) {
      _load();
    }
  }

  List<String> _uniqueOptions(String key) {
    final values = listings
        .map((e) => e[key]?.toString() ?? '')
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Tumu', ...values];
  }

  List<Map<String, dynamic>> _filteredListings() {
    return listings.where((listing) {
      final title = listing['title']?.toString().toLowerCase() ?? '';
      final profession =
          listing['profession']?.toString().toLowerCase() ?? '';
      final location = listing['location']?.toString().toLowerCase() ?? '';
      final owner = listing['ownerName']?.toString().toLowerCase() ?? '';
      final matchesQuery = query.isEmpty
          ? true
          : title.contains(query) ||
              profession.contains(query) ||
              location.contains(query) ||
              owner.contains(query);
      final matchesProfession = selectedProfession == 'Tumu'
          ? true
          : listing['profession']?.toString() == selectedProfession;
      final matchesLocation = selectedLocation == 'Tumu'
          ? true
          : listing['location']?.toString() == selectedLocation;
      final matchesOwner = onlyMine
          ? (listing['ownerUserId'] as num?)?.toInt() ==
              widget.api.currentUserId()
          : true;
      return matchesQuery &&
          matchesProfession &&
          matchesLocation &&
          matchesOwner;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'İlanlar',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _openCreate,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Her meslekten uzman burada ilan verebilir.'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDDEAE3)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'İlan, meslek, konum ara',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              setState(() => query = value.trim().toLowerCase()),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _filterDropdown(
                              label: 'Meslek',
                              value: selectedProfession,
                              items: _uniqueOptions('profession'),
                              onChanged: (v) => setState(() {
                                selectedProfession = v ?? 'Tumu';
                              }),
                            ),
                            _filterDropdown(
                              label: 'Konum',
                              value: selectedLocation,
                              items: _uniqueOptions('location'),
                              onChanged: (v) => setState(() {
                                selectedLocation = v ?? 'Tumu';
                              }),
                            ),
                            FilterChip(
                              label: const Text('Sadece benim'),
                              selected: onlyMine,
                              onSelected: (v) => setState(() => onlyMine = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._filteredListings().map(
                    (listing) => _ListingCard(
                      listing: listing,
                      api: widget.api,
                      onChanged: _load,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEAE3)),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        items: items
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(v),
              ),
            )
            .toList(),
        onChanged: onChanged,
        hint: Text(label),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.api,
    required this.onChanged,
  });

  final Map<String, dynamic> listing;
  final ApiClient api;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing['imageUrl']?.toString() ?? '';
    final resolvedUrl = api.resolveImageUrl(imageUrl);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailPage(
                listingId: (listing['id'] as num).toInt(),
                api: api,
              ),
            ),
          ).then((changed) {
            if (changed == true) {
              onChanged();
            }
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: imageUrl.isEmpty
                  ? const ColoredBox(color: Color(0xFFE8F6EF))
                  : Image.network(
                      resolvedUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) =>
                          const ColoredBox(color: Color(0xFFE8F6EF)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F6EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      listing['profession']?.toString() ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1B9C6B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF6B7A72)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing['location']?.toString() ?? '',
                          style: const TextStyle(color: Color(0xFF6B7A72)),
                        ),
                      ),
                      Text(
                        listing['ownerName']?.toString() ?? '',
                        style: const TextStyle(color: Color(0xFF6B7A72)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage({
    super.key,
    required this.listingId,
    required this.api,
  });

  final int listingId;
  final ApiClient api;

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  Map<String, dynamic>? detail;
  bool loading = true;
  bool changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.listingDetail(widget.listingId);
      setState(() => detail = data);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final imageUrl = detail!['imageUrl']?.toString() ?? '';
    final resolvedUrl = widget.api.resolveImageUrl(imageUrl);
    final isOwner =
        (detail!['ownerUserId'] as num?)?.toInt() == widget.api.currentUserId();
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('İlan Detayı'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, changed),
          ),
        ),
        body: ListView(
          children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: imageUrl.isEmpty
                  ? const ColoredBox(color: Color(0xFFE8F6EF))
                  : Image.network(
                      resolvedUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) =>
                          const ColoredBox(color: Color(0xFFE8F6EF)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F6EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      detail!['profession']?.toString() ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1B9C6B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail!['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(detail!['description']?.toString() ?? ''),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: Color(0xFF6B7A72)),
                      const SizedBox(width: 6),
                      Text(detail!['location']?.toString() ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 18, color: Color(0xFF6B7A72)),
                      const SizedBox(width: 6),
                      Text(detail!['phone']?.toString() ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Telefon numarasi kopyalandi (demo).',
                                  ),
                                ),
                              ),
                          icon: const Icon(Icons.call),
                          label: const Text('Ara'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatThreadPage(
                                  api: widget.api,
                                  otherUserId:
                                      (detail!['ownerUserId'] as num?)?.toInt() ??
                                          0,
                                  otherName:
                                      detail!['ownerName']?.toString() ??
                                          'Kullanici',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Mesaj Gonder'),
                        ),
                      ),
                    ],
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditListingPage(
                                    api: widget.api,
                                    detail: detail!,
                                  ),
                                ),
                              );
                              if (updated == true) {
                                changed = true;
                                _load();
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Duzenle'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('İlan silinsin mi?'),
                                  content: const Text(
                                    'Bu islem geri alinamaz.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Vazgec'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await widget.api
                                    .deleteListing(widget.listingId);
                                if (!mounted) return;
                                Navigator.pop(context, true);
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Sil'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final professionController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final imageUrlController = TextEditingController();
  int creditBalance = 0;
  int pricePerCredit = 50;

  String error = '';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    final data = await widget.api.creditBalance();
    if (!mounted) return;
    setState(() {
      creditBalance = (data['balance'] as num?)?.toInt() ?? 0;
      pricePerCredit = (data['pricePerCredit'] as num?)?.toInt() ?? 50;
    });
  }

  Future<void> _submit() async {
    setState(() {
      error = '';
      saving = true;
    });
    try {
      if (imageUrlController.text.trim().isEmpty) {
        setState(() {
          error = 'Fotograf URL zorunludur.';
          saving = false;
        });
        return;
      }
      await widget.api.createListing(
        profession: professionController.text.trim(),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        phone: phoneController.text.trim(),
        location: locationController.text.trim(),
        imageUrl: imageUrlController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map && payload['message'] != null) {
        setState(() => error = payload['message'].toString());
      } else {
        setState(() => error = 'İlan kaydi basarisiz. Kredi bakiyeni kontrol et.');
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
      appBar: AppBar(title: const Text('İlan Ver')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _input(professionController, 'Meslek (Orn. Elektrik Ustasi)'),
          _input(titleController, 'İlan Basligi'),
          _input(descriptionController, 'İlan Detayi', maxLines: 4),
          _input(phoneController, 'İletisim Numarasi'),
          _input(locationController, 'Konum'),
          const SizedBox(height: 6),
          Text(
            'Meslek Fotografı (URL)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _input(
            imageUrlController,
            'Fotograf URL',
            onChanged: (_) => setState(() {}),
          ),
          if (imageUrlController.text.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrlController.text.trim(),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  height: 160,
                  color: const Color(0xFFF1F7F4),
                  alignment: Alignment.center,
                  child: const Text('URL ile resim yuklenemedi'),
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F7F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDEAE3)),
              ),
              child: const Center(child: Text('Fotoğraf URL girilmedi')),
            ),
          const SizedBox(height: 8),
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
                const Text(
                  'İlan Komisyonu',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('Bu ilan icin 1 kredi komisyon alinacaktir.'),
                const SizedBox(height: 4),
                Text('Mevcut bakiyen: $creditBalance kredi'),
                Text('Komisyon: 1 kredi'),
              ],
            ),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: saving ? null : _submit,
            icon: const Icon(Icons.publish),
            label: Text(
              saving ? 'Kaydediliyor...' : '1 Kredi ile Yayınla',
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class EditListingPage extends StatefulWidget {
  const EditListingPage({super.key, required this.api, required this.detail});

  final ApiClient api;
  final Map<String, dynamic> detail;

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  late final TextEditingController professionController;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController phoneController;
  late final TextEditingController locationController;
  late final TextEditingController imageUrlController;

  String error = '';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    professionController =
        TextEditingController(text: widget.detail['profession']?.toString());
    titleController =
        TextEditingController(text: widget.detail['title']?.toString());
    descriptionController =
        TextEditingController(text: widget.detail['description']?.toString());
    phoneController =
        TextEditingController(text: widget.detail['phone']?.toString());
    locationController =
        TextEditingController(text: widget.detail['location']?.toString());
    imageUrlController =
        TextEditingController(text: widget.detail['imageUrl']?.toString());
  }

  Future<void> _submit() async {
    setState(() {
      error = '';
      saving = true;
    });
    try {
      String imageUrl = imageUrlController.text.trim();
      await widget.api.updateListing(
        listingId: (widget.detail['id'] as num).toInt(),
        profession: professionController.text.trim(),
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        phone: phoneController.text.trim(),
        location: locationController.text.trim(),
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map && payload['message'] != null) {
        setState(() => error = payload['message'].toString());
      } else {
        setState(() => error = 'İlan guncelleme basarisiz.');
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrlController.text.trim();
    final resolvedUrl = widget.api.resolveImageUrl(imageUrl);
    return Scaffold(
      appBar: AppBar(title: const Text('İlanı Duzenle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _input(professionController, 'Meslek (Orn. Elektrik Ustasi)'),
          _input(titleController, 'İlan Basligi'),
          _input(descriptionController, 'İlan Detayi', maxLines: 4),
          _input(phoneController, 'İletisim Numarasi'),
          _input(locationController, 'Konum'),
          const SizedBox(height: 6),
          Text(
            'Meslek Fotografı (URL)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _input(
            imageUrlController,
            'Fotograf URL',
            onChanged: (_) => setState(() {}),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isEmpty
                ? const ColoredBox(
                    color: Color(0xFFF1F7F4),
                    child: SizedBox(height: 160),
                  )
                : Image.network(
                    resolvedUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => const ColoredBox(
                      color: Color(0xFFF1F7F4),
                      child: SizedBox(height: 160),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: saving ? null : _submit,
            icon: const Icon(Icons.save),
            label: Text(saving ? 'Kaydediliyor...' : 'Guncelle'),
          ),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
