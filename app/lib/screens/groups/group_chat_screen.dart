import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/chat_widgets.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import 'group_detail_screen.dart';

/// Group text chat (FR-43, FR-44). Text only — no attachments (FR-33).
class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  Message? _replyingTo;
  String get groupId => widget.groupId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final group = state.td.group(groupId);
    if (group == null) {
      return const Scaffold(body: Center(child: Text('—')));
    }
    final messages = state.messagesOf('grp:$groupId');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupDetailScreen(groupId: groupId),
                ),
              ),
          child: Row(
            children: [
              GroupAvatar(group: group, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      s.memberCount(group.memberIds.length),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GroupDetailScreen(groupId: groupId),
                  ),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                messages.isEmpty
                    ? EmptyState(
                      icon: Icons.forum_outlined,
                      title: group.name,
                      subtitle: s.messageHint,
                    )
                    : MessageList(
                      messages: List.of(messages),
                      isGroup: true,
                      threadId: 'grp:$groupId',
                      resolveSender: (id) => state.td.member(id),
                      onReply: (m) => setState(() => _replyingTo = m),
                    ),
          ),
          if (_replyingTo != null)
            _ReplyBar(
              name:
                  _replyingTo!.senderId == meId
                      ? s.you
                      : (state.td.member(_replyingTo!.senderId)?.namePlusTitle ??
                          ''),
              text: _replyingTo!.text,
              onCancel: () => setState(() => _replyingTo = null),
            ),
          MessageComposer(
            hint: s.messageHint,
            onSend: (text) {
              AppScope.of(context, listen: false).sendGroupMessage(
                groupId,
                text,
                replyToId: _replyingTo?.id,
              );
              if (_replyingTo != null) setState(() => _replyingTo = null);
            },
          ),
        ],
      ),
    );
  }
}

/// Composer üstündeki "yanıtlıyorsun" çubuğu — X ile vazgeçilir.
class _ReplyBar extends StatelessWidget {
  const _ReplyBar({required this.name, required this.text, required this.onCancel});

  final String name;
  final String text;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
