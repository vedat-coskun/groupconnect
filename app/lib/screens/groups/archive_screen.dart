import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';

/// Menü → Arşiv (FR-40): grubu kuran üyenin arşivlediği özel gruplar.
///
/// Üründe **kalıcı silme yoktur**: "Grubu Arşivle" grubu ve mesaj dizisini
/// korur, yalnız herkesin listelerinden kaldırır. Geri alabilen tek kişi grubu
/// kuran üyedir — bu ekran da onun içindir. Arşivleme geri alınabilir olduğu
/// için hiçbir aşamada "Emin misin?" onayı sorulmaz.
///
/// Nadir kullanılan bir **yönetim listesi** olduğu için Gruplar sekmesinde
/// değil Menü'de durur — "Engellenenler"in Ayarlar altında durması gibi.
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final groups = state.archivedGroups;

    return Scaffold(
      appBar: AppBar(title: Text(s.archiveTitle)),
      body:
          groups.isEmpty
              ? EmptyState(
                icon: Icons.archive_outlined,
                title: s.archiveEmpty,
                subtitle: s.archiveHint,
              )
              // "Kutu kutu" + 393px güvenliği: ListTile (geniş leading+trailing
              // = taşma riski) yerine özel Row; ad+üye sayısı InfoBox'ta.
              : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, i) {
                  final g = groups[i];
                  final scheme = Theme.of(context).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InfoBox(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  s.memberCount(g.memberIds.length),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          icon: const Icon(Icons.unarchive_outlined, size: 18),
                          label: Text(s.restore),
                          onPressed: () {
                            final messenger = ScaffoldMessenger.of(context);
                            AppScope.of(
                              context,
                              listen: false,
                            ).restoreGroup(g.id);
                            messenger.showSnackBar(
                              SnackBar(content: Text(s.groupRestored)),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
