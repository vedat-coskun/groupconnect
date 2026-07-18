import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../contacts/directory_search_screen.dart';
import '../groups/group_chat_screen.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

/// Chat-list filters: 1:1 / organized / private. **Çoklu seçim** — her çip
/// bağımsız açılıp kapanır, üçü birden seçili olmak eski "Tümü" ile aynı şey
/// olduğu için ayrı bir "Tümü" çipi yok. Liste her zaman bölüm başlıklı.
enum _ChatFilter { personal, organized, private }

/// Unified conversation list: group chats + surfaced 1:1 threads (FR-29).
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  // Varsayılan: üçü de seçili (eski "Tümü" davranışı).
  final Set<_ChatFilter> _filters = {..._ChatFilter.values};

  void _toggle(_ChatFilter f) => setState(() {
    if (!_filters.remove(f)) _filters.add(f);
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final all = state.chatSummaries;
    final children = _groupedChildren(all, s);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.chatsTitle),
        // Yeni Sohbet: sağ üstte "+" (Gruplar/Kişiler ile uyumlu).
        actions: [
          IconButton(
            tooltip: s.newChatTitle,
            icon: const Icon(Icons.add),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewChatScreen()),
                ),
          ),
        ],
      ),
      body:
          all.isEmpty
              // Hiç sohbet yok → tam boş durum + kişi ekle.
              ? EmptyState(
                icon: Icons.forum_outlined,
                title: s.chatsEmpty,
                subtitle: s.chatsEmptyHint,
                action: FilledButton.icon(
                  onPressed: () => _openDirectory(context),
                  icon: const Icon(Icons.person_add_alt),
                  label: Text(s.addContact),
                ),
              )
              : Column(
                children: [
                  _FilterBar(filters: _filters, onToggle: _toggle),
                  Expanded(
                    // Hiçbir çip seçili değilse de burası boşalır — çipe
                    // dokunmak tek çıkış, dolayısıyla çıkmaz sokak değil.
                    child:
                        children.isEmpty
                            ? EmptyState(
                              icon: Icons.filter_list_off_outlined,
                              title: s.chatsFilterEmpty,
                            )
                            : ListView(children: children),
                  ),
                ],
              ),
    );
  }

  /// Seçili çiplerin bölümlerini, her birinin başında adıyla (KİŞİSEL /
  /// KURUMSAL / ÖZEL) listeler. Seçili olmayan çipin bölümü hiç çizilmez;
  /// seçili ama içi boş olan bölüm de atlanır (başlık tek başına kalmaz).
  List<Widget> _groupedChildren(List<ChatSummary> all, AppStrings s) {
    final children = <Widget>[];
    void section(
      _ChatFilter f,
      String title,
      bool Function(ChatSummary) test,
    ) {
      if (!_filters.contains(f)) return;
      final items = all.where(test).toList();
      if (items.isEmpty) return;
      children.add(_SectionHeader(title));
      for (var i = 0; i < items.length; i++) {
        children.add(_ChatTile(summary: items[i]));
        if (i < items.length - 1) {
          children.add(const Divider(height: 1, indent: 72));
        }
      }
    }

    section(_ChatFilter.personal, s.chatsFilterPersonal, (c) => !c.isGroup);
    section(
      _ChatFilter.organized,
      s.organized,
      (c) => c.isGroup && (c.group?.isOrganized ?? false),
    );
    section(
      _ChatFilter.private,
      s.privateGroup,
      (c) => c.isGroup && !(c.group?.isOrganized ?? true),
    );
    return children;
  }

  void _openDirectory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DirectorySearchScreen()),
    );
  }
}

/// Section label ("KİŞİSEL" / "KURUMSAL" / "ÖZEL") — her bölümün başında.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        context.upper(title),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Horizontal filter chips above the chat list — **bağımsız işaretlenir**
/// (ChoiceChip değil FilterChip: tekli seçim değil çoklu).
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filters, required this.onToggle});

  final Set<_ChatFilter> filters;
  final ValueChanged<_ChatFilter> onToggle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Widget chip(_ChatFilter f, String label) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: filters.contains(f),
        onSelected: (_) => onToggle(f),
      ),
    );

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          chip(_ChatFilter.personal, s.chatsFilterPersonal),
          chip(_ChatFilter.organized, s.organized),
          chip(_ChatFilter.private, s.privateGroup),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.summary});

  final ChatSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading:
          summary.isGroup
              ? GroupAvatar(group: summary.group!, radius: 26)
              : MemberAvatar(member: summary.member!, radius: 26),
      title: Text(
        summary.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        summary.subtitle.isEmpty ? '—' : summary.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatTime(summary.time),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (summary.muted) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.notifications_off_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ],
      ),
      onTap: () {
        if (summary.isGroup) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupChatScreen(groupId: summary.group!.id),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(memberId: summary.member!.id),
            ),
          );
        }
      },
    );
  }
}
