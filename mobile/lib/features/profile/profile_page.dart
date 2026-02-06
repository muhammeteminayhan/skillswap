import 'package:dio/dio.dart';
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
    final photoUrl = profile!['photoUrl']?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDDEAE3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFE8F6EF),
                  backgroundImage: photoUrl.isEmpty
                      ? null
                      : NetworkImage(photoUrl),
                  child: photoUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.black54,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  profile!['name']?.toString() ?? '',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.session.email,
                  style: const TextStyle(color: Color(0xFF4A5852)),
                ),
                const SizedBox(height: 6),
                Text(
                  profile!['title']?.toString() ?? '',
                  style: const TextStyle(color: Color(0xFF4A5852)),
                ),
                Text(
                  profile!['location']?.toString() ?? '',
                  style: const TextStyle(color: Color(0xFF6B7A72)),
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
              _badgeCard([
                'assets/Güvenli Liman.png',
                'assets/İtibar Sahibi.png',
                'assets/Kusursuz Hizmet.png',
                'assets/Vizyoner.png',
              ]),
            ],
          ),
          const SizedBox(height: 14),
          Card(
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
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditProfilePage(api: widget.api, profile: profile!),
                ),
              );
              if (updated == true) {
                widget.api.profile().then((p) => setState(() => profile = p));
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Profili Duzenle'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return SizedBox(
      width: 170,
      height: 140,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDEAE3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1B9C6B), size: 28),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Color(0xFF4A5852))),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeCard(List<String> assetPaths) {
    return SizedBox(
      width: 170,
      height: 140,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDEAE3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: assetPaths
                  .map(
                    (path) => Image.asset(
                      path,
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.api, required this.profile});

  final ApiClient api;
  final Map<String, dynamic> profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController nameController;
  late final TextEditingController titleController;
  late final TextEditingController locationController;
  late final TextEditingController bioController;
  late final TextEditingController photoController;

  String error = '';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.profile['name']?.toString() ?? '',
    );
    titleController = TextEditingController(
      text: widget.profile['title']?.toString() ?? '',
    );
    locationController = TextEditingController(
      text: widget.profile['location']?.toString() ?? '',
    );
    bioController = TextEditingController(
      text: widget.profile['bio']?.toString() ?? '',
    );
    photoController = TextEditingController(
      text: widget.profile['photoUrl']?.toString() ?? '',
    );
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      error = '';
    });
    try {
      await widget.api.updateProfile(
        name: nameController.text.trim(),
        title: titleController.text.trim(),
        location: locationController.text.trim(),
        bio: bioController.text.trim(),
        photoUrl: photoController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map && payload['message'] != null) {
        setState(() => error = payload['message'].toString());
      } else {
        setState(() => error = 'Guncelleme basarisiz.');
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
      appBar: AppBar(title: const Text('Profil Duzenle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _input(nameController, 'Ad Soyad'),
            _input(titleController, 'Unvan'),
            _input(locationController, 'Konum'),
            _input(bioController, 'Hakkimda', maxLines: 3),
            _input(photoController, 'Profil Fotograf URL', maxLines: 1),
            if (error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 12),
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

  Widget _input(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
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
                      onPressed: () async {
                        try {
                          await widget.api.activateBoost();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Aktifleştirildi'),
                            ),
                          );
                        } catch (_) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Aktifleştirilemedi'),
                            ),
                          );
                        }
                      },
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
