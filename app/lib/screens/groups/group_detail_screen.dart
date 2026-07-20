import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/enums.dart';
import '../../models/models.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../contacts/contact_detail_screen.dart';
import 'contact_picker_screen.dart';
import 'group_chat_screen.dart';

/// Group detail & management (FR-34..FR-40). Organized groups are read-only
/// (join-only, admin-managed); private groups expose leave/delete/invite for
/// the appropriate roles.
class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final state = AppScope.of(context);
    final g = state.td.group(groupId);
    if (g == null) {
      return const Scaffold(body: Center(child: Text('—')));
    }
    final isMember = state.isEffectiveMember(g);
    final isAdmin = g.managerId == state.td.myId && !g.isOrganized;
    final members = state.membersOf(g);
    // Grubu kuran kişi — listenin başında kendi ayracıyla gösterilir.
    final creator =
        g.managerId != null ? state.td.member(g.managerId!) : null;
    final pending = state.pendingGroupInvites(groupId);

    return Scaffold(
      appBar: AppBar(title: Text(s.groupInfoTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          // Kurucuya (yalnız özel grupta) fotoğraf değiştirme — Profil'deki
          // kamera-rozetli desen; prototipte mock.
          Center(
            child:
                isAdmin
                    ? Stack(
                      children: [
                        GroupAvatar(group: g, radius: 46),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: Theme.of(context).colorScheme.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _photoStub(context),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    : GroupAvatar(group: g, radius: 46),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    g.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Adı yalnız kurucu değiştirir (kurum sahibi hükmü).
                if (isAdmin)
                  IconButton(
                    tooltip: s.edit,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _renameDialog(context, g),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            // Özel grupta rozet TÜRÜ değil ERİŞİMİ söyler: "Herkese Açık" /
            // "Kısıtlı Katılımcı" — kullanıcıya "Özel" etiketi bilgi vermiyordu.
            child: TagChip(
              label:
                  g.isOrganized
                      ? s.organized
                      : (g.isOpen ? s.accessOpenChip : s.accessClosedChip),
              icon:
                  g.isOrganized
                      ? Icons.verified_outlined
                      : (g.isOpen ? Icons.public : Icons.lock_outline),
            ),
          ),
          if (g.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                g.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          if (g.isOrganized)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.organizedJoinOnly)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Birincil eylem: sohbeti GÖREBİLİYORSAM aç (FR-90 — üyelik yetmez);
          // göremiyor ama katılabilirsem katıl (özel/açık grup).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                state.canSeeGroupChat(g)
                    ? FilledButton.icon(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => GroupChatScreen(groupId: groupId),
                            ),
                          ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(s.openChat),
                    )
                    : (isMember
                        ? const SizedBox.shrink()
                        : FilledButton.icon(
                          onPressed: () {
                            AppScope.of(
                              context,
                              listen: false,
                            ).joinGroup(groupId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.joinedGroup)),
                            );
                          },
                          icon: const Icon(Icons.group_add),
                          label: Text(s.joinGroup),
                        )),
          ),

          if (isMember) ...[
            SwitchListTile(
              secondary: const Icon(Icons.notifications_off_outlined),
              title: Text(s.mute),
              // Kişisel görünüm (FR-49): bakan kimliğe ait, grup-üstü değil.
              value: state.isGroupMuted(groupId),
              onChanged:
                  (_) => AppScope.of(
                    context,
                    listen: false,
                  ).toggleGroupMute(groupId),
            ),
          ],

          // FR-90: iki anahtarı yalnız MANAGER çevirir (görünürlük yalnız
          // kurumsal grupta anlamlı — özelde üyeler zaten birbirini görür).
          if (state.isGroupManager(g)) ...[
            const Divider(height: 16),
            RoleHeader(s.managerSettingsTitle),
            // Yazma yetkisi: switch yerine iki-seçenekli kutu-toggle.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: BoxedBinaryChoice(
                value: g.membersCanWrite,
                onChanged:
                    (v) => AppScope.of(
                      context,
                      listen: false,
                    ).setMembersCanWrite(groupId, v),
                falseLabel: s.writeManagerOnly,
                trueLabel: s.writeMembersToo,
              ),
            ),
            if (g.isOrganized)
              SwitchListTile(
                secondary: const Icon(Icons.shield_outlined),
                title: Text(s.authorityOnlyLabel),
                value: g.visibility == GroupVisibility.authorityOnly,
                onChanged:
                    (v) => AppScope.of(context, listen: false).setGroupVisibility(
                      groupId,
                      v
                          ? GroupVisibility.authorityOnly
                          : GroupVisibility.allMembers,
                    ),
              ),
          ],

          const Divider(height: 16),

          // Üyeler doğrudan bu sayfada, ÜÇ ayraçla: önce GRUP YÖNETİCİSİ
          // (grubu kuran kişi), sonra roller admin sırasıyla (ortak kural).
          // Ayrı "Üyeler" ekranı kaldırıldı — liste zaten burada.
          if (creator != null) ...[
            RoleHeader(s.groupAdmin),
            _memberRow(context, state, g, creator, canManage: false),
          ],
          ...roleSections(
            context: context,
            members: members.where((m) => m.id != g.managerId).toList(),
            roles: state.tenantRoles,
            roleName: state.roleName,
            header: (t) => RoleHeader(t),
            otherLabel: s.membersTitle,
            row: (m) => _memberRow(context, state, g, m, canManage: isAdmin),
          ),

          // Admin: invite members + pending count (FR-38).
          if (isAdmin) ...[
            const Divider(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: Text(s.inviteMembers),
              subtitle:
                  pending > 0 ? Text('${s.pending}: $pending') : null,
              onTap: () => _invite(context, g),
            ),
            // FR-81: "açık" bayrağını YALNIZ grubu kuran üye çevirir; bu bir
            // kiracı admin ayarı değildir. Kapatmak mevcut üyeleri atmaz.
            // İki-seçenekli kutu-toggle; açıklamalar kutu içinde.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: BoxedBinaryChoice(
                value: g.isOpen,
                onChanged:
                    (v) => AppScope.of(
                      context,
                      listen: false,
                    ).toggleGroupOpen(groupId),
                falseLabel: s.closedGroup,
                falseDesc: s.closedGroupHint,
                trueLabel: s.openGroup,
                trueDesc: '${s.openGroupHint} ${s.openGroupToggleHint}',
              ),
            ),
          ],

          const Divider(height: 16),

          // Leave (private members) / archive (admin). Organized: neither.
          if (!g.isOrganized) ...[
            if (isAdmin)
              ListTile(
                // Yıkıcı değil: arşivlemek geri alınabilir, o yüzden kırmızı
                // (error) renk de kullanmıyoruz.
                leading: const Icon(Icons.archive_outlined),
                title: Text(s.archiveGroup),
                subtitle: Text(s.archiveHint),
                onTap: () => _archive(context, g),
              )
            else if (isMember)
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  s.leaveGroup,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () => _leave(context, g),
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _invite(BuildContext context, Group g) async {
    // Manage mode: picker mevcut üyeleri (pasif) ve bekleyen davetleri
    // işaretli gösterir; "Kaydet"te yeni davetleri gönderir, kalkanları iptal
    // eder ve özet snackbar'ı kendisi verir.
    await pickContacts(context, groupId: g.id);
  }

  // Ürün kuralı: "Emin misin?" ikinci onayı yok — eylem doğrudan uygulanır,
  // sonuç bildirimle söylenir. Ayrılmak geri alınabilir: açık gruba yeniden
  // katılırsın, kapalı gruba yeni davetle dönersin (FR-39, FR-81).
  void _leave(BuildContext context, Group g) {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    AppScope.of(context, listen: false).leaveGroup(g.id);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(s.leftGroup)));
  }

  // Ortak üye satırı: rol başlıkta olduğundan alt-yazı yalnız bölüm.
  Widget _memberRow(
    BuildContext context,
    AppState state,
    Group g,
    Member m, {
    required bool canManage,
  }) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final isMe = m.id == state.td.myId;
    // "Kutu kutu" (kullanıcı tercihi): avatar serbest, ad InfoBox'ta, sağda
    // (yetkiliyse) çıkar ikonu.
    return InkWell(
      onTap:
          isMe
              ? null
              : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactDetailScreen(memberId: m.id),
                ),
              ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        child: Row(
          children: [
            MemberAvatar(member: m),
            const SizedBox(width: 10),
            Expanded(
              child: InfoBox(
                // İsim düzeni tek satır: "Ad SOYAD, Ünvan, Bölüm [rakam]".
                child: Text.rich(
                  TextSpan(
                    children: [
                      m.rowLabelSpan(context),
                      if (isMe)
                        TextSpan(
                          text: ' (${s.you})',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (canManage && !isMe)
              IconButton(
                tooltip: s.removeMember,
                icon: Icon(
                  Icons.person_remove_outlined,
                  color: scheme.error,
                ),
                onPressed:
                    () => AppScope.of(
                      context,
                      listen: false,
                    ).removeGroupMember(g.id, m.id),
              ),
          ],
        ),
      ),
    );
  }

  // Ad değiştirme — veri girişi diyaloğu (form; NFR-18 kapsamı dışında).
  void _renameDialog(BuildContext context, Group g) {
    final s = context.s;
    final controller = TextEditingController(text: g.name);
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(s.groupName),
            content: TextField(controller: controller, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.cancel),
              ),
              FilledButton(
                onPressed: () {
                  AppScope.of(
                    context,
                    listen: false,
                  ).renameGroup(g.id, controller.text);
                  Navigator.pop(ctx);
                },
                child: Text(s.save),
              ),
            ],
          ),
    );
  }

  // PROTOTİP: grup fotoğrafı seçimi mock (Profil/Özel Grup Yarat ile aynı).
  void _photoStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prototip: gerçek uygulamada grup fotoğrafı seçilir.'),
      ),
    );
  }

  // Ürün kuralı: "Emin misin?" ikinci onayı yok. Bu eylemde güvenle
  // uygulanabiliyor, çünkü artık YIKICI DEĞİL: silmek yerine arşivliyor —
  // grup ve mesajları durur, kurucusu Menü → Arşiv'den geri alır. Üründe
  // kalıcı silme yoktur.
  void _archive(BuildContext context, Group g) {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    AppScope.of(context, listen: false).archiveGroup(g.id);
    Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(s.groupArchived)));
  }
}
