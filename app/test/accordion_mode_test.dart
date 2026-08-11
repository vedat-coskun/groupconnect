// TEKLİ / ÇOKLU AKORDİYON kişisel ayarı (kullanıcı hükmü 2026-08-06):
// - Çoklu (varsayılan): birden çok bölüm açık kalabilir.
// - Tekli: bir bölüm açılınca kardeşleri kapanır.
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/state/app_state.dart';

void main() {
  AppState login() {
    final s = AppState();
    s.setPendingPhone('+90', '5555555503'); // Arda
    s.selectTenant('uni');
    return s;
  }

  test('varsayılan ÇOKLU: iki bölüm aynı anda açık kalır', () {
    final s = login();
    expect(s.accordionSingle, isFalse);
    s.toggleChatSection('all');
    s.toggleChatSection('organized');
    expect(s.isChatSectionExpanded('all'), isTrue);
    expect(s.isChatSectionExpanded('organized'), isTrue);
  });

  test('TEKLİ: yeni bölüm açılınca kardeşleri kapanır', () {
    final s = login();
    s.toggleChatSection('all');
    s.toggleChatSection('organized');
    s.setAccordionSingle(true);

    s.toggleChatSection('private');
    expect(s.isChatSectionExpanded('private'), isTrue);
    expect(s.isChatSectionExpanded('all'), isFalse);
    expect(s.isChatSectionExpanded('organized'), isFalse);

    // Aynı bölüme tekrar dokun → kapanır (tekli modda da kapatma serbest).
    s.toggleChatSection('private');
    expect(s.isChatSectionExpanded('private'), isFalse);
  });

  test('TEKLİ Kişiler→Herkes rolleri için de geçerli', () {
    final s = login();
    s.setAccordionSingle(true);
    s.toggleEveryoneRole('Akademisyen');
    s.toggleEveryoneRole('Öğrenci');
    expect(s.isEveryoneRoleExpanded('Öğrenci'), isTrue);
    expect(s.isEveryoneRoleExpanded('Akademisyen'), isFalse);
  });

  test('ayar kimlik başına saklanır (setAccordionSingle → td)', () {
    final s = login();
    s.setAccordionSingle(true);
    expect(s.accordionSingle, isTrue);
    s.setAccordionSingle(false);
    expect(s.accordionSingle, isFalse);
  });
}
