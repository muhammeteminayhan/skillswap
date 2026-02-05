import 'package:flutter/material.dart';

import '../core/models/auth_session.dart';
import '../core/network/api_client.dart';
import '../features/auth/auth_page.dart';
import '../features/main/main_shell.dart';

class SkillSwapApp extends StatefulWidget {
  const SkillSwapApp({super.key});

  @override
  State<SkillSwapApp> createState() => _SkillSwapAppState();
}

class _SkillSwapAppState extends State<SkillSwapApp> {
  final ApiClient _api = ApiClient();
  AuthSession? _session;

  void _onAuthSuccess(AuthSession session) {
    setState(() {
      _session = session;
      _api.setSession(session);
    });
  }

  void _onLogout() {
    setState(() {
      _session = null;
      _api.clearSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillSwap',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF032B35),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF24C58E),
          secondary: Color(0xFF4B7BFF),
          surface: Color(0xFF063B46),
        ),
        useMaterial3: true,
      ),
      home: _session == null
          ? AuthPage(api: _api, onAuthSuccess: _onAuthSuccess)
          : MainShell(api: _api, session: _session!, onLogout: _onLogout),
    );
  }
}
