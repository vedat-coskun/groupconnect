// Tasarım Fakültesi eklentisi (kullanıcı hükmü): University artık iki
// fakülteli (Mühendislik + Tasarım) — "tek kök varsa atla" artık devreye
// girmez, kök listesi gösterilir.
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/state/app_state.dart';

void main() {
  test('Kurumsal kökler: iki fakülte', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('uni');

    final roots = s.treeRootGroups.map((g) => g.name).toSet();
    expect(roots, {'Mühendislik Fakültesi', 'Tasarım Fakültesi'});
  });

  test('Tasarım Fakültesi → MIS + Tasarım Bölümü, birer akademisyen/öğrenci, '
      'sayılar tutar (FR-71)', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('uni');

    final fac = s.td.groups.firstWhere((g) => g.name == 'Tasarım Fakültesi');
    final children = s.childGroupsOf(fac.id);
    expect(children.map((g) => g.name).toSet(), {'MIS Bölümü', 'Tasarım Bölümü'});

    for (final dept in children) {
      final roles =
          s.aggregateMembersOf(dept).map((m) => s.roleOf(m).id).toSet();
      expect(roles, {'academic', 'student'}); // birer akademisyen + öğrenci
      expect(s.aggregateMembersOf(dept).length, 2);
    }
    expect(s.aggregateMembersOf(fac).length, 4); // 2 + 2, üst = alt toplamı
  });
}
