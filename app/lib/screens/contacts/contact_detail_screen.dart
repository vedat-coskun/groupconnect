import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';
import '../chats/chat_screen.dart';
import '../groups/create_group_screen.dart';
import '../groups/group_detail_screen.dart';

/// Contact detail (FR-24). Shows the member's visible identity and the actions
/// available: message, add/remove, block, favorite, common groups, and start a
/// common group (FR-45). The phone number is never displayed (NFR-5).
class ContactDetailScreen extends StatelessWidget {
  const ContactDetailScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final m = state.td.member(memberId);
    if (m == null) {
      return const Scaffold(body: Center(child: Text('—')));
    }
    final role = state.roleOf(m);
    final isContact = state.isContact(memberId);
    final isBlocked = state.isBlocked(memberId);
    final isFavorite = state.isFavorite(memberId);
    final common = state.commonGroups(memberId);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (isContact)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? Colors.amber : null,
              ),
              tooltip: isFavorite ? s.removeFavorite : s.addFavorite,
              onPressed:
                  () => AppScope.of(
                    context,
                    listen: false,
                  ).toggleFavorite(memberId),
            ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Center(child: MemberAvatar(member: m, radius: 46)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              m.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TagChip(
              label: state.roleName(role),
              icon:
                  state.isAuthority(m)
                      ? Icons.verified_outlined
                      : Icons.school_outlined,
            ),
          ),
          const SizedBox(height: 20),

          // Primary actions
          if (!isBlocked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => ChatScreen(
                                    memberId: memberId,
                                    // Matris görüyorsa tanışma modu yok.
                                    intro:
                                        !state.treatAsContact(memberId),
                                  ),
                            ),
                          ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(s.sendMessage),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isContact)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _add(context, m, s),
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(s.addToContacts),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Identity fields — NO phone number (NFR-5, FR-24).
          _InfoRow(
            icon: Icons.badge_outlined,
            label: s.memberNoLabel,
            value: m.memberNo,
          ),
          _InfoRow(
            icon: Icons.apartment_outlined,
            label: s.departmentLabel,
            value: m.department,
          ),
          _InfoRow(
            icon: Icons.workspace_premium_outlined,
            label: s.roleLabel,
            value: state.roleName(role),
          ),
          if (m.course != null)
            _InfoRow(
              icon: Icons.menu_book_outlined,
              label: s.course,
              value: m.course!,
            ),

          if (isContact) ...[
            const Divider(height: 24),
            _NotesTile(memberId: memberId),
          ],

          const Divider(height: 24),

          // Common groups (FR-24) + start a common group (FR-45).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              s.commonGroups,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (common.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.noCommonGroups,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final g in common)
              ListTile(
                leading: GroupAvatar(group: g, radius: 18),
                title: Text(g.name),
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(groupId: g.id),
                      ),
                    ),
              ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => CreateGroupScreen(preselectedMemberId: memberId),
                    ),
                  ),
              icon: const Icon(Icons.group_add_outlined),
              label: Text('${s.createGroupTitle} · ${m.fullName.split(' ').first}'),
            ),
          ),

          const Divider(height: 8),

          // Destructive actions
          if (isContact)
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: Text(s.removeFromContacts),
              onTap: () => _remove(context, memberId, s),
            ),
          ListTile(
            leading: Icon(
              isBlocked ? Icons.lock_open_outlined : Icons.block,
              color:
                  isBlocked
                      ? null
                      : Theme.of(context).colorScheme.error,
            ),
            title: Text(
              isBlocked ? s.unblock : s.block,
              style: TextStyle(
                color:
                    isBlocked
                        ? null
                        : Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () {
              final st = AppScope.of(context, listen: false);
              if (isBlocked) {
                st.unblock(memberId);
              } else {
                st.block(memberId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.blockedNotice)),
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _add(BuildContext context, Member m, AppStrings s) {
    final state = AppScope.of(context, listen: false);
    if (m.addPolicy == AddPolicy.everyone) {
      // Bildirim yok: eklenince "Rehbere Ekle" butonu kaybolur ve ekran rehber-
      // içi görünüme geçer — bu kalıcı görsel onay yeter (2026-07-25).
      state.addContact(m.id);
    } else {
      _showInviteSheet(context, m.id, s);
    }
  }

  void _showInviteSheet(BuildContext context, String id, AppStrings s) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (sheetContext) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.addToContacts,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  s.addPolicyHint,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(hintText: s.inviteMessageHint),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    AppScope.of(
                      sheetContext,
                      listen: false,
                    ).addContact(id, message: controller.text);
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.inviteSent)),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: Text(s.send),
                ),
              ],
            ),
          ),
    );
  }

  // Ürün kuralı: hiçbir eylem "Emin misin?" ikinci onayı istemez. Doğrudan
  // uygulanır; sonuç EKRANDAKİ durum değişiminden anlaşılır (buton geri döner) —
  // transient snackbar kaldırıldı (2026-07-25). Rehberden çıkarmak geri
  // alınabilir (kişiyi yeniden ekleyebilirsin).
  void _remove(BuildContext context, String id, AppStrings s) {
    AppScope.of(context, listen: false).removeContact(id);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(label, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      dense: true,
    );
  }
}

class _NotesTile extends StatelessWidget {
  const _NotesTile({required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final note = state.noteFor(memberId);
    return ListTile(
      leading: const Icon(Icons.sticky_note_2_outlined),
      title: Text(s.notes, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(note.isEmpty ? s.notesHint : note),
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: () => _editNote(context, memberId, note, s),
    );
  }

  void _editNote(
    BuildContext context,
    String id,
    String current,
    AppStrings s,
  ) {
    final controller = TextEditingController(text: current);
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(s.notes),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(hintText: s.notesHint),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: () {
                  AppScope.of(
                    dialogContext,
                    listen: false,
                  ).setNote(id, controller.text);
                  Navigator.pop(dialogContext);
                },
                child: Text(s.save),
              ),
            ],
          ),
    );
  }
}
