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
        // AppBar yerine kutu başlık (kullanıcı tercihi 2026-07-19) + kutu
        // sekme çubuğu gövdenin üstünde.
        body: SafeArea(
          child: Column(
            children: [
              BoxedPageHeader(
                title: s.groupsTitle,
                actionTooltip: s.createGroupTitle,
                onAction:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateGroupScreen(),
                      ),
                    ),
              ),
              BoxedTabBar(
                labels: [
                  if (hasHierarchy) s.tabOrganizedGroups,
                  s.tabMyGroups,
                  s.tabJoinable,
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    if (hasHierarchy) const GroupTreeScreen(),
                    const _MyGroupsTab(),
                    const _JoinableTab(),
                  ],
                ),
              ),
            ],
          ),
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
    // Yalnız ÖZEL gruplarım (kullanıcı hükmü 2026-07-19): kurumsal üyeliklerim
    // artık Kurumsal Gruplar ağacında "Üye" rozetiyle görünür, burada değil.
    final groups = state.myGroups.where((g) => !g.isOrganized).toList();

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

  // "Kutu kutu" pilotu (kullanıcı tercihi 2026-07-19): AVATAR kaldırıldı
  // (gerekli değil), sağdaki Kurumsal/Özel tür rozeti kaldırıldı; ortadaki
  // ad+açıklama bir KUTUYA alındı, üye sayısı sağda sade bir RAKAM-KUTUSU.
  Widget _groupTile(BuildContext context, Group g) {
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
            // Kalp YALNIZ favoride görünür (kırmızı çizgili); favori değilse
            // boş kalır (Kişiler'deki desenle aynı — kullanıcı hükmü). Dokunma
            // alanı yine durur (favoriden çıkarmak için).
            IconButton(
              visualDensity: VisualDensity.compact,
              icon:
                  fav
                      ? const Icon(Icons.favorite_border, color: Colors.red)
                      : const SizedBox.shrink(),
              onPressed:
                  () => AppScope.of(
                    context,
                    listen: false,
                  ).toggleFavoriteGroup(g.id),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: InfoBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    // Açıklama OPSİYONEL (kullanıcı hükmü): admin girmişse
                    // gösterilir, boşsa satır hiç çizilmez (kutu kısalır).
                    if (g.description.trim().isNotEmpty)
                      Text(
                        g.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Hiyerarşi düğümünde alt ağacın toplamı (FR-71).
            CountBox(count: state.groupMemberCount(g)),
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
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, i) {
        final g = groups[i];
        final admin =
            g.managerId != null ? state.td.member(g.managerId!) : null;
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
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                // Avatar kaldırıldı (kullanıcı tercihi); ad+açıklama kutuda.
                Expanded(
                  child: InfoBox(
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
                        // Alt yazı opsiyonel: yönetici varsa adı, yoksa açıklama
                        // (boşsa satır çizilmez).
                        if (admin != null || g.description.trim().isNotEmpty)
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
