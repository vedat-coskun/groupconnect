import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/enums.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'blocked_screen.dart';
import 'muted_screen.dart';

/// Settings (FR-49, FR-51, FR-52, FR-53, FR-8, FR-11): visibility, add-policy,
/// blocked list, muted conversations, language, switch organization, logout.
///
/// Ayrı bir sayfa olarak da açılabilir (SettingsScreen) ama asıl kullanım
/// Profil sayfasının ALTINA gömülüdür (kullanıcı tercihi 2026-07-19): gövde
/// [SettingsBody]'de, kaydırma dışarıdan gelir (kendi ListView'i yok).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(children: const [SettingsBody()]),
    );
  }
}

/// Ayarların gövdesi (Scaffold/AppBar YOK) — Profil sayfasının ListView'ine
/// gömülür; kendi kaydırmasını yaratmaz (Column).
class SettingsBody extends StatelessWidget {
  const SettingsBody({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final me = state.me;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          _sectionHeader(context, s.account),

          // MemberVisibility (FR-16, FR-51) — başlıksız, yalnız segment
          // (kurum sahibi: "yalnızca böyle bir bilgi yeterli").
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<MemberVisibility>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13)),
                ),
                segments: [
                  ButtonSegment(
                    value: MemberVisibility.visible,
                    label: Text(s.visible),
                  ),
                  ButtonSegment(
                    value: MemberVisibility.hidden,
                    label: Text(s.hidden),
                  ),
                ],
                selected: {me.visibility},
                onSelectionChanged:
                    (v) => AppScope.of(
                      context,
                      listen: false,
                    ).setVisibility(v.first),
              ),
            ),
          ),

          // Add-to-contacts policy (FR-52)
          // Add-to-contacts policy (FR-52) — label on top, control full-width
          // below (açıklama notu kaldırıldı).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AddPolicy>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      textStyle:
                          WidgetStatePropertyAll(TextStyle(fontSize: 13)),
                    ),
                    segments: [
                      ButtonSegment(
                        value: AddPolicy.everyone,
                        label: Text(s.policyEveryone),
                      ),
                      ButtonSegment(
                        value: AddPolicy.approval,
                        label: Text(s.policyApproval),
                      ),
                    ],
                    selected: {me.addPolicy},
                    onSelectionChanged:
                        (v) => AppScope.of(
                          context,
                          listen: false,
                        ).setAddPolicy(v.first),
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.block),
            // Sayı başlıkta; boş-durum alt yazısı gereksiz (kurum sahibi).
            title: Text(
              '${s.blockedTitle} (${state.blockedMembers.length})',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BlockedScreen()),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_off_outlined),
            title: Text(
              '${s.mutedTitle} (${state.mutedConversations.length})',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MutedScreen()),
                ),
          ),

          const Divider(height: 16),
          _sectionHeader(context, s.settingsTitle),

          // Language (FR-11) — başlıksız; dil adları çevrilmez.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<AppLanguage>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: AppLanguage.tr, label: Text('Türkçe')),
                  ButtonSegment(value: AppLanguage.en, label: Text('English')),
                ],
                selected: {state.language},
                onSelectionChanged:
                    (v) => AppScope.of(
                      context,
                      listen: false,
                    ).setLanguage(v.first),
              ),
            ),
          ),

          // Switch organization — only when registered to multiple (FR-8)
          if (state.isMultiTenant)
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(s.switchTenant),
              subtitle: Text(state.activeTenant!.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _switchTenant(context),
            ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.about),
            onTap: () => _about(context, s),
          ),

          const Divider(height: 16),
          // Görünüm — kişisel tercih; admin'in KİLİTLEmediği eksenler burada
          // değiştirilir, kilitliler salt-okur bilgiyle gösterilir.
          _sectionHeader(context, 'Görünüm'),
          _AppearanceUser(state: state),

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
            onTap: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              AppScope.of(context, listen: false).logout();
            },
          ),
          const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      context.upper(title),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1,
      ),
    ),
  );

  void _switchTenant(BuildContext context) {
    final state = AppScope.of(context, listen: false);
    final s = context.s;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    s.switchTenant,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                for (final t in state.loginTenants)
                  ListTile(
                    leading: Icon(
                      t.id == state.activeTenant!.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(t.name),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      state.switchTenant(t.id);
                      // Return to the shell so the new org's home is shown
                      // (or the profile-setup phase, if that tenant is new).
                      if (context.mounted) {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      }
                    },
                  ),
              ],
            ),
          ),
    );
  }

  void _about(BuildContext context, AppStrings s) {
    showAboutDialog(
      context: context,
      applicationName: s.appName,
      applicationVersion: '0.1.0 (prototype)',
      children: [Text(s.aboutBody)],
    );
  }
}

/// Kullanıcı görünüm bölümü: admin'in kilitlemediği eksenleri kişiselleştirir.
/// Etkin değer app_state.appearance'tan; kilitli eksen salt-okur "kurum
/// belirledi" bilgisiyle gösterilir (kullanıcı tercihi 2026-07-19).
class _AppearanceUser extends StatelessWidget {
  const _AppearanceUser({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final eff = state.appearance;

    Widget lockedNote() => Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Kurum belirledi',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arkaplan rengi.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              const Text('Arkaplan rengi'),
              if (!state.canUserSetAccent) lockedNote(),
            ],
          ),
        ),
        if (state.canUserSetAccent)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final c in kAccentPalette)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => state.setUserAccent(c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                eff.accent.toARGB32() == c.toARGB32()
                                    ? scheme.onSurface
                                    : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child:
                            eff.accent.toARGB32() == c.toARGB32()
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                                : null,
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: eff.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        const SizedBox(height: 8),

        // Yazı boyutu.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              const Text('Yazı boyutu'),
              if (!state.canUserSetTextScale) lockedNote(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final sc in AppTextScale.values)
                ChoiceChip(
                  label: Text(sc.labelTr),
                  selected: eff.scale == sc,
                  onSelected:
                      state.canUserSetTextScale
                          ? (_) => state.setUserTextScale(sc)
                          : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Yazı tipi.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              const Text('Yazı tipi'),
              if (!state.canUserSetFont) lockedNote(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final (label, family) in kFontOptions)
                ChoiceChip(
                  label: Text(label, style: TextStyle(fontFamily: family)),
                  selected: eff.fontFamily == family,
                  onSelected:
                      state.canUserSetFont
                          ? (_) => state.setUserFont(family)
                          : null,
                ),
            ],
          ),
        ),
        // Override'ları sıfırla (kurum varsayılanına dön) — yalnız değiştirilebilir
        // eksen varken anlamlı.
        if (state.canUserSetAccent ||
            state.canUserSetTextScale ||
            state.canUserSetFont)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextButton.icon(
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Kurum varsayılanına dön'),
              onPressed: () {
                if (state.canUserSetAccent) state.setUserAccent(null);
                if (state.canUserSetTextScale) state.setUserTextScale(null);
                if (state.canUserSetFont) state.setUserFont(null);
              },
            ),
          ),
      ],
    );
  }
}
