import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../state/app_scope.dart';
import '../../widgets/chat_widgets.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../contacts/contact_detail_screen.dart';

/// 1:1 text chat (FR-29, FR-32, FR-33). Text only — no attachments. If the
/// peer is not yet a contact, a banner notes that presence is hidden (FR-32).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.memberId, this.intro = false});

  final String memberId;

  /// True when opened as an "introduction message" from discovery (FR-32).
  final bool intro;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Message? _replyingTo;
  String get memberId => widget.memberId;
  bool get intro => widget.intro;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final member = state.td.member(memberId);
    if (member == null) {
      return const Scaffold(body: Center(child: Text('—')));
    }
    final role = state.roleOf(member);
    final messages = state.messagesOf(state.dmThread(memberId));
    // Matrisin doğrudan gördüğü kişi rehberdeymiş gibidir — şerit/intro yok.
    final isContact = state.treatAsContact(memberId);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactDetailScreen(memberId: memberId),
                ),
              ),
          child: Row(
            children: [
              MemberAvatar(member: member, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      state.roleName(role),
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
            tooltip: state.isDmMuted(memberId) ? s.unmute : s.mute,
            icon: Icon(
              state.isDmMuted(memberId)
                  ? Icons.notifications_off
                  : Icons.notifications_none,
            ),
            onPressed:
                () => AppScope.of(
                  context,
                  listen: false,
                ).toggleDmMute(memberId),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ContactDetailScreen(memberId: memberId),
                  ),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isContact)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.tertiaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                s.notInContactsYet,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child:
                messages.isEmpty
                    ? EmptyState(
                      icon: Icons.waving_hand_outlined,
                      title: member.fullName.split(' ').first,
                      subtitle: intro ? s.introHint : s.messageHint,
                    )
                    : MessageList(
                      messages: List.of(messages),
                      isGroup: false,
                      threadId: state.dmThread(memberId),
                      myId: state.td.myId,
                      resolveSender: (id) => state.td.member(id),
                      onReply: (m) => setState(() => _replyingTo = m),
                    ),
          ),
          if (_replyingTo != null)
            _ReplyBar(
              name:
                  _replyingTo!.senderId == state.td.myId
                      ? s.you
                      : member.namePlusTitle,
              text: _replyingTo!.text,
              onCancel: () => setState(() => _replyingTo = null),
            ),
          MessageComposer(
            hint: intro ? s.introHint : s.messageHint,
            onSend: (text) {
              AppScope.of(context, listen: false).sendDm(
                memberId,
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
