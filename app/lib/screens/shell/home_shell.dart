import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../chats/chats_screen.dart';
import '../contacts/contacts_screen.dart';
import '../groups/groups_screen.dart';
import '../menu/menu_screen.dart';

/// Main app shell with bottom navigation:
/// Gruplar · Kişiler · Sohbetler · Menü.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    GroupsScreen(),
    ContactsScreen(),
    ChatsScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: s.tabGroups,
          ),
          NavigationDestination(
            icon: const Icon(Icons.contacts_outlined),
            selectedIcon: const Icon(Icons.contacts),
            label: s.tabContacts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: s.tabChats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu),
            selectedIcon: const Icon(Icons.menu),
            label: s.tabMenu,
          ),
        ],
      ),
    );
  }
}
