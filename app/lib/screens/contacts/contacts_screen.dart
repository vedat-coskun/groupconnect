import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../state/mock_data.dart';
import '../../widgets/common.dart';
import '../chats/chat_screen.dart';
import 'contact_detail_screen.dart';
import 'directory_search_screen.dart';

/// Kişiler — ÜÇ sekme:
/// - **Herkes**: rehbere eklemeden erişebildiğim herkes — rolümün matriste
///   doğrudan gördüğü rollerin tüm üyeleri (Admin Ayarları → Doğrudan Görme).
/// - **Rehberim**: benim seçtiklerim + onayla eklediklerim.
/// - **Davetler**: bekleyen onaylar (gelen) + gönderdiklerim.
/// Her listede kişiler rol ayraçlarıyla gruplu; her bölümün İÇİNDE favoriler
/// üstte (favori = hızlı erişim sabitlemesi, arkadaşlık değil).
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // AppBar yerine kutu başlık + kutu sekme çubuğu (kullanıcı tercihi).
        body: SafeArea(
          child: Column(
            children: [
              BoxedPageHeader(
                title: s.contactsTitle,
                actionTooltip: s.addContact,
                onAction:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DirectorySearchScreen(),
                      ),
                    ),
              ),
              BoxedTabBar(
                labels: [s.everyoneTab, s.myContactsTab, s.addedMeTab],
              ),
              const Expanded(
                child: TabBarView(
                  children: [_EveryoneList(), _PeopleList(), _AddedMeTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeopleList extends StatefulWidget {
  const _PeopleList();

  @override
  State<_PeopleList> createState() => _PeopleListState();
}

class _PeopleListState extends State<_PeopleList> {
  // Rol başlığına dokununca o bölüm katlanır/açılır (yalnız bu ekran içinde).
  final Set<String> _collapsedRoles = {};

  // Outlook tarzı çoklu seçim pilotu (kullanıcı tercihi): avatara dokununca
  // seçim moduna girilir; avatarların yerini seçim daireleri alır, üstte
  // Tümünü Seç / Tümünü Bırak çubuğu belirir.
  bool _selecting = false;
  final Set<String> _selected = {};

  void _exitSelection() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final contacts = state.contacts;

    if (contacts.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: s.contactsEmpty,
        subtitle: s.contactsEmptyHint,
      );
    }

    final allSelected = _selected.length == contacts.length;

    // FR-54/FR-79 (kullanıcı hükmüyle teyit): ayrı FAVORİLER bölümü YOK —
    // HERKES ile aynı düzen: rol başlıklı accordion, favoriler kendi rol
    // bölümünün en üstünde yüzer (çizgili kalple işaretli).
    final list = ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        ...roleSections(
          context: context,
          members: contacts,
          roles: AppScope.of(context).tenantRoles,
          roleName: AppScope.of(context).roleName,
          row:
              (m) => _contactTile(
                context,
                m,
                removable: true,
                selecting: _selecting,
                selected: _selected.contains(m.id),
                onEnterSelect:
                    () => setState(() {
                      _selecting = true;
                      _selected.add(m.id);
                    }),
                onToggleSelect:
                    () => setState(() {
                      if (!_selected.remove(m.id)) _selected.add(m.id);
                    }),
              ),
          header:
              (label) => BoxedRoleHeader(
                label,
                collapsed: _collapsedRoles.contains(label),
                onToggle:
                    () => setState(() {
                      if (!_collapsedRoles.remove(label)) {
                        _collapsedRoles.add(label);
                      }
                    }),
              ),
          otherLabel: s.contactsTitle,
          pinned: (m) => state.isFavorite(m.id),
          collapsed: (label) => _collapsedRoles.contains(label),
        ),
      ],
    );

    if (!_selecting) return list;
    return Column(
      children: [
        _SelectionBar(
          allSelected: allSelected,
          count: _selected.length,
          // "Tümünü Bırak" (hepsi seçiliyken) seçim modundan tümüyle çıkar
          // (kullanıcı hükmü — başa dön); değilse hepsini seçer.
          onToggleAll:
              allSelected
                  ? _exitSelection
                  : () => setState(
                        () => _selected
                          ..clear()
                          ..addAll(contacts.map((m) => m.id)),
                      ),
          onRemoveSelected:
              _selected.isEmpty
                  ? null
                  : () {
                    final messenger = ScaffoldMessenger.of(context);
                    final n = _selected.length;
                    final appState = AppScope.of(context, listen: false);
                    for (final id in _selected) {
                      appState.removeContact(id);
                    }
                    _exitSelection();
                    messenger.showSnackBar(
                      SnackBar(content: Text(s.removedCount(n))),
                    );
                  },
          onClose: _exitSelection,
        ),
        Expanded(child: list),
      ],
    );
  }
}

/// Seçim modunun üst çubuğu (Outlook örneği): solda Tümünü Seç/Bırak, sağda
/// sayaç + toplu sil + kapat.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.allSelected,
    required this.count,
    required this.onToggleAll,
    required this.onRemoveSelected,
    required this.onClose,
  });

  final bool allSelected;
  final int count;
  final VoidCallback onToggleAll;
  final VoidCallback? onRemoveSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    // Dar ekran (393px) dersi: satır SABİT genişlikli olamaz — düğme ve sayaç
    // esnek (Flexible/Expanded + ellipsis), ikonlar kompakt.
    return Material(
      color: scheme.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Flexible(
              child: TextButton.icon(
                onPressed: onToggleAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: Icon(Icons.select_all, color: scheme.onPrimary, size: 18),
                label: Text(
                  allSelected ? s.unselectAll : s.selectAll,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                s.selectedCount(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(color: scheme.onPrimary),
              ),
            ),
            IconButton(
              tooltip: s.removeFromContacts,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.person_remove_outlined, color: scheme.onPrimary),
              onPressed: onRemoveSelected,
            ),
            IconButton(
              tooltip: s.cancel,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, color: scheme.onPrimary),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

// Özel Row (ListTile değil): dar ekranda leading'deki kalp+avatar ListTile'ı
// taşırmasın diye Expanded başlıklı Row kullanıyoruz. Herkes + Rehberim ortak.
// Seçim modu (Outlook pilotu — yalnız Rehberim geçer): avatar dokunuşu modu
// başlatır [onEnterSelect]; modda avatarların yerini seçim daireleri alır,
// satır dokunuşu seçimi çevirir, sağ eylem ikonları gizlenir.
Widget _contactTile(
  BuildContext context,
  Member m, {
  bool removable = false,
  bool showAddToContacts = false,
  bool selecting = false,
  bool selected = false,
  VoidCallback? onEnterSelect,
  VoidCallback? onToggleSelect,
}) {
    final state = AppScope.of(context);
    final fav = state.isFavorite(m.id);
    final isContact = state.isContact(m.id);
    return InkWell(
      onTap:
          selecting
              ? onToggleSelect
              : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChatScreen(memberId: m.id)),
              ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
        child: Row(
          children: [
            if (selecting) ...[
              const SizedBox(width: 12),
              _selectCircle(context, selected: selected),
            ] else ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: _favoriteHeart(isFavorite: fav),
                onPressed:
                    () => AppScope.of(
                      context,
                      listen: false,
                    ).toggleFavorite(m.id),
              ),
              GestureDetector(
                onTap: onEnterSelect,
                child: MemberAvatar(member: m),
              ),
            ],
            const SizedBox(width: 10),
            // İsim düzeni tek satır: "Ad SOYAD, Ünvan, Bölüm [rakam]".
            // "Kutu kutu" (kullanıcı tercihi): yalnız ORTADAKİ metin kutuda —
            // avatar ve sağdaki ekle/çıkar ikonu serbest kalır.
            Expanded(
              child: InfoBox(
                child: Text.rich(
                  m.rowLabelSpan(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // HERKES'te Rehberim durumu — ÜÇ durum:
            //  • kişi zaten rehberde → kırmızı "−" (çıkar);
            //  • ona bekleyen davetim var → saat (dokun: daveti iptal et);
            //  • değilse → yeşil "+" (onay-FARKINDA ekle: matris/politika
            //    doğrudan ekletiyorsa anında; değilse onay daveti gider —
            //    "Görünür ama matris-dışı" kişide, kurum sahibi hükmü 2026-08-01).
            if (showAddToContacts && !selecting)
              isContact
                  ? IconButton(
                    tooltip: context.s.removeFromContacts,
                    visualDensity: VisualDensity.compact,
                    // Çıkarma = kırmızı, ekleme = yeşil (kullanıcı hükmü).
                    icon: const Icon(
                      Icons.person_remove_outlined,
                      color: Colors.red,
                    ),
                    // Bildirim yok — ikon değişimi kalıcı onay (bkz. ekleme).
                    onPressed:
                        () => AppScope.of(
                          context,
                          listen: false,
                        ).removeContact(m.id),
                  )
                  : state.pendingContactInviteTo(m.id) != null
                  ? IconButton(
                    tooltip: context.s.cancel,
                    visualDensity: VisualDensity.compact,
                    // Bekleyen davet: saat ikonu, dokununca iptal.
                    icon: Icon(
                      Icons.schedule,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      final st = AppScope.of(context, listen: false);
                      final inv = st.pendingContactInviteTo(m.id);
                      if (inv != null) st.cancelInvite(inv);
                    },
                  )
                  : IconButton(
                    tooltip: context.s.addToContacts,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.person_add_alt,
                      color: Colors.green,
                    ),
                    // Onay-farkında ekleme: doğrudan eklenirse ikon "−"ye döner;
                    // onay gerekiyorsa "beklemede" (saat) durumuna geçer.
                    onPressed:
                        () => AppScope.of(
                          context,
                          listen: false,
                        ).addContact(m.id),
                  ),
            // Rehberim'de silme (kurum sahibi hükmü): onaysız (NFR-18).
            // Onayla eklenmişse kişi DAVETLER → Onaylananlar'a düşer (rıza
            // kaybolmaz); doğrudan eklenmişse tamamen silinir.
            if (removable && !selecting)
              IconButton(
                tooltip: context.s.removeFromContacts,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.person_remove_outlined,
                  color: Colors.red,
                ),
                // Bildirim yok: çıkarınca satır Rehberim'den kaybolur, bu
                // yeterli görsel geri bildirim.
                onPressed:
                    () =>
                        AppScope.of(context, listen: false).removeContact(m.id),
              ),
          ],
        ),
      ),
    );
}

// Seçim dairesi (Outlook pilotu): seçili = dolu daire + beyaz onay işareti,
// değil = içi boş çember. Avatarla aynı boyut (40) — satır yüksekliği oynamaz.
Widget _selectCircle(BuildContext context, {required bool selected}) {
  final scheme = Theme.of(context).colorScheme;
  if (selected) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: scheme.primary,
      child: Icon(Icons.check, color: scheme.onPrimary),
    );
  }
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: scheme.outline, width: 2),
    ),
  );
}

// Kalp yalnız FAVORİ'yi kodlar (kullanıcı hükmü — sıralama da yalnız favori
// üzerinden, FR-79): favori = kırmızı çizgili boş kalp; diğer herkes boş
// (dokunma alanı durur, görünmez). Dolu kalp YOK. Rehber durumu satırın
// SAĞINDAKİ yeşil ekle / kırmızı çıkar ikonunda zaten görünür — solda
// tekrarlanmaz.
Widget _favoriteHeart({required bool isFavorite}) {
  if (isFavorite) {
    return const Icon(Icons.favorite_border, color: Colors.red);
  }
  return const SizedBox.shrink();
}

/// HERKES — rehbere eklemeden erişebildiğim herkes (matris; FR yeni).
/// Satıra dokun → doğrudan sohbet. Kalp → hızlı erişim sabitlemesi.
///
/// Rol bölümleri VARSAYILAN KAPALI başlar; açık/kapalı durumu widget'ta değil
/// AppState'te tutulur (kullanıcı tercihi 2026-07-19) — sekme değişince
/// sıfırlanmaz, yalnız logout temizler. Bu yüzden Stateless.
class _EveryoneList extends StatelessWidget {
  const _EveryoneList();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final people = state.everyoneVisible;

    if (people.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: s.noResults,
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        ...roleSections(
          context: context,
          members: people,
          roles: state.tenantRoles,
          roleName: state.roleName,
          row: (m) => _contactTile(context, m, showAddToContacts: true),
          header:
              (label) => BoxedRoleHeader(
                label,
                // Açık değilse "kapalı" görünür (varsayılan kapalı).
                collapsed: !state.isEveryoneRoleExpanded(label),
                onToggle: () => state.toggleEveryoneRole(label),
              ),
          otherLabel: s.contactsTitle,
          pinned: (m) => state.isFavorite(m.id),
          collapsed: (label) => !state.isEveryoneRoleExpanded(label),
        ),
      ],
    );
  }
}

/// "Beni Ekleyenler" — incoming connections + my outgoing requests.
class _AddedMeTab extends StatelessWidget {
  const _AddedMeTab();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final invites = state.incomingInvites; // onay bekleyen (kişi daveti)
    // Gönderdiğim rehber davetlerinin TAM geçmişi (bekleyen+kabul+red, tarihli).
    final outgoing = state.sentContactInvites;
    // Rehberim'den silinen ONAYLI kişiler — rıza durur, tek dokunuşla eklenir.
    final approved = state.approvedNotInContacts;

    // Yalnız BEKLEYEN onaylar burada; kabul/red → düşer, otomatik-kabul (doğrudan)
    // olanlar zaten kabul edilmiş sayılır ve burada gösterilmez (Rehberim'de).
    if (invites.isEmpty && outgoing.isEmpty && approved.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: s.noInvitations,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final inv in invites) _approvalRow(context, inv),
        if (outgoing.isNotEmpty) ...[
          BoxedRoleHeader(s.sentInvites),
          for (final inv in outgoing) _outgoingRow(context, inv),
        ],
        if (approved.isNotEmpty) ...[
          BoxedRoleHeader(s.approvedSection),
          for (final m in approved) _approvedRow(context, m),
        ],
      ],
    );
  }

  // Onaylanmış ama rehberde olmayan kişi: "Ekle" onay istemeden geri ekler —
  // rıza davet kabulünde bir kez verilmiştir, yeniden sorulmaz.
  Widget _approvedRow(BuildContext context, Member m) {
    final s = context.s;
    return _row(
      context,
      m,
      trailing: TextButton.icon(
        icon: const Icon(Icons.person_add_alt, size: 18),
        label: Text(s.add),
        onPressed:
            () => AppScope.of(context, listen: false).addContactDirect(m.id),
      ),
    );
  }

  // Ortak, taşmaz person satırı (Expanded başlık).
  Widget _row(BuildContext context, Member m, {required Widget trailing}) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ContactDetailScreen(memberId: m.id),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            MemberAvatar(member: m),
            const SizedBox(width: 10),
            Expanded(
              child: InfoBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${state.roleName(state.roleOf(m))} · ${m.department}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            trailing,
          ],
        ),
      ),
    );
  }

  // Onay bekleyen → enabled: işaretle = kabul, ✕ = reddet.
  Widget _approvalRow(BuildContext context, Invitation inv) {
    final state = AppScope.of(context);
    final m = state.td.member(inv.fromMemberId);
    if (m == null) return const SizedBox.shrink();
    final s = context.s;
    return _row(
      context,
      m,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: s.reject,
            icon: const Icon(Icons.close),
            onPressed:
                () => AppScope.of(context, listen: false).rejectInvite(inv),
          ),
          Checkbox(
            value: false,
            onChanged: (v) {
              if (v == true) {
                AppScope.of(context, listen: false).acceptInvite(inv);
              }
            },
          ),
        ],
      ),
    );
  }

  // Gönderdiğim davet → durum çipi (renk kodlu) + göreli tarih; bekleyende
  // ayrıca iptal (✕). Kabul/red edilmişler salt-okur geçmiştir.
  Widget _outgoingRow(BuildContext context, Invitation inv) {
    final state = AppScope.of(context);
    final id = inv.toMemberId;
    final m = id != null ? state.td.member(id) : null;
    if (m == null) return const SizedBox.shrink();
    final s = context.s;
    final pending = inv.status == InviteStatus.pending;
    return _row(
      context,
      m,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusChip(context, inv.status),
              const SizedBox(height: 2),
              Text(
                _inviteDate(context, inv.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (pending)
            IconButton(
              tooltip: s.cancel,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close),
              onPressed:
                  () => AppScope.of(context, listen: false).cancelInvite(inv),
            ),
        ],
      ),
    );
  }

  // Durum çipi: bekleyen (nötr), kabul (yeşil), red (hata rengi).
  Widget _statusChip(BuildContext context, InviteStatus status) {
    final scheme = Theme.of(context).colorScheme;
    final s = context.s;
    final (String label, Color bg, Color fg) = switch (status) {
      InviteStatus.pending => (
        s.statusPending,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      InviteStatus.accepted => (
        s.statusAccepted,
        const Color(0xFFD7F0DB),
        const Color(0xFF1B5E20),
      ),
      InviteStatus.rejected => (
        s.statusRejected,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Göreli tarih: bugün→"Bugün", dün→"Dün", <7g→"N gün önce", eski→gg.aa.
  String _inviteDate(BuildContext context, DateTime t) {
    final s = context.s;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return s.today;
    if (diff == 1) return s.yesterdayShort;
    if (diff < 7) return s.daysAgo(diff);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}.${two(t.month)}';
  }
}

