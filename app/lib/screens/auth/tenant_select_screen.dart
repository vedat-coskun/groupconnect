import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';

/// Multi-tenant selection (FR-6, FR-7). Shown only when the phone belongs to
/// more than one organization AND no remembered org is set. "Bu kurumu
/// hatırla" persists the choice so later logins skip this screen (FR-8); it
/// stays changeable from Menü → Kurum Değiştir.
class TenantSelectScreen extends StatefulWidget {
  const TenantSelectScreen({super.key});

  @override
  State<TenantSelectScreen> createState() => _TenantSelectScreenState();
}

class _TenantSelectScreenState extends State<TenantSelectScreen> {
  late bool _remember;

  @override
  void initState() {
    super.initState();
    // Kurum Değiştir yoluyla gelindiyse ve "hatırla" zaten aktifse kutu işaretli
    // gelsin ki yeni seçim hatırlanan kurumu güncellesin (ilk girişte: kapalı).
    _remember = AppScope.of(context, listen: false).hasRememberedTenant;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.tenantSelectTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.tenantSelectSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              for (final t in state.loginTenants)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.business_outlined,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      t.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap:
                        () => AppScope.of(
                          context,
                          listen: false,
                        ).selectTenant(t.id, remember: _remember),
                  ),
                ),
              const SizedBox(height: 4),
              CheckboxListTile(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(s.rememberTenant),
                subtitle: Text(s.rememberTenantHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
