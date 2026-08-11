import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
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
                        // Yeni sohbet sağ üstteki "+" ile açılır — ayrı "Kişi
                        // Ekle" butonu kaldırıldı (o Kişiler'in işi; burada
                        // çift/farklı-yön eylem kafa karıştırıyordu — 2026-08-01).
                        subtitle: s.chatsEmptyHint,
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
              // Kategori satırları da HEPSİ gibi gelen-kutusu görünümünde:
              // son mesaj önizlemesi + saat; kişi statüsü/rol ve grup üye
              // sayısı gösterilmez (kullanıcı hükmü 2026-08-06).
              : items.map((c) => _ChatTile(summary: c, showActivity: true)),
        );
      }
    }

    // EN ÜSTTE "HEPSİ" (kullanıcı tercihi 2026-07-22): tüm sohbetler tek DÜZ
    // listede, WhatsApp gibi — kategori ayrımı ve hiyerarşi/girinti YOK.
    // Aşağıdaki kategori bölümleri aynen durur (aynı sohbet iki yerde görünür).
    //
    // Kategori bölümlerinden AYRILAN yanı: (1) yalnız **içi dolu** sohbetler
    // (en az bir mesaj) — kategoriler bir DİZİNdir, HEPSİ gerçek konuşmalardır;
    // (2) satırlar son mesaj ÖNİZLEMESİ + saat gösterir (`showActivity`) ve
    // **son aktiviteye göre** sıralanır (FR-100 geri alındı — kurum sahibi
    // hükmü 2026-07-22). Kategori satırları içerik taşımamaya devam eder.
    section(
      'all',
      s.chatSectionAll,
      (c) => state.hasMessages(c.threadId),
      layout: (items) {
        final sorted = [...items]..sort((a, b) {
          final ta = a.lastMessageTime, tb = b.lastMessageTime;
          if (ta == null && tb == null) {
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          }
          if (ta == null) return 1;
          if (tb == null) return -1;
          return tb.compareTo(ta); // en yeni üstte
        });
        return [
          for (final c in sorted) _ChatTile(summary: c, showActivity: true),
        ];
      },
    );

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
            showActivity: true, // kurumsal satırlar da son mesaj + saat gösterir
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
    this.showActivity = false,
  });

  final ChatSummary summary;

  /// Kurumsal hiyerarşide alt düğüm girintisi (kök = 0).
  final double indent;

  /// null = accordion değil (dokunmak sohbeti açar). true/false = açık/kapalı.
  final bool? expanded;
  final VoidCallback? onToggle;

  /// Gelen-kutusu görünümü: alt yazı son mesaj önizlemesi olur ve sağda saat
  /// gösterilir (CountBox/statü yerine). Sohbetler ekranındaki TÜM bölümler
  /// (HEPSİ + Kurumsal/Özel/Kişisel) bunu kullanır (kullanıcı hükmü 2026-08-06);
  /// false = eski dizin düzeni (ad + açıklama/statü + üye sayısı).
  final bool showActivity;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final g = summary.group;
    final m = summary.member;
    // showActivity: alt yazı = son mesaj önizlemesi (mesaj yoksa boş). false
    // (eski dizin düzeni): kurumsal grupta boş, özel grupta açıklama, 1:1'de
    // "Ünvan · Bölüm".
    final subtitle =
        showActivity
            ? (summary.lastMessageText ?? '')
            : g != null
            ? (g.isOrganized ? '' : g.description)
            : [
              if (m!.title.isNotEmpty) m.title,
              if (m.department.isNotEmpty) m.department,
            ].join(' · ');
    final timeStr =
        showActivity && summary.lastMessageTime != null
            ? _formatChatTime(context, summary.lastMessageTime!)
            : null;
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
                        // HEPSİ: son mesaj saati (WhatsApp gibi, sağ üst).
                        if (timeStr != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        // HEPSİ önizlemesi tek satır (gelen-kutusu); diğer
                        // bölümlerde açıklama iki satıra kadar.
                        maxLines: showActivity ? 1 : 2,
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
            // Hiyerarşi düğümünde alt ağacın toplamı (FR-71). HEPSİ'de saat
            // bu yeri aldı — üye sayısı gösterilmez (gelen-kutusu görünümü).
            if (g != null && !showActivity)
              CountBox(count: state.groupMemberCount(g)),
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

/// HEPSİ satırındaki son-mesaj saat etiketi: bugün → "SS:dd", dün → "Dün",
/// daha eski → "gg.aa". Saat/tarih yalnız HEPSİ'de gösterilir (FR-100 geri
/// alındı). intl bağımlılığı yok — elle biçimlenir.
String _formatChatTime(BuildContext context, DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  String two(int n) => n.toString().padLeft(2, '0');
  if (day == today) return '${two(t.hour)}:${two(t.minute)}';
  if (day == today.subtract(const Duration(days: 1))) {
    return context.s.yesterdayShort;
  }
  return '${two(t.day)}.${two(t.month)}';
}
