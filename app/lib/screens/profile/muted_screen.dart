import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/common.dart';

/// Manage muted conversations — unmute chats/groups (FR-49).
class MutedScreen extends StatelessWidget {
  const MutedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final muted = state.mutedConversations;

    return Scaffold(
      appBar: AppBar(title: Text(s.mutedTitle)),
      body:
          muted.isEmpty
              ? EmptyState(
                icon: Icons.notifications_active_outlined,
                title: s.mutedEmpty,
              )
              : ListView.separated(
                itemCount: muted.length,
                separatorBuilder:
                    (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) {
                  final c = muted[i];
                  return ListTile(
                    leading:
                        c.isGroup
                            ? GroupAvatar(group: c.group!)
                            : MemberAvatar(member: c.member!),
                    title: Text(
                      c.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(c.isGroup ? s.tabGroups : s.tabChats),
                    trailing: OutlinedButton(
                      onPressed: () {
                        final st = AppScope.of(context, listen: false);
                        if (c.isGroup) {
                          st.toggleGroupMute(c.group!.id);
                        } else {
                          st.toggleDmMute(c.member!.id);
                        }
                      },
                      child: Text(s.unmute),
                    ),
                  );
                },
              ),
    );
  }
}
