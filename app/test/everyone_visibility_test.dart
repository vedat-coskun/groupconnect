// "Herkes" görünürlüğü: admin matrisi bir ENGEL değil, VARSAYILANdır
// (kurum sahibi hükmü 2026-08-01). Matris-dışı bir çift ENGELLİ değildir —
// kişi kendini "Görünür" tuttukça listede kalır; yalnız ekleme onaya bağlıdır.
// Regresyon: bir öğrenci, kendini görünür tutan BAŞKA bir öğrenciyi görür.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/models/enums.dart';
import 'package:groupconnect/state/app_state.dart';

void main() {
  test('öğrenci, görünür başka bir öğrenciyi Herkes\'te görür (matris değil)',
      () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555503'); // Arda — öğrenci
    s.selectTenant('uni');

    final visibleIds = s.everyoneVisible.map((m) => m.id).toSet();

    // Suden (u_zeynep) öğrenci ve varsayılan "Görünür" → Arda onu GÖRÜR
    // (matris öğrenci→öğrenci vermese de, çünkü matris engel değil varsayılan).
    expect(visibleIds, contains('u_zeynep'));
    // Akademisyen zaten matrisle görünür (kontrol).
    expect(visibleIds, contains('u_ayse'));
    // Ama Suden matris-DIŞIdır → doğrudan eklenemez; eklemek ONAY davetidir.
    expect(s.canSeeDirectly(s.me.roleId, 'student'), isFalse);
    expect(s.addContact('u_zeynep'), AddResult.invited);
  });
}
