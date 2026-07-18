import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import 'common.dart';

/// A single chat bubble. Mine on the right, others on the left. In group
/// threads the sender's name is shown above others' bubbles.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.senderName,
    this.senderColor,
    this.quotedName,
    this.quotedText,
  });

  final Message message;
  final bool isMine;
  final String? senderName;
  final Color? senderColor;

  /// Yanıtlanan mesajın göndereni ve metni (varsa) — balonda alıntı kutusu.
  final String? quotedName;
  final String? quotedText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isMine ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = isMine ? scheme.onPrimary : scheme.onSurface;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  senderName!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: senderColor ?? scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (quotedText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.08),
                  border: Border(
                    left: BorderSide(color: fg.withValues(alpha: 0.5), width: 3),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quotedName != null)
                      Text(
                        quotedName!,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      quotedText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Text(message.text, style: TextStyle(color: fg, fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              message.edited
                  ? '${formatTime(message.time)} · ${context.s.editedTag}'
                  : formatTime(message.time),
              style: TextStyle(
                color: fg.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable list of messages. Auto-scrolls to the newest message when the
/// list grows (e.g. after sending).
class MessageList extends StatefulWidget {
  const MessageList({
    super.key,
    required this.messages,
    required this.isGroup,
    required this.threadId,
    this.resolveSender,
    this.onReply,
  });

  final List<Message> messages;
  final bool isGroup;

  /// Düzenle/Sil işlemleri için mesajın yaşadığı dizi.
  final String threadId;
  final Member? Function(String senderId)? resolveSender;

  /// Menüden "Yanıtla" seçilince ekrana haber verir (composer alıntı çubuğu).
  final void Function(Message message)? onReply;

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    }
  }

  void _jumpToBottom() {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const SizedBox.expand();
    }
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: widget.messages.length,
      itemBuilder: (context, i) {
        final m = widget.messages[i];
        final isMine = m.senderId == meId;
        String? name;
        Color? color;
        if (widget.isGroup && !isMine) {
          final sender = widget.resolveSender?.call(m.senderId);
          name = sender?.namePlusTitle;
          color = sender?.avatarColor;
        }
        // Alıntı (yanıtlanan mesaj) çözümü — aynı dizide aranır.
        String? qName;
        String? qText;
        if (m.replyToId != null) {
          for (final q in widget.messages) {
            if (q.id == m.replyToId) {
              qText = q.text;
              qName =
                  q.senderId == meId
                      ? context.s.you
                      : (widget.resolveSender
                              ?.call(q.senderId)
                              ?.namePlusTitle ??
                          '');
              break;
            }
          }
        }
        return GestureDetector(
          // Mobilde uzun bas, masaüstünde sağ tık — aynı menü.
          onLongPress: () => _showMenu(m, isMine),
          onSecondaryTap: () => _showMenu(m, isMine),
          child: MessageBubble(
            message: m,
            isMine: isMine,
            senderName: name,
            senderColor: color,
            quotedName: qName,
            quotedText: qText,
          ),
        );
      },
    );
  }

  /// Mesaj menüsü — kurum sahibi hükmü: KENDİ mesajımda Düzenle / Yanıtla /
  /// Kopyala / Sil; GELEN mesajda yalnız Yanıtla / Sil.
  void _showMenu(Message m, bool isMine) {
    final s = context.s;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMine)
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(s.edit),
                    onTap: () {
                      Navigator.pop(ctx);
                      _editDialog(m);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.reply_outlined),
                  title: Text(s.reply),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onReply?.call(m);
                  },
                ),
                if (isMine)
                  ListTile(
                    leading: const Icon(Icons.copy_outlined),
                    title: Text(s.copy),
                    onTap: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(ClipboardData(text: m.text));
                    },
                  ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                  title: Text(
                    s.delete,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                  // Onaysız (NFR-18) — prototipte yerel silme.
                  onTap: () {
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    AppScope.of(context, listen: false)
                        .deleteMessage(widget.threadId, m.id);
                    messenger.showSnackBar(
                      SnackBar(content: Text(s.messageDeleted)),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  /// Düzenleme — veri girişi diyaloğu (form; NFR-18'in kapsamı dışında).
  void _editDialog(Message m) {
    final s = context.s;
    final controller = TextEditingController(text: m.text);
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(s.edit),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: 1,
              maxLines: 5,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: () {
                  AppScope.of(context, listen: false).editMessage(
                    widget.threadId,
                    m.id,
                    controller.text,
                  );
                  Navigator.pop(ctx);
                },
                child: Text(s.save),
              ),
            ],
          ),
    );
  }
}

/// Text-only message composer. Deliberately has **no** attachment / camera /
/// location controls (FR-33, NFR-11).
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.hint,
    required this.onSend,
  });

  final String hint;
  final ValueChanged<String> onSend;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final can = _controller.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  fillColor: scheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _canSend ? _send : null,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                minimumSize: const Size(52, 52),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.send_rounded, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
