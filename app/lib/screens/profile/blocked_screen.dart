import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';

/// Manage blocked members — view and unblock (FR-18, FR-53).
class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final blocked = state.blockedMembers;

    return Scaffold(
      appBar: AppBar(title: Text(s.blockedTitle)),
      body:
          blocked.isEmpty
              ? EmptyState(
                icon: Icons.block,
                title: s.blockedEmpty,
              )
              // "Kutu kutu" + 393px güvenliği: özel Row, ad InfoBox'ta.
              : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: blocked.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, i) {
                  final m = blocked[i];
                  final role = state.roleOf(m);
                  final scheme = Theme.of(context).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                    child: Row(
                      children: [
                        MemberAvatar(member: m),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InfoBox(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${state.roleName(role)} · ${m.department}',
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
                        OutlinedButton(
                          onPressed:
                              () => AppScope.of(
                                context,
                                listen: false,
                              ).unblock(m.id),
                          child: Text(s.unblock),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
