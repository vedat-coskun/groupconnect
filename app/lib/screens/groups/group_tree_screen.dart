import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';
import '../contacts/contact_detail_screen.dart';
import '../contacts/directory_search_screen.dart';
import 'group_chat_screen.dart';

/// Hierarchical "Kurum Yapısı" browser (Adım 2). Navigates the group tree level
/// by level — e.g. Dekanlık → Bölüm → alt gruplar + kişiler — using the admin's
/// `levelLabels`. [groupId] null = top level (roots).
class GroupTreeScreen extends StatelessWidget {
  const GroupTreeScreen({super.key, this.groupId});

  final String? groupId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);

    // Top level: the roots (Dekanlık seviyesi).
    if (groupId == null) {
      final roots = state.treeRootGroups;
      return Scaffold(
        appBar: AppBar(title: Text(s.orgStructureTitle)),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _LevelHeader(state.levelLabel(0)),
            for (final g in roots) _groupRow(context, g),
          ],
        ),
      );
    }

    final g = state.td.group(groupId!);
    if (g == null) {
      return const Scaffold(body: Center(child: Text('—')));
    }
    final depth = state.groupDepth(g);
    final children = state.childGroupsOf(g.id);
    // Üyelik en alt seviyede; üst grubun kişileri = alt gruplarının toplamı.
    final members = state.aggregateMembersOf(g);
    final path = state.groupPath(g);

    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          // Toplu Ekle: bu gruptaki kişileri dizinde ön-filtreyle aç.
          IconButton(
            tooltip: s.addContact,
            icon: const Icon(Icons.person_add_alt),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DirectorySearchScreen(initialGroupId: g.id),
                  ),
                ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Breadcrumb: Fakülte › Bölüm › …
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              path.map((e) => e.name).join('  ›  '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: GroupAvatar(group: g, radius: 24),
            title: Text(
              g.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            // Seviye adı yerine toplam kişi (alt gruplar dahil).
            subtitle: Text('${members.length} kişi'),
            trailing: IconButton(
              tooltip: s.openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupChatScreen(groupId: g.id),
                    ),
                  ),
            ),
          ),
          const Divider(),

          if (children.isNotEmpty) ...[
            _LevelHeader('${state.levelLabel(depth + 1)} (${children.length})'),
            for (final c in children) _groupRow(context, c),
            const Divider(),
          ],

          // Üyeler kategoriye (rol) göre — admin'in tanımladığı rol sırasıyla.
          // Ortak kural: rol (kategori) başlıkları, admin sırasıyla.
          ...roleSections(
            context: context,
            members: members,
            roles: state.tenantRoles,
            roleName: state.roleName,
            row: (m) => _memberRow(context, m),
            header: (t) => _LevelHeader(t),
            otherLabel: s.membersTitle,
          ),
          if (members.isEmpty && children.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('—')),
            ),
        ],
      ),
    );
  }

  Widget _memberRow(BuildContext context, Member m) {
    return ListTile(
      leading: MemberAvatar(member: m),
      // İsim düzeni tek satır: "Ad SOYAD, Ünvan, Bölüm [rakam]".
      title: Text(
        m.rowLabel(context),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContactDetailScreen(memberId: m.id),
            ),
          ),
    );
  }

  /// A drill-in row for a child group (shows sub-count / member-count hint).
  Widget _groupRow(BuildContext context, Group g) {
    final state = AppScope.of(context);
    final childCount = state.childGroupsOf(g.id).length;
    // Toplam kişi (alt gruplar dahil) — üst grupta alt sayıların toplamına eşit.
    final people = state.aggregateMembersOf(g).length;
    return ListTile(
      leading: GroupAvatar(group: g, radius: 22),
      title: Text(
        g.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        childCount > 0
            ? '${state.levelLabel(state.groupDepth(g) + 1)}: $childCount · '
                '$people kişi'
            : '$people kişi',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GroupTreeScreen(groupId: g.id)),
          ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        context.upper(text),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
