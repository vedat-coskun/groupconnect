import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../contacts/contact_detail_screen.dart';
import 'group_chat_screen.dart';

/// "Kurumsal" (Kurum Yapısı) — TEK ekranda çok-seviyeli YERİNDE AKORDİYON
/// (kullanıcı tercihi 2026-07-19): ayrı alt-sayfa yok. Kökler (ör. Fakülteler)
/// üstte; bir düğümü açınca alt grupları görünür (üyeleri DEĞİL); yaprak düğümü
/// (ör. Bölüm) açınca üyeleri rol başlıklarıyla görünür. Açık/kapalı durumu
/// AppState'te tutulur — sekme/gezinme sıfırlamaz, yalnız logout temizler.
///
/// Not: eski "DEKANLIK" seviye başlığı ve düğüm-başına "Toplu Ekle" alt-sayfası
/// kaldırıldı (birleşik akordiyon isteği).
class GroupTreeScreen extends StatelessWidget {
  const GroupTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final roots = state.treeRootGroups;
    return ListView(
      padding: const EdgeInsets.only(top: 6, bottom: 88),
      children: [
        for (final g in roots) ..._node(context, state, g, depth: 0),
      ],
    );
  }

  /// Bir düğüm satırı + (açıksa) altı. İç düğüm → alt gruplar (özyineli);
  /// yaprak → üyeler (rol başlıklarıyla).
  List<Widget> _node(
    BuildContext context,
    AppState state,
    Group g, {
    required int depth,
  }) {
    final children = state.childGroupsOf(g.id);
    final expanded = state.isTreeGroupExpanded(g.id);

    final out = <Widget>[
      _GroupRow(group: g, depth: depth, expanded: expanded),
    ];
    if (!expanded) return out;

    // Alt gruplar (varsa) — özyineli. Yaprakta bu boş geçer.
    for (final c in children) {
      out.addAll(_node(context, state, c, depth: depth + 1));
    }

    // HER düğümde (Fakülte dahil) o düğümün TOPLAM üyelerini (FR-71) rol
    // başlıklarıyla göster — böylece bir fakültenin akademisyen/öğrencileri de
    // burada listelenir (kullanıcı hükmü). Rol başlıkları AKORDİYON (varsayılan
    // kapalı, logout'a kadar kalıcı), İNCE KUTU içinde — Kişiler → Herkes deseni.
    final members = state.aggregateMembersOf(g);
    out.addAll(
      roleSections(
        context: context,
        members: members,
        roles: state.tenantRoles,
        roleName: state.roleName,
        row: (m) => _MemberRow(member: m, indent: (depth + 2) * 20.0),
        header:
            (label) => BoxedRoleHeader(
              label,
              indent: (depth + 1) * 20.0,
              collapsed: !state.isTreeRoleExpanded(g.id, label),
              onToggle: () => state.toggleTreeRole(g.id, label),
            ),
        collapsed: (label) => !state.isTreeRoleExpanded(g.id, label),
        otherLabel: context.s.membersTitle,
      ),
    );
    return out;
  }
}

/// Akordiyon grup satırı (kutulu): avatar + ad/alt-bilgi kutusu + (görebiliyorsa)
/// sohbet ikonu + aç/kapa chevron'u. Satıra dokunmak açar/kapatır.
class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.depth,
    required this.expanded,
  });

  final Group group;
  final int depth;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => state.toggleTreeGroup(group.id),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12 + depth * 20.0, 5, 8, 5),
        child: Row(
          children: [
            GroupAvatar(group: group, radius: 22),
            const SizedBox(width: 10),
            Expanded(
              child: InfoBox(
                // "N Bölüm · M kişi" alt-bilgisi kaldırıldı (kullanıcı hükmü) —
                // tek satır ad. ÜYESİ olduğum kurumsal grupta "Üye" rozeti
                // (kullanıcı hükmü: özel gruplar ayrı sekmede, kurumsal
                // üyelikler burada işaretli).
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (state.isEffectiveMember(group)) ...[
                      const SizedBox(width: 8),
                      TagChip(label: context.s.memberBadge),
                    ],
                  ],
                ),
              ),
            ),
            // İkon = "buraya yazabilirim" (FR-90 hızlı-yazma kısayolu). Satır
            // dokunuşu aç/kapa'ya gittiği için sohbet ayrı ikondan açılır.
            if (state.canSeeGroupChat(group))
              IconButton(
                tooltip: context.s.openChat,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupChatScreen(groupId: group.id),
                      ),
                    ),
              ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Yaprak düğüm açılınca gösterilen üye satırı (kutulu, girintili).
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.indent});

  final Member member;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContactDetailScreen(memberId: member.id),
            ),
          ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12 + indent, 4, 12, 4),
        child: Row(
          children: [
            MemberAvatar(member: member),
            const SizedBox(width: 10),
            Expanded(
              child: InfoBox(
                // İsim düzeni tek satır: "Ad SOYAD, Ünvan, Bölüm [rakam]".
                child: Text.rich(
                  member.rowLabelSpan(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

