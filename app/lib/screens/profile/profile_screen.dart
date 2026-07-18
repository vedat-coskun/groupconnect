import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';
import 'profile_edit_screen.dart';
import 'settings_screen.dart';

/// Profile tab: view identity + entry to edit and to settings (FR-50).
/// Phone number is never shown (NFR-5).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final me = state.me;
    final role = state.roleOf(me);
    final tenant = state.activeTenant!;

    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                MemberAvatar(member: me, radius: 48),
                // PROTOTİP: profil fotoğrafı ekleme afişi (mock).
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
          const SizedBox(height: 12),
          Center(
            child: Text(
              me.fullName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Wrap(
              spacing: 8,
              children: [
                TagChip(label: state.roleName(role)),
                TagChip(label: tenant.name, icon: Icons.business_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileEditScreen(),
                    ),
                  ),
              icon: const Icon(Icons.edit_outlined),
              label: Text(s.editProfile),
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: s.memberNoLabel,
            value: me.memberNo,
          ),
          _InfoRow(
            icon: Icons.apartment_outlined,
            label: s.departmentLabel,
            value: me.department,
          ),
          _InfoRow(
            icon: Icons.workspace_premium_outlined,
            label: s.roleLabel,
            value: state.roleName(role),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(s.settingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
          ),
          const SizedBox(height: 24),
        ],
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
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Fotoğrafı Kaldır'),
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
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      dense: true,
    );
  }
}
