// Kimlik kapsamı (userid) regresyonları — "ekrandaki her madde ve her işlem
// bakan kimliğe göre" (kurum sahibi hükmü). Üç kimlik: 01=Vedat (akademisyen),
// 02=Suden (u_zeynep), 03=Arda (u_can).
//
// Kapsanan sınıflar:
//   1. FR-90 — grup sohbeti erişimi: manager + görünürlük/yazma anahtarları;
//      üyelik tek başına erişim vermez; veri katmanı koruması (NFR-17).
//   2. 1:1 dizileri taraf-çifti anahtarlıdır: katılımcı olmayan kimlik
//      başkasının yazışmasını göremez; karşı taraf kendi yazışmasını görür.
//   3. Kişisel durum (engel, not, sessize alma) kimlik değişiminde sızmaz.
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/state/app_state.dart';

AppState _login(String lastTwo) {
  final s = AppState();
  s.setPendingPhone('+90', '55555555$lastTwo');
  s.selectTenant('uni');
  return s;
}

void _relogin(AppState s, String lastTwo) {
  s.logout();
  s.setPendingPhone('+90', '55555555$lastTwo');
  s.selectTenant('uni');
}

void main() {
  test('FR-90: görme (rol+görünürlük) ve yazma (manager+anahtar) ayrı katman',
      () {
    final s = _login('03'); // Arda — öğrenci, g_dept_cs üyesi
    final dept = s.td.group('g_dept_cs')!; // authorityOnly
    final course = s.td.group('g_test')!; // allMembers + membersCanWrite
    final private = s.td.group('g_bitirme')!; // özel + membersCanWrite

    // Öğrenci bölüm ÜYESİdir ama "yalnız yetkili" olduğundan sohbeti GÖREMEZ
    // (kurum sahibi hükmü) — dolayısıyla yazamaz da.
    expect(s.isEffectiveMember(dept), isTrue); // Kurum Yapısı'nda görünür
    expect(s.canSeeGroupChat(dept), isFalse); // ama sohbeti görmez
    expect(s.canWriteInGroup(dept), isFalse);
    // Sohbetler listesinde bölüm YOK, kendi dersi VAR.
    final chatIds = s.chatSummaries.map((c) => c.group?.id).toSet();
    expect(chatIds.contains('g_dept_cs'), isFalse);
    expect(chatIds.contains('g_test'), isTrue);

    // Kendi dersi: görünür (allMembers) ve tartışma (membersCanWrite) → yazar.
    expect(s.canSeeGroupChat(course), isTrue);
    expect(s.canWriteInGroup(course), isTrue);
    // Özel grup (membersCanWrite): her üye yazar.
    expect(s.canWriteInGroup(private), isTrue);

    // Veri katmanı koruması: göremediği gruba gönderim sessizce düşer.
    final before = s.messagesOf('grp:g_dept_cs').length;
    s.sendGroupMessage('g_dept_cs', 'öğrenci bölüme yazamaz');
    expect(s.messagesOf('grp:g_dept_cs').length, before);

    // Akademisyen (Vedat): bölümü GÖRÜR (yetkili) ama yazamaz (manager değil,
    // anahtar kapalı) — okur. Ders sahibi olduğu g_test'te manager → yazar.
    _relogin(s, '01');
    expect(s.canSeeGroupChat(s.td.group('g_dept_cs')!), isTrue);
    expect(s.canWriteInGroup(s.td.group('g_dept_cs')!), isFalse);
    expect(s.isGroupManager(s.td.group('g_test')!), isTrue);
    final n = s.messagesOf('grp:g_test').length;
    s.sendGroupMessage('g_test', 'Sınav tarihi güncellendi.');
    expect(s.messagesOf('grp:g_test').length, n + 1);
  });

  test('FR-90: manager iki anahtarı çevirir; başkası çeviremez', () {
    final s = _login('01'); // Vedat — g_dept_cs manager DEĞİL (u_ayse)
    // Manager olmayan çeviremez (no-op).
    s.setMembersCanWrite('g_dept_cs', true);
    expect(s.td.group('g_dept_cs')!.membersCanWrite, isFalse);

    // Manager olduğu g_test'te çevirir.
    s.setMembersCanWrite('g_test', false);
    expect(s.td.group('g_test')!.membersCanWrite, isFalse);
    // Öğrenci artık ders sohbetini görür ama yazamaz (anahtar kapandı).
    _relogin(s, '03');
    expect(s.canSeeGroupChat(s.td.group('g_test')!), isTrue);
    expect(s.canWriteInGroup(s.td.group('g_test')!), isFalse);
  });

  test('1:1 dizileri taraf-çiftine aittir — üçüncü kimliğe kapalı', () {
    final s = _login('01'); // Vedat
    // Tohum: Vedat↔Suden yazışması çift-anahtarlı dizide durur.
    expect(s.dmThread('u_zeynep'), 'dm:u_me:u_zeynep');
    expect(s.messagesOf(s.dmThread('u_zeynep')), isNotEmpty);

    // Karşı taraf (Suden) AYNI diziyi kendi ucundan görür.
    _relogin(s, '02');
    expect(s.dmThread('u_me'), 'dm:u_me:u_zeynep');
    expect(s.messagesOf(s.dmThread('u_me')), isNotEmpty);

    // Üçüncü kimlik (Arda) için aynı kişiyle anahtar FARKLIDIR ve boştur:
    // başkasının yazışması ona hiçbir uçtan görünmez.
    _relogin(s, '03');
    expect(s.dmThread('u_zeynep'), 'dm:u_can:u_zeynep');
    expect(s.messagesOf(s.dmThread('u_zeynep')), isEmpty);
    expect(s.messagesOf(s.dmThread('u_me')), isEmpty);
    // Sohbet listesinde de başkasının 1:1'i yüzmez.
    expect(s.chatSummaries.where((c) => !c.isGroup), isEmpty);
  });

  test('engel / sessize alma / not kimlik başına yalıtılır', () {
    final s = _login('01'); // Vedat
    s.block('u_elif');
    s.toggleDmMute('u_ayse');
    s.toggleGroupMute('g_bitirme');
    s.setNote('u_zeynep', 'Bitirme projesi ekibinde.');

    // Arda girer: Vedat'ın kişisel durumu ona sızmaz.
    _relogin(s, '03');
    expect(s.isBlocked('u_elif'), isFalse);
    expect(s.isDmMuted('u_ayse'), isFalse);
    expect(s.isGroupMuted('g_bitirme'), isFalse);
    expect(s.noteFor('u_zeynep'), isEmpty);

    // Vedat geri girer: kendi durumu korunur (oturum içi kimlik önbelleği).
    _relogin(s, '01');
    expect(s.isBlocked('u_elif'), isTrue);
    expect(s.isDmMuted('u_ayse'), isTrue);
    expect(s.isGroupMuted('g_bitirme'), isTrue);
    expect(s.noteFor('u_zeynep'), 'Bitirme projesi ekibinde.');
  });

  test('FR-18: engellediğim kişiye 1:1 gönderim veri katmanında düşer', () {
    final s = _login('01');
    s.block('u_elif');
    final tid = s.dmThread('u_elif');
    final before = s.messagesOf(tid).length;
    s.sendDm('u_elif', 'bu gitmemeli');
    expect(s.messagesOf(tid).length, before);
  });
}
