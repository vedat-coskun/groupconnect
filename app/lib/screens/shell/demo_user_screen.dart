import 'package:flutter/material.dart';

import '../../state/app_scope.dart';
import '../../widgets/common.dart';

/// GELİŞTİRME (yalnız debug) — alt çubuğun en solundaki "Demo" sekmesi.
///
/// Tek simülatörde iki-kişilik akışları test etmek için: üç demo kimliği
/// arasında ANINDA geçiş (telefon/OTP yok). Paylaşılan veri (mesajlar/gruplar)
/// tek bellekte olduğundan, bir kullanıcı bir işlem yapıp diğerine geçince
/// sonucu görür. Bkz. [AppState.switchDemoUser]. Release'de HİÇ gösterilmez
/// (home_shell yalnız kDebugMode'da bu sekmeyi ekler).
class DemoUserScreen extends StatelessWidget {
  const DemoUserScreen({super.key});

  // (telefon, ad, rol etiketi, uni'deki myId).
  static const _users = <(String, String, String, String)>[
    ('5555555501', 'Vedat Coşkun', 'Akademisyen', 'u_me'),
    ('5555555502', 'Suden Test', 'Öğrenci', 'u_zeynep'),
    ('5555555503', 'Arda Test', 'Öğrenci', 'u_can'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final currentMyId = state.activeTenant != null ? state.td.myId : null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BoxedPageHeader(title: 'Demo'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Geliştirme aracı: kimliği anında değiştir. Paylaşılan veri '
                '(mesaj/grup) ortak olduğundan, biri işlem yapınca diğerine '
                'geçince görürsün.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  for (final (phone, name, role, myId) in _users)
                    _UserButton(
                      name: name,
                      role: role,
                      active: myId == currentMyId,
                      onTap:
                          () => AppScope.of(
                            context,
                            listen: false,
                          ).switchDemoUser(phone),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek demo kullanıcı butonu: aktif olan dolgulu (secondaryContainer) +
/// onay işareti; diğerleri hafif yüzey kutusu.
class _UserButton extends StatelessWidget {
  const _UserButton({
    required this.name,
    required this.role,
    required this.active,
    required this.onTap,
  });

  final String name;
  final String role;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = active ? scheme.onSecondaryContainer : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: active ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: active ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  active ? Icons.person : Icons.person_outline,
                  color: fg,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        role,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (active)
                  Icon(Icons.check_circle, color: scheme.onSecondaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
