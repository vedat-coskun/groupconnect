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
              : ListView.separated(
                itemCount: blocked.length,
                separatorBuilder:
                    (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) {
                  final m = blocked[i];
                  final role = state.roleOf(m);
                  return ListTile(
                    leading: MemberAvatar(member: m),
                    title: Text(
                      m.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${state.roleName(role)} · ${m.department}',
                    ),
                    trailing: OutlinedButton(
                      onPressed:
                          () => AppScope.of(
                            context,
                            listen: false,
                          ).unblock(m.id),
                      child: Text(s.unblock),
                    ),
                  );
                },
              ),
    );
  }
}
