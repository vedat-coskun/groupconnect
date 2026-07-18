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
              : ListView.separated(
                itemCount: groups.length,
                separatorBuilder:
                    (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) {
                  final g = groups[i];
                  return ListTile(
                    leading: GroupAvatar(group: g, radius: 22),
                    title: Text(
                      g.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      s.memberCount(g.memberIds.length),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.unarchive_outlined, size: 18),
                      label: Text(s.restore),
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        AppScope.of(context, listen: false).restoreGroup(g.id);
                        messenger.showSnackBar(
                          SnackBar(content: Text(s.groupRestored)),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
