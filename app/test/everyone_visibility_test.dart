// "Herkes" görünürlüğü: admin matrisi bir ENGEL değil, VARSAYILANdır
// (kurum sahibi hükmü 2026-08-01). Matris-dışı çift ENGELLİ değildir — kişi
// kendini "Görünür" tuttukça görünür; "Görünmez" yaparsa yalnız matrisin
// otomatik gördüğü roller (yetkili) onu görür. "Tamamen gizli" YOKTUR.
//
// Seed: login öğrencileri Suden (u_zeynep) + Arda (u_can) GİZLİ başlar; diğer
// öğrenciler görünür.
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/state/app_state.dart';

void main() {
  test('öğrenci: görünür öğrenciyi görür, GİZLİ öğrenciyi görmez', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555503'); // Arda — öğrenci
    s.selectTenant('uni');

    final ardaSees = s.everyoneVisible.map((m) => m.id).toSet();

    // Görünür bir öğrenci (Aslı) → matris öğrenci→öğrenci vermese de görünür.
    expect(ardaSees, contains('u_asli'));
    // Akademisyen zaten matrisle görünür.
    expect(ardaSees, contains('u_ayse'));
    // Suden GİZLİ → matris-dışı öğrenci onu GÖRMEZ.
    expect(ardaSees, isNot(contains('u_zeynep')));

    // Matris-dışı görünür öğrenciyi eklemek ONAY davetidir (doğrudan değil).
    expect(s.canSeeDirectly(s.me.roleId, 'student'), isFalse);
    expect(s.addContact('u_asli'), AddResult.invited);
  });

  test('akademisyen GİZLİ öğrenciyi de görür (matris zorlar — engel yok)', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501'); // Vedat — akademisyen
    s.selectTenant('uni');

    // Suden gizli olsa da akademisyen matrisle her zaman görür.
    expect(s.everyoneVisible.map((m) => m.id), contains('u_zeynep'));
  });

  test('REHBERDEKİ gizli kişi Herkes\'te (everyoneVisibleOrContact) kalır', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555504'); // Merve — görünür öğrenci
    s.selectTenant('uni');
    s.addContactDirect('u_can'); // Arda (gizli) rehbere

    // Keşif listesinde Arda YOK (gizli); ama Herkes = keşif ∪ rehber → VAR.
    expect(s.everyoneVisible.map((m) => m.id), isNot(contains('u_can')));
    expect(
      s.everyoneVisibleOrContact.map((m) => m.id),
      contains('u_can'),
    );
  });
}
