// Yeşil Vadi Sitesi hiyerarşisi: iki blok (üçer daire) + iki bağımsız villa
// (kullanıcı hükmü). Çocuksuz kök düğümlerin (villa) `isHierarchyRoot` ile
// Kurum Yapısı'nda görünmesi — düz kurumsal gruplardan (ör. bir ders grubu)
// ayrı tutulması — bu testin asıl amacı.
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/state/app_state.dart';

void main() {
  test('Kurumsal kökler: 2 blok + 2 villa, düz gruplar (ör. Site Duyuruları) '
      'hariç', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501'); // Vedat — Müdür
    s.selectTenant('site');

    final roots = s.treeRootGroups.map((g) => g.name).toSet();
    expect(roots, {'Mavi Blok', 'Yeşil Blok', 'Deniz Villa', 'Orman Villa'});
    // "Site Duyuruları" düz bir kurumsal gruptur (çocuksuz VE isHierarchyRoot
    // değil) — hiyerarşide görünmemeli.
    expect(roots.contains('Site Duyuruları'), isFalse);
  });

  test('Blok → Daire sayıları birbirini tutar (FR-71)', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('site');

    final mavi = s.td.groups.firstWhere((g) => g.name == 'Mavi Blok');
    final daireler = s.childGroupsOf(mavi.id);
    expect(daireler.length, 3);
    expect(s.aggregateMembersOf(mavi).length, 3); // Blok = 3 dairenin toplamı

    final deniz = s.td.groups.firstWhere((g) => g.name == 'Deniz Villa');
    expect(s.childGroupsOf(deniz.id), isEmpty); // villa yaprak, alt birimi yok
    expect(s.aggregateMembersOf(deniz).length, 1);
  });

  test('Müdür (yetkili) herkesi görür; sakin yalnız personeli (varsayılan '
      'matris)', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501'); // Vedat — Müdür (idari personel)
    s.selectTenant('site');
    expect(s.everyoneVisible.length, 15); // kendisi hariç 15 kişi

    // Aynı kimlikle bir sakini simüle etmek yerine matrisi doğrudan sorgula:
    // idari personel yetkili (isAuthority), ev sahibi/sakin değil.
    expect(s.canSeeDirectly('staff', 'owner'), isTrue);
    expect(s.canSeeDirectly('owner', 'owner'), isFalse); // komşu komşuyu değil
    expect(s.canSeeDirectly('owner', 'staff'), isTrue); // ama personeli görür
  });

  test('FR-90: dairesinin sakini kendi Daire sohbetinde yazar', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('site');
    final daire1 = s.td.groups.firstWhere((g) => g.id == 'sg_mavi_1');
    expect(s.td.member('s_mavi1'), isNotNull);
    expect(daire1.writerIds.contains('s_mavi1'), isTrue);
  });
}
