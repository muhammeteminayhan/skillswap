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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.api.requests();
    setState(() {
      items = list;
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
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Card(
                        child: ListTile(
                          title: Text(item['text']?.toString() ?? ''),
                          subtitle: Text(
                            'Istiyor: ${item['wantedSkill']}\nSunuyor: ${item['offeredSkill']}',
                          ),
                          trailing: Text(item['status']?.toString() ?? ''),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
