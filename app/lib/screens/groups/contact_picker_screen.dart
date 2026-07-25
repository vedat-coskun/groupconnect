import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';

/// Multi-select of the user's personal contacts (FR-38, FR-41).
///
/// Two modes:
/// - **Pick** ([groupId] == null): returns the selected member ids (e.g. while
///   *creating* a group — invites are sent on creation).
/// - **Manage** ([groupId] != null): reflects the existing group's state —
///   current members come pre-checked + disabled, pending invitees pre-checked.
///   "Uygula" syncs: newly-checked → invite sent, unchecked invitees → cancelled.
class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({
    super.key,
    this.title,
    this.excludeIds = const {},
    this.groupId,
  });

  final String? title;
  final Set<String> excludeIds;
  final String? groupId;

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  final Set<String> _selected = {};
  Set<String> _members = {};
  Set<String> _alreadyInvited = {};

  bool get _manage => widget.groupId != null;

  @override
  void initState() {
    super.initState();
    if (_manage) {
      final state = AppScope.of(context, listen: false);
      final g = state.td.group(widget.groupId!);
      _members = g?.memberIds.toSet() ?? {};
      _alreadyInvited = state.pendingGroupInviteeIds(widget.groupId!);
      // Mevcut durumu yansıt: üyeler + bekleyen davetliler işaretli gelir.
      _selected
        ..addAll(_members)
        ..addAll(_alreadyInvited);
    }
  }

  void _save() {
    final state = AppScope.of(context, listen: false);
    final s = context.s;
    if (!_manage) {
      Navigator.pop(context, _selected.toList());
      return;
    }
    // Senkron: yeni işaretlenenlere davet gönder, işareti kalkan davetlileri iptal et.
    final gid = widget.groupId!;
    final toInvite =
        _selected.difference(_members).difference(_alreadyInvited).toList();
    final toCancel = _alreadyInvited.difference(_selected).toList();
    final messenger = ScaffoldMessenger.of(context);
    if (toInvite.isNotEmpty) state.inviteMembersToGroup(gid, toInvite);
    for (final id in toCancel) {
      state.cancelGroupInvite(gid, id);
    }
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(s.inviteSyncSummary(toInvite.length, toCancel.length))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    // İki üst bölüm (kurum sahibi hükmü): REHBERİM, sonra HERKES — davet
    // rehberle sınırlı değildir; matrisin doğrudan gördüğü herkes davet
    // edilebilir. Görünüm Kişiler'dekiyle aynı: rol bölümleri + favori üstte
    // + kalp; fark yalnız sağdaki seçim kutusudur.
    final contactIds = state.contacts.map((m) => m.id).toSet();
    final rehber =
        state.contacts
            .where((m) => !widget.excludeIds.contains(m.id))
            .toList();
    final herkes =
        state.everyoneVisible
            .where(
              (m) =>
                  !contactIds.contains(m.id) &&
                  !widget.excludeIds.contains(m.id),
            )
            .toList();
    // Yönetim modunda listeye girmeyen mevcut üye/davetli kalmasın (örn.
    // matris-dışı bir üye) — HERKES kovasının sonuna eklenir (zaten kilitli).
    final shown = {...rehber.map((m) => m.id), ...herkes.map((m) => m.id)};
    for (final id in {..._members, ..._alreadyInvited}) {
      if (shown.contains(id) || widget.excludeIds.contains(id)) continue;
      final m = state.td.member(id);
      if (m != null && m.id != state.td.myId) herkes.add(m);
    }
    final canSave = _manage || _selected.isNotEmpty;

    List<Widget> bucket(String title, List<Member> people) {
      if (people.isEmpty) return const [];
      return [
        RoleHeader(title),
        ...roleSections(
          context: context,
          members: people,
          roles: state.tenantRoles,
          roleName: state.roleName,
          header: (t) => _SubHeader(t),
          otherLabel: s.contactsTitle,
          // Favoriler gibi, zaten DAVET ETTİKLERİM de rol bölümünün üstüne
          // pinlenir (kullanıcı hükmü 2026-07-25) — ayrı bir davetli listesi yok.
          pinned: (m) => state.isFavorite(m.id) || _alreadyInvited.contains(m.id),
          row: _personRow,
        ),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? s.inviteMembers),
        actions: [
          TextButton(
            onPressed: canSave ? _save : null,
            child: Text(
              _manage
                  ? s.updateInvites
                  : '${s.sendInvite} (${_selected.length})',
            ),
          ),
        ],
      ),
      body:
          (rehber.isEmpty && herkes.isEmpty)
              ? EmptyState(
                icon: Icons.people_outline,
                title: s.contactsEmpty,
                subtitle: s.contactsEmptyHint,
              )
              : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  ...bucket(s.myContactsTab, rehber),
                  ...bucket(s.everyoneTab, herkes),
                ],
              ),
    );
  }

  // Kişiler'deki satırın seçim kutulu hali: kalp + avatar + tek satır isim +
  // checkbox. Üyeler kilitli (davet değil üyelik; çıkarma Grup Bilgisi'nde).
  Widget _personRow(Member m) {
    final state = AppScope.of(context);
    final fav = state.isFavorite(m.id);
    final isMember = _members.contains(m.id);
    final selected = _selected.contains(m.id);
    return InkWell(
      onTap:
          isMember
              ? null
              : () => setState(() {
                if (!_selected.remove(m.id)) _selected.add(m.id);
              }),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
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
            Expanded(
              child: Text.rich(
                m.rowLabelSpan(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Checkbox(
              value: isMember || selected,
              onChanged:
                  isMember
                      ? null
                      : (v) => setState(() {
                        if (v == true) {
                          _selected.add(m.id);
                        } else {
                          _selected.remove(m.id);
                        }
                      }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Üst kovaların (REHBERİM / HERKES) içindeki rol alt-başlığı — daha sönük.
class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Text(
        context.upper(text),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Convenience: push the picker and await the selected member ids (pick mode).
/// Pass [groupId] for manage mode (syncs invites for an existing group).
Future<List<String>?> pickContacts(
  BuildContext context, {
  String? title,
  Set<String> excludeIds = const {},
  String? groupId,
}) {
  return Navigator.of(context).push<List<String>>(
    MaterialPageRoute(
      builder:
          (_) => ContactPickerScreen(
            title: title,
            excludeIds: excludeIds,
            groupId: groupId,
          ),
    ),
  );
}
