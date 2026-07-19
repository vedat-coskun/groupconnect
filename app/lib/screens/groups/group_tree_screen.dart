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
class GroupTreeScreen extends StatefulWidget {
  const GroupTreeScreen({super.key, this.groupId});

  final String? groupId;

  @override
  State<GroupTreeScreen> createState() => _GroupTreeScreenState();
}

class _GroupTreeScreenState extends State<GroupTreeScreen> {
  // Tek seferde en fazla bir çocuk grup satırı açık kalır (accordion).
  String? _expandedChildId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    // Alt seviye (bir üst gruptan push edilmiş): kendi Scaffold'lu sayfa.
    if (widget.groupId != null) {
      final g = state.td.group(widget.groupId!);
      if (g == null) return const Scaffold(body: Center(child: Text('—')));
      return _nodeContent(context, g, embedded: false);
    }

    // Kök = "Kurumsal" sekmesinin içeriği (FR-42 rev.4). Kendi Scaffold'u yok.
    final roots = state.treeRootGroups;
    // **Tek kök varsa kök-seçim ekranını ATLA** (kullanıcı hükmü): DEKANLIK'ta
    // tek öğe (ör. Mühendislik Fakültesi) varken ona tıklamak zorunda kalmadan
    // doğrudan içeriği (Bölümler + kişiler) açılır. Çoklu kökte liste kalır.
    if (roots.length == 1) {
      return _nodeContent(context, roots.first, embedded: true);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _LevelHeader(state.levelLabel(0)),
        for (final g in roots) _groupRow(context, g, expandable: false),
      ],
    );
  }

  /// Bir grup düğümünün içeriği: başlık kartı + alt gruplar (accordion) +
  /// toplam kişiler (FR-71). [embedded] true ise Scaffold/AppBar/breadcrumb
  /// yoktur — "Kurumsal" sekmesine gömülü tek-kök gösterimi için. false ise
  /// push edilmiş alt sayfa olarak kendi AppBar'ını taşır.
  Widget _nodeContent(BuildContext context, Group g, {required bool embedded}) {
    final s = context.s;
    final state = AppScope.of(context);
    final depth = state.groupDepth(g);
    final children = state.childGroupsOf(g.id);
    // Üyelik en alt seviyede; üst grubun kişileri = alt gruplarının toplamı.
    final members = state.aggregateMembersOf(g);
    final path = state.groupPath(g);

    final body = ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Breadcrumb yalnız alt sayfalarda (kök tek olduğunda anlamsız).
        if (!embedded)
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
          // İkon = "buraya yazabilirim" (kullanıcı hükmü — "mesaj gönderemem").
          // Üyelik değil, YAZAR olmak gerekir (FR-90); okuma yine de üyeye
          // Sohbetler'den açıktır (GroupChatScreen zaten salt-okur şerit
          // gösterir) — bu ikon Kurum Yapısı'ndaki hızlı-yazma kısayoludur.
          trailing:
              state.canSeeGroupChat(g)
                  ? IconButton(
                    tooltip: s.openChat,
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GroupChatScreen(groupId: g.id),
                          ),
                        ),
                  )
                  : null,
        ),
        const Divider(),

        if (children.isNotEmpty) ...[
          _LevelHeader('${state.levelLabel(depth + 1)} (${children.length})'),
          for (final c in children) ...[
            _groupRow(context, c, expandable: true),
            if (_expandedChildId == c.id) _expandedChildContent(context, c),
          ],
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
    );

    if (embedded) return body;
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
      body: body,
    );
  }

  Widget _memberRow(BuildContext context, Member m) {
    return ListTile(
      leading: MemberAvatar(member: m),
      // İsim düzeni tek satır: "Ad SOYAD, Ünvan, Bölüm [rakam]".
      title: Text.rich(
        m.rowLabelSpan(context),
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

  /// A drill-in row for a child group. Root-level rows (expandable: false)
  /// push a new screen; rows nested inside a node's own children list
  /// expand in place instead (single-open accordion) so the parent's own
  /// toplam kişi listesi (FR-71) never leaves view.
  Widget _groupRow(BuildContext context, Group g, {required bool expandable}) {
    final state = AppScope.of(context);
    final childCount = state.childGroupsOf(g.id).length;
    // Toplam kişi (alt gruplar dahil) — üst grupta alt sayıların toplamına eşit.
    final people = state.aggregateMembersOf(g).length;
    final isExpanded = expandable && _expandedChildId == g.id;
    return ListTile(
      leading: GroupAvatar(group: g, radius: 22),
      title: Text(
        g.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        childCount > 0
            ? '$childCount ${state.levelLabel(state.groupDepth(g) + 1)} · '
                '$people kişi'
            : '$people kişi',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // İkon = "buraya yazabilirim" (kullanıcı hükmü). Üyelik değil,
          // YAZAR olmak gerekir (FR-90) — okuma üyeye Sohbetler'den açıktır.
          if (state.canSeeGroupChat(g))
            IconButton(
              tooltip: context.s.openChat,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupChatScreen(groupId: g.id),
                    ),
                  ),
            ),
          Icon(
            !expandable
                ? Icons.chevron_right
                : (isExpanded ? Icons.expand_less : Icons.expand_more),
          ),
        ],
      ),
      onTap: () {
        if (!expandable) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GroupTreeScreen(groupId: g.id)),
          );
          return;
        }
        setState(() => _expandedChildId = isExpanded ? null : g.id);
      },
    );
  }

  /// Tıklanan çocuk grubun üye listesi — aynı sayfada, girinti ile (accordion).
  Widget _expandedChildContent(BuildContext context, Group g) {
    final state = AppScope.of(context);
    final members = state.aggregateMembersOf(g);
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: roleSections(
          context: context,
          members: members,
          roles: state.tenantRoles,
          roleName: state.roleName,
          row: (m) => _memberRow(context, m),
          header: (t) => _LevelHeader(t),
          otherLabel: context.s.membersTitle,
        ),
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
