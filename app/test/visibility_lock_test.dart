// GÖRÜNÜRLÜK KİLİDİ — rol-başına (kullanıcı hükmü 2026-08-02). Admin bir rolü
// kilitlerse o rolün üyeleri KENDİ görünürlüğünü/ekleme politikasını
// DEĞİŞTİREMEZ (Profil'de gizli) ve etkin görünürlük admin varsayılanına
// sabitlenir — üyenin kişisel "Görünür" tercihi bile ezilir.
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/models/enums.dart';
import 'package:groupconnect/state/app_state.dart';

void main() {
  test('kilit + varsayılan GİZLİ: görünür öğrenci de etkin gizli olur', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555503'); // Arda — öğrenci
    s.selectTenant('uni');

    // Önce: u_asli görünür bir öğrenci → matris-dışı Arda onu görür.
    expect(s.everyoneVisible.map((m) => m.id), contains('u_asli'));

    // Admin öğrenci rolünü GİZLİ varsayılanla kilitler.
    s.setDefaultVisibility(MemberVisibility.hidden);
    s.setRoleVisibilityLocked('student', true);

    // u_asli kişisel olarak "Görünür" olsa da etkin görünürlük admin
    // varsayılanına (gizli) sabitlenir → matris-dışı Arda artık göremez.
    final asli = s.td.members['u_asli']!;
    expect(s.effectiveVisibility(asli), MemberVisibility.hidden);
    expect(s.everyoneVisible.map((m) => m.id), isNot(contains('u_asli')));
  });

  test('kilitli rolde kullanıcı kendi görünürlüğünü ayarlayamaz', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555503'); // Arda — öğrenci
    s.selectTenant('uni');

    expect(s.canUserSetVisibility, isTrue);
    s.setRoleVisibilityLocked('student', true);
    expect(s.canUserSetVisibility, isFalse);
  });

  test('kilit yalnız hedef rolü etkiler — akademisyen serbest kalır', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501'); // Vedat — akademisyen
    s.selectTenant('uni');

    s.setRoleVisibilityLocked('student', true);
    // Vedat akademisyen → öğrenci kilidi onu etkilemez.
    expect(s.canUserSetVisibility, isTrue);
  });
}
