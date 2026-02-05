import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const SkillswapApp());
}

class SkillswapApp extends StatelessWidget {
  const SkillswapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap Health',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HealthPage(),
    );
  }
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  String _status = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchHealth();
  }

  String _baseUrl() {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  Future<void> _fetchHealth() async {
    setState(() => _status = 'Loading...');
    final dio = Dio(BaseOptions(baseUrl: _baseUrl(), connectTimeout: const Duration(seconds: 5)));
    try {
      final response = await dio.get('/health');
      if (response.statusCode == 200 && response.data == 'OK') {
        setState(() => _status = 'OK');
      } else {
        setState(() => _status = 'ERROR: Unexpected response (${response.statusCode})');
      }
    } catch (e) {
      setState(() => _status = 'ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Health'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchHealth,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
