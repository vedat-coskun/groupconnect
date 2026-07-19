import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';
import 'contact_picker_screen.dart';
import 'group_detail_screen.dart';

/// Create a Private Group (FR-37, FR-41). Optionally starts from a contact
/// (common-group flow, FR-45) who is auto-included as the first invited member.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key, this.preselectedMemberId});

  /// When set, this contact is included automatically (FR-45).
  final String? preselectedMemberId;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

// PROTOTİP: grup fotoğrafı seçimi (mock) — Profil'deki desenin aynısı.
// Gerçek uygulamada image_picker vb. ile seçilir.
void _showPhotoOptions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder:
        (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Fotoğraf Çek'),
                onTap: () {
                  Navigator.pop(ctx);
                  _photoStub(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(ctx);
                  _photoStub(context);
                },
              ),
            ],
          ),
        ),
  );
}

void _photoStub(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Prototip: gerçek uygulamada grup fotoğrafı seçilir.'),
    ),
  );
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _inviteMessage = TextEditingController();
  final List<String> _invited = [];

  /// FR-81: kapalı varsayılan — açıklık bilinçli bir seçim olsun.
  bool _isOpen = false;

  /// FR-90: varsayılan yalnız yönetici yazar (kullanıcı hükmü).
  bool _membersCanWrite = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedMemberId != null) {
      _invited.add(widget.preselectedMemberId!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _inviteMessage.dispose();
    super.dispose();
  }

  bool get _canCreate => _name.text.trim().isNotEmpty;

  Future<void> _pickInvitees() async {
    final picked = await pickContacts(
      context,
      title: context.s.inviteMembers,
      excludeIds: _invited.toSet(),
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() => _invited.addAll(picked));
    }
  }

  void _create() {
    final state = AppScope.of(context, listen: false);
    // The preselected contact (FR-45) joins immediately; others are invited.
    final autoInclude = <String>[
      if (widget.preselectedMemberId != null) widget.preselectedMemberId!,
    ];
    final invited =
        _invited.where((id) => !autoInclude.contains(id)).toList();
    final group = state.createPrivateGroup(
      name: _name.text,
      description: _description.text,
      inviteMessage: _inviteMessage.text,
      invitedIds: invited,
      autoIncludeIds: autoInclude,
      isOpen: _isOpen,
      membersCanWrite: _membersCanWrite,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(groupId: group.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.createGroupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Grup fotoğrafı — Profil'deki kamera rozetli avatar deseni (mock).
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      Theme.of(context).colorScheme.tertiaryContainer,
                  child: Icon(
                    Icons.groups_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _showPhotoOptions(context),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: s.groupName),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(labelText: s.groupDescription),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inviteMessage,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(labelText: s.groupInviteMessage),
          ),
          // Not: Özel gruplarda hiyerarşi yok (düz). Hiyerarşi yalnız kurumsal
          // gruplarda ve admin tarafından tanımlanır.
          const SizedBox(height: 20),
          Text(
            s.groupAccessLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          // FR-81: kapalı mı, herkese açık mı? Açıklık daveti DIŞLAMAZ — her
          // iki durumda da davet gönderilebilir (aşağıdaki bölüm).
          RadioListTile<bool>(
            value: false,
            groupValue: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v!),
            contentPadding: EdgeInsets.zero,
            title: Text(s.closedGroup),
            subtitle: Text(s.closedGroupHint),
          ),
          RadioListTile<bool>(
            value: true,
            groupValue: _isOpen,
            onChanged: (v) => setState(() => _isOpen = v!),
            contentPadding: EdgeInsets.zero,
            title: Text(s.openGroup),
            subtitle: Text(s.openGroupHint),
          ),
          const SizedBox(height: 20),
          // FR-90: yazma yetkisi kuruluşta seçilir (varsayılan yalnız yönetici);
          // sonra Grup Bilgisi'nden değiştirilebilir. Yönetici (kurucu) her
          // durumda yazar; bu anahtar diğer üyeleri etkiler.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.membersCanWriteLabel),
            value: _membersCanWrite,
            onChanged: (v) => setState(() => _membersCanWrite = v),
          ),
          const SizedBox(height: 20),
          Text(
            s.inviteMembers,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_invited.isEmpty)
            Text(
              s.contactsEmptyHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in _invited)
                  if (state.td.member(id) != null)
                    InputChip(
                      avatar: MemberAvatar(
                        member: state.td.member(id)!,
                        radius: 12,
                      ),
                      label: Text(state.td.member(id)!.fullName),
                      onDeleted:
                          id == widget.preselectedMemberId
                              ? null
                              : () => setState(() => _invited.remove(id)),
                    ),
              ],
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickInvitees,
            icon: const Icon(Icons.person_add_alt),
            label: Text(s.inviteMembers),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _canCreate ? _create : null,
            icon: const Icon(Icons.check),
            label: Text(s.create),
          ),
        ],
      ),
    );
  }
}
