import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../chats/chats_screen.dart';
import '../contacts/contacts_screen.dart';
import '../groups/groups_screen.dart';
import '../menu/menu_screen.dart';

/// Main app shell with bottom navigation:
/// Sohbetler · Gruplar · Kişiler · Menü.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    ChatsScreen(),
    GroupsScreen(),
    ContactsScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      // "Kutu kutu" tasarım pilotu (kullanıcı tercihi): NavigationBar yerine
      // her sekme kendi yuvarlatılmış kutusunda (seçili = dolgulu kutu).
      bottomNavigationBar: _BoxedNavBar(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
        items: [
          (Icons.chat_bubble_outline, Icons.chat_bubble, s.tabChats),
          (Icons.groups_outlined, Icons.groups, s.tabGroups),
          (Icons.contacts_outlined, Icons.contacts, s.tabContacts),
          (Icons.menu, Icons.menu, s.tabMenu),
        ],
      ),
    );
  }
}

/// Kutu görünümlü alt menü: her öğe yuvarlatılmış bir kutu; seçili öğe
/// secondaryContainer dolgusuyla öne çıkar, diğerleri hafif yüzey kutusu.
class _BoxedNavBar extends StatelessWidget {
  const _BoxedNavBar({
    required this.index,
    required this.onSelect,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final List<(IconData, IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              for (final (i, item) in items.indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Material(
                      color:
                          i == index
                              ? scheme.secondaryContainer
                              : scheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                i == index ? item.$2 : item.$1,
                                size: 22,
                                color:
                                    i == index
                                        ? scheme.onSecondaryContainer
                                        : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(
                                  fontWeight:
                                      i == index
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                  color:
                                      i == index
                                          ? scheme.onSecondaryContainer
                                          : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
