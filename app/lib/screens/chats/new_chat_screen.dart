import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../groups/group_chat_screen.dart';
import 'chat_screen.dart';

/// "Yeni Sohbet" (FR-29/FR-30 + kurum sahibi hükmü):
/// - **EN ÜSTTE mesaj yazma alanı**, altında **isimle arama**, altında
///   **HERKES** (matris) kategorilere göre, **solda checkbox**.
/// - Sıra serbesttir: önce yaz sonra seç, önce seç sonra yaz, yazarken seç.
/// - **1 kişi** seçiliyken gönder → birebir sohbet. **Birden çok kişi** →
///   OTOMATİK yeni **Kapalı Grup**; adı ilk adlardan kurulur: "Vedat & Arda",
///   "Vedat & Arda & Ayşe", "Vedat & Arda & Ayşe ..." (ben + ilk iki kişi,
///   fazlası "...").
/// - "Özel Grup Yarat" kısayolu bilinçli olarak YOKTUR — çoklu seçim zaten
///   grup kurar; adlı/fotoğraflı kalıcı grup isteyen Gruplar'daki "+"ı kullanır.
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _message = TextEditingController();
  String _query = '';
  final Set<String> _selected = {};
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _message.addListener(() {
      final can = _message.text.trim().isNotEmpty;
      if (can != _canSend) setState(() => _canSend = can);
    });
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  /// Otomatik grup adı — kurum sahibi hükmü: ben + ilk iki seçilenin ADI,
  /// "&" ile; daha fazlası varsa sona "...".
  String _autoName(AppState state, List<Member> others) {
    String first(String n) => n.trim().split(RegExp(r'\s+')).first;
    final names = [
      first(state.me.fullName),
      ...others.take(2).map((m) => first(m.fullName)),
    ];
    var name = names.join(' & ');
    if (others.length > 2) name = '$name ...';
    return name;
  }

  void _send() {
    final text = _message.text.trim();
    if (text.isEmpty || _selected.isEmpty) return;
    final state = AppScope.of(context, listen: false);

    if (_selected.length == 1) {
      final id = _selected.first;
      state.sendDm(id, text);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatScreen(memberId: id)),
      );
      return;
    }

    // Çoklu seçim = otomatik yeni Kapalı Grup. Seçilenler DOĞRUDAN üyedir
    // (FR-45 emsali) — davet beklenmez, mesaj anında herkese gider; seçim
    // zaten HERKES'ten (matris) yapıldığı için rıza modeliyle tutarlıdır.
    final others =
        _selected
            .map((id) => state.td.member(id))
            .whereType<Member>()
            .toList();
    final g = state.createPrivateGroup(
      name: _autoName(state, others),
      description: '',
      inviteMessage: '',
      autoIncludeIds: _selected.toList(),
    );
    state.sendGroupMessage(g.id, text);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: g.id)),
    );
  }

  Widget _personRow(Member m) {
    return CheckboxListTile(
      value: _selected.contains(m.id),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (v) {
        setState(() {
          if (v == true) {
            _selected.add(m.id);
          } else {
            _selected.remove(m.id);
          }
        });
      },
      secondary: MemberAvatar(member: m),
      // İsim düzeni tek satır: "Ad SOYAD, Ünvan, Bölüm [rakam]".
      title: Text.rich(
        m.rowLabelSpan(context),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final q = _query.trim().toLowerCase();
    final people =
        state.everyoneVisible
            .where(
              (m) =>
                  q.isEmpty ||
                  '${m.fullName} ${m.memberNo}'.toLowerCase().contains(q),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.newChatTitle)),
      body: Column(
        children: [
          // 1) Mesaj — gönder, yalnız metin + en az bir kişi varken aktif.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _message,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: s.messageHint,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed:
                      (_canSend && _selected.isNotEmpty) ? _send : null,
                ),
              ),
            ),
          ),
          // 2) İsimle arama.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: '${s.fullName} · ${s.memberNoLabel}',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          // 3) HERKES — kategorilere göre, solda checkbox, favoriler üstte.
          Expanded(
            child:
                people.isEmpty
                    ? Center(child: Text(s.noResults))
                    : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: roleSections(
                        context: context,
                        members: people,
                        roles: state.tenantRoles,
                        roleName: state.roleName,
                        header: (t) => RoleHeader(t),
                        otherLabel: s.contactsTitle,
                        pinned: (m) => state.isFavorite(m.id),
                        row: _personRow,
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
