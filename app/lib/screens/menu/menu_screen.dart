import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../admin/admin_settings_screen.dart';
import '../groups/archive_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/settings_screen.dart';

/// "Menü" hub tab (deck MENU 01). Gathers Profil + secondary destinations in
/// one place so the bottom bar stays lean (Gruplar · Kişiler · Sohbetler ·
/// Menü). Detail/settings screens live one level down.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);

    void push(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: Text(s.tabMenu)),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(s.profileTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const ProfileScreen()),
          ),
          if (state.isMultiTenant)
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(s.switchTenant),
              subtitle: Text(state.activeTenant!.name),
              trailing: const Icon(Icons.chevron_right),
              // Baştaki kurum-seçim ekranına dön; seçim sonrası ana ekrana taze
              // girilir (menüye dönülmez).
              onTap:
                  () =>
                      AppScope.of(context, listen: false).startTenantSwitch(),
            ),

          const Divider(height: 16),
          // Arşiv: nadir kullanılan bir yönetim listesi — "Engellenenler"in
          // Ayarlar altında durması gibi, Gruplar sekmesini kalabalıklaştırmaz.
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: Text(s.archiveTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const ArchiveScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(s.settingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => push(const SettingsScreen()),
          ),
          // Yalnız yetkili rollere (akademisyen/yönetici/… ). Prototip: gerçek
          // sürümde Web Admin paneline taşınacak.
          if (state.isAuthority(state.me))
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text(s.adminSettingsTitle),
              subtitle: const Text('Prototip — Web Admin paneline taşınacak'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => push(const AdminSettingsScreen()),
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.about),
            onTap: () => _about(context),
          ),

          const Divider(height: 16),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              s.logout,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            // Onay sormadan doğrudan çık (kaybedilecek veri yok).
            onTap: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              AppScope.of(context, listen: false).logout();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _about(BuildContext context) {
    final s = context.s;
    showAboutDialog(
      context: context,
      applicationName: s.appName,
      applicationVersion: '0.1.0 (prototype)',
      children: [Text(s.aboutBody)],
    );
  }
}
