import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/models/auth_session.dart';
import '../../core/network/api_client.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.api, required this.onAuthSuccess});

  final ApiClient api;
  final ValueChanged<AuthSession> onAuthSuccess;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool registerMode = false;
  bool loading = false;
  String error = '';

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final titleController = TextEditingController();
  final locationController = TextEditingController();

  Future<void> _submit() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      AuthSession session;
      if (registerMode) {
        session = await widget.api.register(
          name: nameController.text.trim(),
          email: email,
          password: password,
          title: titleController.text.trim(),
          location: locationController.text.trim(),
        );
      } else {
        session = await widget.api.login(email, password);
      }
      widget.onAuthSuccess(session);
    } on DioException catch (e) {
      final payload = e.response?.data;
      if (payload is Map && payload['message'] != null) {
        setState(() => error = payload['message'].toString());
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        setState(
          () => error =
              'Baglanti kurulamadi. Backend icin URL/port kontrol edin.',
        );
      } else {
        final status = e.response?.statusCode;
        setState(
          () => error =
              'Istek basarisiz oldu${status == null ? '' : ' (HTTP $status)'}',
        );
      }
    } catch (_) {
      setState(() => error = 'Beklenmeyen bir hata olustu.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6FBF8), Color(0xFFE8F6EF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (registerMode)
                    const Text(
                      'Yeteneklerini paylas, takasa basla.',
                      style: TextStyle(color: Color(0xFF4A5852)),
                    ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (registerMode) ...[
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Ad Soyad',
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-posta',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Sifre',
                            ),
                          ),
                          if (registerMode) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: titleController,
                              decoration: const InputDecoration(
                                labelText: 'Unvan (opsiyonel)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                labelText: 'Konum (opsiyonel)',
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: loading ? null : _submit,
                              child: Text(
                                loading
                                    ? 'Yukleniyor...'
                                    : registerMode
                                    ? 'Kayit Ol'
                                    : 'Giris Yap',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => setState(() {
                                    registerMode = !registerMode;
                                    error = '';
                                  }),
                            child: Text(
                              registerMode
                                  ? 'Zaten hesabin var mi? Giris yap'
                                  : 'Hesabin yok mu? Kayit ol',
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Giris yaparak KVKK ve Aydinlatma Metni kosullarini kabul etmis olursunuz.',
                            style: TextStyle(
                              color: Color(0xFF6B7A72),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (error.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              error,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
