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

  int currentUserId() => _userId();

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

  Future<void> activateBoost() async {
    await dio.post('/api/demo/boost/activate/${_userId()}');
  }

  Future<Map<String, dynamic>> chat(String message) async {
    final response = await dio.post(
      '/api/chat',
      data: {'userId': _userId(), 'message': message},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> conversations() async {
    final response = await dio.get('/api/chat/conversations/${_userId()}');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> chatThread({
    required int otherUserId,
  }) async {
    final response = await dio.get(
      '/api/chat/thread',
      queryParameters: {'userId': _userId(), 'otherUserId': otherUserId},
    );
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> sendDirectMessage({
    required int toUserId,
    required String body,
  }) async {
    await dio.post(
      '/api/chat/send',
      data: {'fromUserId': _userId(), 'toUserId': toUserId, 'body': body},
    );
  }

  Future<List<Map<String, dynamic>>> requests() async {
    final response = await dio.get('/api/requests/${_userId()}');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<String>> requestWants() async {
    final response = await dio.get('/api/requests/${_userId()}/wants');
    return (response.data as List).map((e) => e.toString()).toList();
  }

  Future<void> addRequestWant(String want) async {
    await dio.post('/api/requests/${_userId()}/wants', data: want);
  }

  Future<void> deleteRequestWant(String want) async {
    await dio.delete(
      '/api/requests/${_userId()}/wants',
      queryParameters: {'want': want},
    );
  }

  Future<List<Map<String, dynamic>>> requestsAll() async {
    final response = await dio.get('/api/requests');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> createRequest(String text) async {
    await dio.post('/api/requests', data: {'userId': _userId(), 'text': text});
  }

  Future<void> sendSwapFeedback({
    required int requestId,
    required bool success,
  }) async {
    await dio.post(
      '/api/requests/$requestId/feedback',
      data: {'success': success},
    );
  }

  Future<void> updateSwapStatus({
    required int requestId,
    required String status,
  }) async {
    await dio.put(
      '/api/requests/$requestId/status',
      data: {'status': status},
    );
  }

  Future<List<Map<String, dynamic>>> swapMatches() async {
    final response = await dio.get('/api/swaps/matches/${_userId()}');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> acceptSwapMatch(int matchId) async {
    await dio.post(
      '/api/swaps/matches/$matchId/accept',
      data: {'userId': _userId()},
    );
  }

  Future<void> doneSwapMatch(int matchId) async {
    await dio.post(
      '/api/swaps/matches/$matchId/done',
      data: {'userId': _userId()},
    );
  }

  Future<void> reviewSwapMatch({
    required int matchId,
    required int rating,
    required String comment,
  }) async {
    await dio.post(
      '/api/swaps/matches/$matchId/review',
      data: {'fromUserId': _userId(), 'rating': rating, 'comment': comment},
    );
  }

  Future<List<Map<String, dynamic>>> swapReviewsForMatch(int matchId) async {
    final response = await dio.get('/api/swaps/matches/$matchId/reviews');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> swapReviewsForUser(int userId) async {
    final response = await dio.get('/api/swaps/reviews/$userId');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> creditBalance() async {
    final response = await dio.get('/api/credits/${_userId()}/balance');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> creditTransactions() async {
    final response = await dio.get('/api/credits/${_userId()}/transactions');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> purchaseCredits(int credits) async {
    final response = await dio.post(
      '/api/credits/purchase',
      data: {'userId': _userId(), 'credits': credits},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> skills() async {
    final response = await dio.get('/api/skills/${_userId()}');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateSkills(
    List<Map<String, String>> offers,
    List<Map<String, String>> wants,
  ) async {
    final response = await dio.put(
      '/api/skills/${_userId()}',
      data: {'offers': offers, 'wants': wants},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, String>> addOfferSkill({
    required String name,
    required String description,
  }) async {
    final response = await dio.post(
      '/api/skills/${_userId()}/offer',
      data: {'name': name, 'description': description},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return {
      'name': (data['name'] ?? '').toString(),
      'description': (data['description'] ?? '').toString(),
      'id': (data['id'] as num?)?.toString() ?? '',
    };
  }

  Future<Map<String, String>> updateOfferSkill({
    required int skillId,
    required String name,
    required String description,
  }) async {
    final response = await dio.put(
      '/api/skills/${_userId()}/offer/$skillId',
      data: {'name': name, 'description': description},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return {
      'name': (data['name'] ?? '').toString(),
      'description': (data['description'] ?? '').toString(),
      'id': (data['id'] as num?)?.toString() ?? '',
    };
  }

  Future<void> deleteOfferSkill(int skillId) async {
    await dio.delete('/api/skills/${_userId()}/offer/$skillId');
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

  Future<Map<String, dynamic>> profileById(int userId) async {
    final response = await dio.get('/api/profile/$userId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> updateProfile({
    required String name,
    required String title,
    required String location,
    required String bio,
    required String photoUrl,
  }) async {
    await dio.put(
      '/api/profile/${_userId()}',
      data: {
        'name': name,
        'title': title,
        'location': location,
        'bio': bio,
        'photoUrl': photoUrl,
      },
    );
  }

  Future<List<Map<String, dynamic>>> listings() async {
    final response = await dio.get('/api/listings');
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> listingDetail(int listingId) async {
    final response = await dio.get('/api/listings/$listingId');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createListing({
    required String profession,
    required String title,
    required String description,
    required String phone,
    required String location,
    required String imageUrl,
  }) async {
    final response = await dio.post(
      '/api/listings',
      data: {
        'ownerUserId': _userId(),
        'profession': profession,
        'title': title,
        'description': description,
        'phone': phone,
        'location': location,
        'imageUrl': imageUrl,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateListing({
    required int listingId,
    required String profession,
    required String title,
    required String description,
    required String phone,
    required String location,
    required String imageUrl,
  }) async {
    final response = await dio.put(
      '/api/listings/$listingId',
      data: {
        'ownerUserId': _userId(),
        'profession': profession,
        'title': title,
        'description': description,
        'phone': phone,
        'location': location,
        'imageUrl': imageUrl,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> deleteListing(int listingId) async {
    await dio.delete(
      '/api/listings/$listingId',
      queryParameters: {'ownerUserId': _userId()},
    );
  }

  Future<String> uploadListingImage(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await dio.post('/api/uploads', data: form);
    final data = Map<String, dynamic>.from(response.data as Map);
    return data['url']?.toString() ?? '';
  }

  String resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${dio.options.baseUrl}$url';
  }
}
