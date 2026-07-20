import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';
import 'settings_screen.dart';

/// Profile tab: view identity + (embedded) settings (FR-50). Phone number is
/// never shown (NFR-5).
///
/// Kimlik alanları (ad/üye no/bölüm/rol) admin'e aittir ve salt-okunurdur
/// (FR-58) — ayrı "Profili Düzenle" ekranı YOK (kullanıcı tercihi 2026-07-19):
/// zaten bu ekrandayız. Kullanıcının değiştirebildiği tek şey profil
/// fotoğrafıdır (prototip mock); bir değişiklik bekliyorsa üstte
/// "Değişiklikleri Kaydet / İptal Et" çubuğu belirir, yoksa görünmez.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Bekleyen (kaydedilmemiş) değişiklik var mı? Yalnız buysa Kaydet/İptal görünür.
  bool _dirty = false;

  void _markDirty() => setState(() => _dirty = true);

  void _save() {
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Değişiklikler kaydedildi.')),
    );
  }

  void _cancel() {
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Değişiklikler iptal edildi.')),
    );
  }

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
          // Değişiklik varken ÜSTTE Kaydet/İptal çubuğu (yoksa hiç çizilmez).
          if (_dirty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Değişiklikleri Kaydet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Değişiklikleri İptal Et'),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                MemberAvatar(member: me, radius: 48),
                // PROTOTİP: profil fotoğrafı ekleme afişi (mock). Seçim yapmak
                // "bekleyen değişiklik" sayılır → Kaydet/İptal çubuğu belirir.
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _showPhotoOptions,
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
                TagChip(label: tenant.name, icon: Icons.business_outlined),
                TagChip(label: state.roleName(role)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // "Ad SOYAD, Ünvan, Bölüm" satır düzenindeki sırayla (FR-94):
          // ünvan yalnız varsa gösterilir; rol ayrı bir rozet/alan olarak durur.
          if (me.title.isNotEmpty)
            _InfoRow(
              icon: Icons.school_outlined,
              label: s.titleLabel,
              value: me.title,
            ),
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
          // Ayarlar Profil'in altına gömülü (ayrı sayfa değil).
          const SettingsBody(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // PROTOTİP: profil fotoğrafı seçimi (mock). Bir seçenek seçmek bekleyen
  // değişiklik oluşturur → Kaydet/İptal çubuğu belirir.
  void _showPhotoOptions() {
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
                _markDirty();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(ctx);
                _markDirty();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Fotoğrafı Kaldır'),
              onTap: () {
                Navigator.pop(ctx);
                _markDirty();
              },
            ),
          ],
        ),
      ),
    );
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
