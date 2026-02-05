import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';

class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl(),
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
          headers: const {'Content-Type': 'application/json'},
        ),
      );

  final Dio dio;
  AuthSession? _session;

  void setSession(AuthSession session) {
    _session = session;
  }

  void clearSession() {
    _session = null;
  }

  int _userId() => _session?.userId ?? 1;

  static String _baseUrl() {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envBaseUrl.isNotEmpty) return envBaseUrl;
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  Future<AuthSession> login(String email, String password) async {
    final response = await dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return AuthSession(
      userId: (data['userId'] as num).toInt(),
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      token: data['token']?.toString() ?? '',
    );
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? title,
    String? location,
  }) async {
    final response = await dio.post(
      '/api/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'title': title ?? '',
        'location': location ?? '',
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return AuthSession(
      userId: (data['userId'] as num).toInt(),
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      token: data['token']?.toString() ?? '',
    );
  }

  Future<Map<String, dynamic>> dashboard() async {
    final response = await dio.get('/api/demo/dashboard/${_userId()}');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> chains() async {
    final response = await dio.get('/api/demo/chains/${_userId()}');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> quantum(bool realMatching) async {
    final response = await dio.get(
      '/api/demo/quantum/${_userId()}',
      queryParameters: {'realMatching': realMatching},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> talents() async {
    final response = await dio.get('/api/demo/talents/${_userId()}');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> semanticSearch(
    String query,
    int radiusKm,
  ) async {
    final response = await dio.get(
      '/api/demo/search/${_userId()}',
      queryParameters: {'query': query, 'radiusKm': radiusKm},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> boostPlans() async {
    final response = await dio.get('/api/demo/boost');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> chat(String message) async {
    final response = await dio.post(
      '/api/chat',
      data: {'userId': _userId(), 'message': message},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> requests() async {
    final response = await dio.get('/api/requests/${_userId()}');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> createRequest(String text) async {
    await dio.post('/api/requests', data: {'userId': _userId(), 'text': text});
  }

  Future<Map<String, dynamic>> skills() async {
    final response = await dio.get('/api/skills/${_userId()}');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> updateSkills(
    List<Map<String, String>> offers,
    List<Map<String, String>> wants,
  ) async {
    await dio.put(
      '/api/skills/${_userId()}',
      data: {'offers': offers, 'wants': wants},
    );
  }

  Future<List<Map<String, dynamic>>> messages() async {
    final response = await dio.get('/api/messages/${_userId()}');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> profile() async {
    final response = await dio.get('/api/profile/${_userId()}');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
