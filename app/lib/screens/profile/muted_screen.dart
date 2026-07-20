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
              // "Kutu kutu" + 393px güvenliği: özel Row, ad InfoBox'ta.
              : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: muted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, i) {
                  final c = muted[i];
                  final scheme = Theme.of(context).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                    child: Row(
                      children: [
                        c.isGroup
                            ? GroupAvatar(group: c.group!)
                            : MemberAvatar(member: c.member!),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InfoBox(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  c.isGroup ? s.tabGroups : s.tabChats,
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
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
