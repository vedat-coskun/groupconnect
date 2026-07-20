import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../contacts/directory_search_screen.dart';
import '../groups/group_chat_screen.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

/// Unified conversation list: group chats + surfaced 1:1 threads (FR-29).
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  // Kurumsal hiyerarşide AÇIK düğümler (accordion — Kurum Yapısı deseni).
  // Set: bir düğümü açmak diğerini kapatmaz; kapatılan düğümün altı gizlenir.
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final all = state.chatSummaries;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Başlık kutusu (kutu konsepti) + "Yeni Sohbet" eylemi.
            BoxedPageHeader(
              title: s.chatsTitle,
              actionTooltip: s.newChatTitle,
              onAction:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewChatScreen()),
                  ),
            ),
            Expanded(
              child:
                  all.isEmpty
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
                      : ListView(
                        padding: const EdgeInsets.only(top: 4, bottom: 24),
                        children: _accordionSections(all, s, state),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  /// Üç KATEGORİ akordiyonu (Kişisel / Kurumsal / Özel — kullanıcı tercihi
  /// 2026-07-19): başlıklar ince kutu, VARSAYILAN KAPALI, açık/kapalı durumu
  /// AppState'te (logout'a kadar kalıcı). Boş kategori hiç gösterilmez.
  /// KURUMSAL açıksa içerik HİYERARŞİKTİR (kökler üstte, altlar girintili).
  List<Widget> _accordionSections(
    List<ChatSummary> all,
    AppStrings s,
    AppState state,
  ) {
    final children = <Widget>[];
    void section(
      String key,
      String title,
      bool Function(ChatSummary) test, {
      List<Widget> Function(List<ChatSummary>)? layout,
    }) {
      final items = all.where(test).toList();
      if (items.isEmpty) return;
      final expanded = state.isChatSectionExpanded(key);
      children.add(
        BoxedRoleHeader(
          title,
          dimLastWord: true, // "sohbetler(i)" sözcüğü sönük
          collapsed: !expanded,
          onToggle: () => state.toggleChatSection(key),
        ),
      );
      if (expanded) {
        children.addAll(
          layout != null
              ? layout(items)
              : items.map((c) => _ChatTile(summary: c)),
        );
      }
    }

    // Sıra (kullanıcı tercihi): Kurumsal → Özel → Kişisel.
    section(
      'organized',
      s.chatSectionOrganized,
      (c) => c.isGroup && (c.group?.isOrganized ?? false),
      layout: (items) => _organizedTree(items, state),
    );
    section(
      'private',
      s.chatSectionPrivate,
      (c) => c.isGroup && !(c.group?.isOrganized ?? true),
    );
    section('personal', s.chatSectionPersonal, (c) => !c.isGroup);
    return children;
  }

  /// Kurumsal sohbetleri hiyerarşiye göre dizer: kökler üstte, çocuklar
  /// **accordion** içinde (Kurum Yapısı deseni — satıra dokun: aç/kapa,
  /// balon ikonu: sohbeti aç). Kardeş sırası ALFABETİK DEĞİL, verinin
  /// (admin'in) tanım sırasıdır — ör. Site'de Personel, Sakin, Ev Sahibi.
  /// Görünmeyen (ör. bana kapalı) bir ara düğümün görünen çocuğu, en yakın
  /// GÖRÜNEN atasının altına asılır; hiç görünen atası yoksa kök hizasında.
  List<Widget> _organizedTree(List<ChatSummary> items, AppState state) {
    final byGroupId = {for (final c in items) c.group!.id: c};
    final dataOrder = {
      for (final (i, g) in state.td.groups.indexed) g.id: i,
    };

    // id -> görünür ebeveyn id (ata zincirinde ilk görünür düğüm).
    String? visibleParent(Group g) {
      var p = g.parentGroupId;
      while (p != null && !byGroupId.containsKey(p)) {
        p = state.td.group(p)?.parentGroupId;
      }
      return p;
    }

    final childrenOf = <String?, List<ChatSummary>>{};
    for (final c in items) {
      childrenOf.putIfAbsent(visibleParent(c.group!), () => []).add(c);
    }
    for (final list in childrenOf.values) {
      list.sort(
        (a, b) =>
            (dataOrder[a.group!.id] ?? 0) - (dataOrder[b.group!.id] ?? 0),
      );
    }

    final out = <Widget>[];
    void emit(String? parentId, int depth) {
      for (final c in childrenOf[parentId] ?? const <ChatSummary>[]) {
        final id = c.group!.id;
        final hasChildren = childrenOf.containsKey(id);
        final isOpen = hasChildren && _expanded.contains(id);
        out.add(
          _ChatTile(
            summary: c,
            indent: depth * 20.0,
            expanded: hasChildren ? isOpen : null,
            onToggle:
                hasChildren
                    ? () => setState(() {
                          if (!_expanded.remove(id)) _expanded.add(id);
                        })
                    : null,
          ),
        );
        if (isOpen) emit(id, depth + 1);
      }
    }

    emit(null, 0);
    return out;
  }

  void _openDirectory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DirectorySearchScreen()),
    );
  }
}

/// Sohbet satırı — **Gruplar → Üye Olduklarım satırıyla aynı düzen** (FR-100):
/// son mesaj/saat YOK (liste ekranı içerik sızdırmaz — E2E ilkesiyle uyumlu);
/// alt yazı grupta açıklama, 1:1'de "Ünvan · Bölüm"; grup satırının sağında
/// tür rozeti + üye sayısı, sessizse 🔕.
///
/// Alt düğümü olan kurumsal satır **accordion başlığıdır** (Kurum Yapısı
/// deseni): satıra dokunmak aç/kapa yapar, sohbete balon ikonundan girilir.
class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.summary,
    this.indent = 0,
    this.expanded,
    this.onToggle,
  });

  final ChatSummary summary;

  /// Kurumsal hiyerarşide alt düğüm girintisi (kök = 0).
  final double indent;

  /// null = accordion değil (dokunmak sohbeti açar). true/false = açık/kapalı.
  final bool? expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final g = summary.group;
    final m = summary.member;
    // Kurumsal grup sohbetlerinde açıklama GEREKSİZ (kullanıcı hükmü — ad zaten
    // yeterli); özel grupta açıklama, 1:1'de "Ünvan · Bölüm" kalır.
    final subtitle =
        g != null
            ? (g.isOrganized ? '' : g.description)
            : [
              if (m!.title.isNotEmpty) m.title,
              if (m.department.isNotEmpty) m.department,
            ].join(' · ');
    void openChat() {
      if (g != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: g.id)),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatScreen(memberId: m!.id)),
        );
      }
    }

    return InkWell(
      // Accordion başlığında dokunuş aç/kapa; sohbet balon ikonundan.
      onTap: expanded == null ? openChat : onToggle,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 + indent, 6, 12, 6),
        child: Row(
          children: [
            g != null
                ? GroupAvatar(group: g, radius: 22)
                : MemberAvatar(member: m!, radius: 22),
            const SizedBox(width: 10),
            // "Kutu kutu" (kullanıcı tercihi): ad+açıklama kutuda; sağdaki
            // Kurumsal/Özel rozeti kaldırıldı (bölüm başlığıyla zaten belli),
            // üye sayısı sade CountBox. Avatar ve accordion kontrolleri serbest.
            Expanded(
              child: InfoBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (summary.muted)
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Accordion başlığında sohbete giriş balon ikonu (Kurum Yapısı
            // hükmüyle aynı kısayol; satır dokunuşu aç/kapa'ya gitti).
            if (expanded != null)
              IconButton(
                tooltip: s.openChat,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: openChat,
              ),
            // Hiyerarşi düğümünde alt ağacın toplamı (FR-71).
            if (g != null) CountBox(count: state.groupMemberCount(g)),
            if (expanded != null)
              Icon(
                expanded! ? Icons.expand_less : Icons.expand_more,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
