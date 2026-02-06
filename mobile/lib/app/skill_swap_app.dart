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
      title: 'İMECE',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6FBF8),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1B9C6B),
          onPrimary: Color(0xFFF7FFFB),
          secondary: Color(0xFF7BD8B0),
          onSecondary: Color(0xFF0B3B2A),
          tertiary: Color(0xFF1D6A56),
          onTertiary: Color(0xFFF7FFFB),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF1C1F1E),
          outline: Color(0xFFDDEAE3),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6FBF8),
          foregroundColor: Color(0xFF1C1F1E),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 1,
          shadowColor: const Color(0x1A1B9C6B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFFFFFFF),
          indicatorColor: Color(0xFF1B9C6B),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF1C1F1E)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF1F7F4),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFDDEAE3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1B9C6B), width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1B9C6B),
            foregroundColor: const Color(0xFFF7FFFB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1B9C6B),
            side: const BorderSide(color: Color(0xFF1B9C6B)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF1C1F1E)),
          bodySmall: TextStyle(color: Color(0xFF3A3F3E)),
          titleMedium: TextStyle(color: Color(0xFF1C1F1E)),
          titleLarge: TextStyle(color: Color(0xFF1C1F1E)),
          headlineMedium: TextStyle(
            color: Color(0xFF1C1F1E),
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: TextStyle(
            color: Color(0xFF1C1F1E),
            fontWeight: FontWeight.w700,
          ),
        ),
        useMaterial3: true,
      ),
      home: _session == null
          ? AuthPage(api: _api, onAuthSuccess: _onAuthSuccess)
          : MainShell(api: _api, session: _session!, onLogout: _onLogout),
    );
  }
}
