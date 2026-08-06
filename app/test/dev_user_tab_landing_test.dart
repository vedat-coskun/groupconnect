// DEBUG "User" (Demo) sekmesi başlangıç davranışı (kullanıcı hükmü 2026-08-06):
// - Oto-giriş (cold start) → ana ekran User sekmesiyle açılır.
// - "Normal giriş akışını dene" (logout → gerçek giriş) → Sohbetler'le açılır,
//   yani gerçek girişten sonra tekrar User seçim ekranına DÜŞMEZ.
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/state/app_state.dart';

void main() {
  test('oto-giriş → startOnDevUserTab TRUE (User sekmesiyle başla)', () {
    final s = AppState();
    s.devAutoLogin(phone: '5555555503', tenantId: 'uni');
    expect(s.phase, AppPhase.home);
    expect(s.startOnDevUserTab, isTrue);
  });

  test('logout → gerçek giriş → startOnDevUserTab FALSE (Sohbetler)', () {
    final s = AppState();
    s.devAutoLogin(phone: '5555555503', tenantId: 'uni');
    expect(s.startOnDevUserTab, isTrue);

    // "Normal giriş akışını dene": auth ekranına dön.
    s.logout();
    expect(s.phase, AppPhase.auth);
    expect(s.startOnDevUserTab, isFalse);

    // Kullanıcı gerçek girişi tamamlar (telefon → kurum).
    s.setPendingPhone('+90', '5555555503');
    s.selectTenant('uni');
    expect(s.phase, AppPhase.home);
    // Gerçek giriş bayrağı ezmez → hâlâ Sohbetler ile açılmalı.
    expect(s.startOnDevUserTab, isFalse);
  });
}
