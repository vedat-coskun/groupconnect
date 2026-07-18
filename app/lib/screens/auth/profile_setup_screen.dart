import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';

/// First-login profile setup (FR-9, FR-50). Pre-filled from the admin-
/// provisioned directory record; the user confirms/edits their visible
/// identity. Phone number is never shown here (NFR-5).
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final TextEditingController _name;
  late final TextEditingController _memberNo;
  late final TextEditingController _department;
  late String _roleId;

  @override
  void initState() {
    super.initState();
    final me = AppScope.of(context, listen: false).me;
    _name = TextEditingController(text: me.fullName);
    _memberNo = TextEditingController(text: me.memberNo);
    _department = TextEditingController(text: me.department);
    _roleId = me.roleId;
  }

  @override
  void dispose() {
    _name.dispose();
    _memberNo.dispose();
    _department.dispose();
    super.dispose();
  }

  void _save() {
    AppScope.of(context, listen: false).completeProfileSetup(
      fullName: _name.text,
      memberNo: _memberNo.text,
      department: _department.text,
      roleId: _roleId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.profileSetupTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      size: 44,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  // PROTOTİP: profil fotoğrafı ekleme afişi (mock) — Profil
                  // ekranındaki kamera rozetiyle aynı desen.
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: scheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _showPhotoOptions(context),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Kimlik bilgileri admin tarafından girilir — kullanıcı görüntüler,
            // değiştiremez (tümü disabled). Kullanıcı yalnızca fotoğraf ekler.
            _Field(label: s.fullName, controller: _name, enabled: false),
            const SizedBox(height: 16),
            _Field(
              label: s.memberNo,
              controller: _memberNo,
              keyboardType: TextInputType.text,
              enabled: false,
            ),
            const SizedBox(height: 16),
            _Field(label: s.department, controller: _department, enabled: false),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _roleId,
              decoration: InputDecoration(labelText: s.role),
              items: [
                for (final r in state.tenantRoles)
                  DropdownMenuItem(
                    value: r.id,
                    child: Text(state.roleName(r)),
                  ),
              ],
              // Rol admin tarafından atanır — kullanıcı değiştiremez (disabled).
              onChanged: null,
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: _save, child: Text(s.done)),
          ],
        ),
      ),
    );
  }
}

// PROTOTİP: profil fotoğrafı seçimi (mock). Gerçek uygulamada image_picker vb.
void _showPhotoOptions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
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
      content: Text('Prototip: gerçek uygulamada profil fotoğrafı seçilir.'),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(labelText: label),
    );
  }
}
