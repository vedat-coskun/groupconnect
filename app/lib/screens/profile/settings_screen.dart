import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/enums.dart';
import '../../state/app_scope.dart';
import 'blocked_screen.dart';
import 'muted_screen.dart';

/// Settings (FR-49, FR-51, FR-52, FR-53, FR-8, FR-11): visibility, add-policy,
/// blocked list, muted conversations, language, switch organization, logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final me = state.me;

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
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
      ),
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
