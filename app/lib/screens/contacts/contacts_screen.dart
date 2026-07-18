import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
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
        appBar: AppBar(
          title: Text(s.contactsTitle),
          actions: [
            IconButton(
              tooltip: s.addContact,
              icon: const Icon(Icons.add),
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DirectorySearchScreen(),
                    ),
                  ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: s.everyoneTab),
              Tab(text: s.myContactsTab),
              Tab(text: s.addedMeTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_EveryoneList(), _PeopleList(), _AddedMeTab()],
        ),
      ),
    );
  }
}

class _PeopleList extends StatelessWidget {
  const _PeopleList();

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

    final favs = contacts.where((m) => state.isFavorite(m.id)).toList();
    final others = contacts.where((m) => !state.isFavorite(m.id)).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        if (favs.isNotEmpty) ...[
          _SectionHeader(s.favoritesTitle),
          // Favoriler içinde de aynı rol sırası (başlıksız, düz).
          for (final m in _byRoleOrder(context, favs)) _contactTile(context, m),
        ],
        // Kalanlar rol (kategori) bazında — admin'in tanımladığı rol sırasıyla.
        // Ortak kural: rol (kategori) başlıkları, admin sırasıyla.
        ...roleSections(
          context: context,
          members: others,
          roles: AppScope.of(context).tenantRoles,
          roleName: AppScope.of(context).roleName,
          row: (m) => _contactTile(context, m, removable: true),
          header: (t) => _SectionHeader(t),
          otherLabel: s.contactsTitle,
        ),
      ],
    );
  }

  /// Sort by (admin role order, name) without adding headers.
  List<Member> _byRoleOrder(BuildContext context, List<Member> list) {
    final roles = AppScope.of(context).tenantRoles;
    final order = {
      for (var i = 0; i < roles.length; i++) roles[i].id: i,
    };
    final sorted = [...list];
    sorted.sort((a, b) {
      final ra = order[a.roleId] ?? 1 << 20;
      final rb = order[b.roleId] ?? 1 << 20;
      if (ra != rb) return ra.compareTo(rb);
      return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
    });
    return sorted;
  }

}

// Özel Row (ListTile değil): dar ekranda leading'deki kalp+avatar ListTile'ı
// taşırmasın diye Expanded başlıklı Row kullanıyoruz. Herkes + Rehberim ortak.
Widget _contactTile(
  BuildContext context,
  Member m, {
  bool removable = false,
}) {
    final state = AppScope.of(context);
    final fav = state.isFavorite(m.id);
    return InkWell(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(memberId: m.id)),
          ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
        child: Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                fav ? Icons.favorite : Icons.favorite_border,
                color: fav ? Colors.red : null,
              ),
              onPressed:
                  () =>
                      AppScope.of(context, listen: false).toggleFavorite(m.id),
            ),
            MemberAvatar(member: m),
            const SizedBox(width: 12),
            // İsim düzeni tek satır: "Ad SOYAD, Ünvan, Bölüm [rakam]".
            Expanded(
              child: Text(
                m.rowLabel(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // Rehberim'de silme (kurum sahibi hükmü): onaysız (NFR-18).
            // Onayla eklenmişse kişi DAVETLER → Onaylananlar'a düşer (rıza
            // kaybolmaz); doğrudan eklenmişse tamamen silinir.
            if (removable)
              IconButton(
                tooltip: context.s.removeFromContacts,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.person_remove_outlined),
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  AppScope.of(context, listen: false).removeContact(m.id);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(context.s.removeFromContacts),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
}

/// HERKES — rehbere eklemeden erişebildiğim herkes (matris; FR yeni).
/// Satıra dokun → doğrudan sohbet. Kalp → hızlı erişim sabitlemesi.
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
          row: (m) => _contactTile(context, m),
          header: (t) => _SectionHeader(t),
          otherLabel: s.contactsTitle,
          pinned: (m) => state.isFavorite(m.id),
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
    final outgoing = state.outgoingInvites; // benim gönderdiğim (bekleyen)
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
          _SectionHeader(s.sentInvites),
          for (final inv in outgoing) _outgoingRow(context, inv),
        ],
        if (approved.isNotEmpty) ...[
          _SectionHeader(s.approvedSection),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            MemberAvatar(member: m),
            const SizedBox(width: 12),
            Expanded(
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
            const SizedBox(width: 8),
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

  // Giden (gönderdiğim) → bekliyor etiketi + iptal.
  Widget _outgoingRow(BuildContext context, Invitation inv) {
    final state = AppScope.of(context);
    final id = inv.toMemberId;
    final m = id != null ? state.td.member(id) : null;
    if (m == null) return const SizedBox.shrink();
    final s = context.s;
    return _row(
      context,
      m,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(s.pending),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: s.cancel,
            icon: const Icon(Icons.close),
            onPressed:
                () => AppScope.of(context, listen: false).cancelInvite(inv),
          ),
        ],
      ),
    );
  }
}

/// Section label.
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
