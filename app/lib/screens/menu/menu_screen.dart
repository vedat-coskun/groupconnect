import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';
import '../admin/admin_settings_screen.dart';
import '../groups/archive_screen.dart';
import '../profile/profile_screen.dart';

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

    // "Kutu kutu" tasarım pilotu (kullanıcı tercihi, Atlas örneği): düz liste
    // yerine 2 sütunlu RENKLİ KART grid'i. Her kart: ikon üst-solda, chevron
    // üst-sağda, başlık (+alt yazı) altta. Renkler PASTEL (kullanıcı tercihi
    // 2026-07-19) — açık zeminde metin/ikon koyu-aynı-ton okunur.
    final cards = <_MenuCard>[
      _MenuCard(
        icon: Icons.person_outline,
        title: s.profileTitle,
        color: const Color(0xFFC7D9F5),
        fg: const Color(0xFF2A4A7A),
        onTap: () => push(const ProfileScreen()),
      ),
      if (state.isMultiTenant)
        _MenuCard(
          icon: Icons.swap_horiz,
          title: s.switchTenant,
          subtitle: state.activeTenant!.name,
          color: const Color(0xFFBFE0D5),
          fg: const Color(0xFF235C4C),
          // Baştaki kurum-seçim ekranına dön; seçim sonrası ana ekrana taze
          // girilir (menüye dönülmez).
          onTap: () => AppScope.of(context, listen: false).startTenantSwitch(),
        ),
      // Arşiv: nadir kullanılan bir yönetim listesi — "Engellenenler"in
      // Ayarlar altında durması gibi, Gruplar sekmesini kalabalıklaştırmaz.
      _MenuCard(
        icon: Icons.archive_outlined,
        title: s.archiveTitle,
        color: const Color(0xFFC6E4DD),
        fg: const Color(0xFF2C5C52),
        onTap: () => push(const ArchiveScreen()),
      ),
      // Ayarlar kartı KALDIRILDI (kullanıcı tercihi 2026-07-19): ayarlar artık
      // Profil sayfasının altına gömülü, ayrı sayfa değil.
      // Kişiden bağımsız (kullanıcı hükmü): gerçek üründe ayrı bir Web
      // Admin paneli/aktörüdür (mobil rol sistemine hiç girmez), rol
      // gözetmeden hangi test kimliğiyle girilirse girilsin erişilebilir.
      _MenuCard(
        icon: Icons.admin_panel_settings_outlined,
        title: s.adminSettingsTitle,
        subtitle: 'Prototip — Web Admin paneline taşınacak',
        color: const Color(0xFFCFD7E4),
        fg: const Color(0xFF3A465C),
        onTap: () => push(const AdminSettingsScreen()),
      ),
      _MenuCard(
        icon: Icons.info_outline,
        title: s.about,
        color: const Color(0xFFEADCBE),
        fg: const Color(0xFF6E5426),
        onTap: () => _about(context),
      ),
      _MenuCard(
        icon: Icons.logout,
        title: s.logout,
        color: const Color(0xFFF0CDCA),
        fg: const Color(0xFF8A3330),
        // Onay sormadan doğrudan çık (kaybedilecek veri yok).
        onTap: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          AppScope.of(context, listen: false).logout();
        },
      ),
    ];

    // AppBar yerine tam genişlikte BAŞLIK KUTUSU (kullanıcı tercihi): pastel
    // kartlardan ayrışsın diye dolgulu-koyu (primary) bir bant — açık gride
    // karşı belirgin başlık okuması.
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoxedPageHeader(title: s.tabMenu),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: cards,
              ),
            ),
          ],
        ),
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

/// Atlas örneğindeki gibi renkli menü kartı: ikon üst-solda, chevron üst-sağda
/// yarı saydam dairede, başlık (+alt yazı) altta. Pastel zemin ([color]) +
/// koyu-aynı-ton ön plan ([fg]) — açık kartta metin/ikon okunur kalır.
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.fg,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chevron kaldırıldı (gereksiz — kullanıcı hükmü): yalnız ikon.
              Icon(icon, color: fg, size: 30),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg.withValues(alpha: .78),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
