import 'package:flutter/material.dart';

import '../../core/models/auth_session.dart';
import '../../core/network/api_client.dart';
import '../home/home_page.dart';
import '../listings/listings_page.dart';
import '../messages/messages_page.dart';
import '../skills/skills_page.dart';
import '../swaps/swaps_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final ApiClient api;
  final AuthSession session;
  final VoidCallback onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        api: widget.api,
        session: widget.session,
        onLogout: widget.onLogout,
      ),
      SkillsPage(api: widget.api),
      ListingsPage(api: widget.api),
      SwapsPage(api: widget.api),
      MessagesPage(api: widget.api),
    ];

    return Scaffold(
      body: SafeArea(child: pages[currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDDEAE3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1B9C6B),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: const Color(0xFFE6ECE9),
            labelTextStyle: MaterialStateProperty.resolveWith(
              (states) => TextStyle(
                fontWeight:
                    states.contains(MaterialState.selected) ? FontWeight.w700 : FontWeight.w500,
                color: states.contains(MaterialState.selected)
                    ? const Color(0xFF2C3E37)
                    : const Color(0xFF6B7A72),
              ),
            ),
            iconTheme: MaterialStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(MaterialState.selected)
                    ? const Color(0xFF2C3E37)
                    : const Color(0xFF6B7A72),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                setState(() => currentIndex = index),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_rounded),
                label: 'Ana Sayfa',
              ),
              const NavigationDestination(
                icon: Icon(Icons.flash_on_rounded),
                label: 'Yetenekler',
              ),
              NavigationDestination(icon: _centerIcon(), label: 'İlanlar'),
              const NavigationDestination(
                icon: Icon(Icons.swap_horiz_rounded),
                label: 'Takaslar',
              ),
              const NavigationDestination(
                icon: Icon(Icons.chat_bubble_rounded),
                label: 'Mesajlar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF24C58E),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_search_rounded, color: Color(0xFF05352F)),
    );
  }
}
