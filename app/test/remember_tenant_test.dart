// "Bu kurumu hatırla" (FR-8) iki yönlü çalışmalı.
//
// Sessiz hata sınıfı: kutunun işaretini kaldırmak eskiden HİÇBİR ŞEY yapmıyordu
// (`if (remember) _rememberedTenantId = tenantId;` — sadece set, hiç clear).
// Kullanıcı hatırlamayı iptal edip başka kurum seçiyor, o an doğru kuruma
// giriyor, ekranda hiçbir belirti yok — ama sonraki girişte eski kuruma
// düşüyor. Kurum adı hiçbir ana ekranda yazmadığı için de fark edilmiyor.
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/state/app_state.dart';

AppState _loggedIn() {
  final state = AppState();
  state.setPendingPhone('+90', '5555555501'); // Vedat — 5 kurumlu
  return state;
}

void main() {
  test('işaretli: çıkış sonrası korunur, seçim ekranı atlanır', () {
    final state = _loggedIn();
    state.selectTenant('uni', remember: true);
    state.logout();
    state.setPendingPhone('+90', '5555555501');
    expect(state.verifyOtp(), isFalse, reason: 'seçim ekranı atlanmalı');
    expect(state.activeTenant!.id, 'uni');
  });

  test('işaret kaldırılınca önceki hatırlanan kurum İPTAL olur', () {
    final state = _loggedIn();
    state.selectTenant('site', remember: true);
    // Kurum Değiştir → kutunun işaretini kaldır → başka kurum seç
    state.selectTenant('uni', remember: false);
    expect(state.hasRememberedTenant, isFalse);

    state.logout();
    state.setPendingPhone('+90', '5555555501');
    expect(state.verifyOtp(), isTrue, reason: 'seçim ekranı gelmeli');
    expect(state.activeTenant, isNull, reason: 'eski kuruma düşmemeli');
  });

  test('kurum izolasyonu: seçilen kurumun dışına veri sızmaz', () {
    final state = _loggedIn();
    state.selectTenant('uni');
    expect(state.td.myId, 'u_me');
    expect(
      state.myGroups.map((g) => g.name),
      isNot(contains('Personel')), // Site'ye ait grup uni'de görünmez
    );
  });
}
