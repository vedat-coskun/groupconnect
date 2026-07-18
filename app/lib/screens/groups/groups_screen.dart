import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';
import 'group_detail_screen.dart';
import 'group_tree_screen.dart';

/// Groups home with tabs: **Kurumsal** (org hiyerarşisi — yalnız hiyerarşisi
/// olan kurumlarda), **Üye Olduklarım** ve **Katılabileceklerim** (FR-42,
/// rev.4). Üç sekme de her zaman aynı görsel ağırlıkta; "Katılabileceklerim"de
/// katılacak bir şey yoksa boş durum gösterilir (sekme yerinde kalır, hep
/// erişilebilir).
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final hasHierarchy = state.hasGroupHierarchy;
    return DefaultTabController(
      length: hasHierarchy ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.groupsTitle),
          actions: [
            // Özel Grup Yarat: sağ üstte "+" (Kişiler'deki "+" ile uyumlu).
            IconButton(
              tooltip: s.createGroupTitle,
              icon: const Icon(Icons.add),
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateGroupScreen(),
                    ),
                  ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              if (hasHierarchy) Tab(text: s.organized),
              Tab(text: s.tabMyGroups),
              Tab(text: s.tabJoinable),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (hasHierarchy) const GroupTreeScreen(),
            const _MyGroupsTab(),
            const _JoinableTab(),
          ],
        ),
      ),
    );
  }
}

class _MyGroupsTab extends StatelessWidget {
  const _MyGroupsTab();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final groups = state.myGroups;

    if (groups.isEmpty) {
      return EmptyState(icon: Icons.groups_outlined, title: s.myGroupsEmpty);
    }

    final favs = groups.where((g) => state.isFavoriteGroup(g.id)).toList();
    final others = groups.where((g) => !state.isFavoriteGroup(g.id)).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        if (favs.isNotEmpty) ...[
          _SectionHeader(s.favoritesTitle),
          for (final g in favs) _groupTile(context, g),
        ],
        if (favs.isNotEmpty && others.isNotEmpty) _SectionHeader(s.groupsTitle),
        for (final g in others) _groupTile(context, g),
      ],
    );
  }

  // Özel Row (ListTile değil): dar ekranda leading(kalp+avatar) + trailing
  // (etiket+sayı) ListTile'ı taşırıyordu; Expanded başlık bunu güvene alır.
  Widget _groupTile(BuildContext context, Group g) {
    final s = context.s;
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fav = state.isFavoriteGroup(g.id);
    return InkWell(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: g.id)),
          ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                fav ? Icons.favorite : Icons.favorite_border,
                color: fav ? Colors.red : null,
              ),
              onPressed:
                  () => AppScope.of(
                    context,
                    listen: false,
                  ).toggleFavoriteGroup(g.id),
            ),
            GroupAvatar(group: g, radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    g.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TagChip(
                  label: g.isOrganized ? s.organized : s.privateGroup,
                  icon:
                      g.isOrganized
                          ? Icons.verified_outlined
                          : Icons.lock_open,
                ),
                const SizedBox(height: 4),
                Text(
                  // Hiyerarşi düğümünde alt ağacın toplamı (FR-71).
                  s.memberCount(state.groupMemberCount(g)),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "FAVORİLER" / "GRUPLAR" section label.
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

class _JoinableTab extends StatelessWidget {
  const _JoinableTab();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final groups = state.joinableGroups;

    if (groups.isEmpty) {
      return EmptyState(
        icon: Icons.group_add_outlined,
        title: s.joinableEmpty,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final g = groups[i];
        final admin =
            g.adminId != null ? state.td.member(g.adminId!) : null;
        final scheme = Theme.of(context).colorScheme;
        // Özel Row (ListTile değil): "Katıl" butonu + uzun alt-yazı dar ekranda
        // ListTile'ı taşırıyordu; Expanded başlık bunu güvene alır.
        return InkWell(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(groupId: g.id),
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                GroupAvatar(group: g, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // FR-82: bu gruba nasıl dahil olacağım — davet mi,
                          // açık mı? Davet, açıklığı ezer.
                          _JoinBadge(
                            invited: state.isInvitedToGroup(g.id),
                          ),
                        ],
                      ),
                      Text(
                        admin == null
                            ? g.description
                            : '${s.adminShort}: ${admin.fullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _join(context, g, s),
                  // Tema tüm FilledButton'lara minimumSize: Size.fromHeight(52)
                  // veriyor — yani minGenişlik = sonsuz (tam genişlik butonlar
                  // için). Row içinde genişlik sınırsız ölçüldüğünden bu sonsuzu
                  // ZORLAR ve satır çizilemez (sekme bomboş kalır). Burada
                  // içeriğe göre daralt — gönder butonundaki (chat_widgets) ile
                  // aynı çözüm.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 40),
                  ),
                  child: Text(s.join),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Onay diyaloğu yok: "Katıl" doğrudan katar. Katılmak düşük riskli ve geri
  // alınabilir bir eylem — özel gruptan dilediğin an ayrılabilirsin (FR-39) —
  // dolayısıyla araya onay koymanın bedeli faydasından fazla. Grubu önce
  // incelemek isteyen satıra dokunup Grup Bilgisi'ne girer.
  void _join(BuildContext context, Group g, AppStrings s) {
    AppScope.of(context, listen: false).joinGroup(g.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.joinedGroup)),
    );
  }
}

/// FR-82: "Katılabileceklerim" satırında bu gruba **nasıl** dahil olunacağını
/// gösterir — davet mi geldi, yoksa grup "açık" mı? Davet açıklığı ezer.
class _JoinBadge extends StatelessWidget {
  const _JoinBadge({required this.invited});

  final bool invited;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final color = invited ? scheme.primary : scheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        invited ? s.joinViaInvite : s.joinViaOpen,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
