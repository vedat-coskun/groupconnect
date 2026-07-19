// Yeşil Vadi Sitesi hiyerarşisi (kullanıcı hükmü): kök üç KATEGORİ'dir
// (İdari Personel / Ev Sahibi / Sakin — admin rolleri). İdari Personel
// çocuksuz (isHierarchyRoot). Ev Sahibi ve Sakin altında Mavi Blok/Yeşil Blok
// AYRI AYRI tekrarlanır — her biri yalnız o kategoriden sakini olan
// daireleri toplar (aynı isim, farklı id).
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/state/app_state.dart';

void main() {
  test('Kurumsal kökler: üç kategori (İdari/Sahip/Sakin), düz gruplar '
      '(ör. Site Duyuruları) hariç', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501'); // Vedat — Müdür
    s.selectTenant('site');

    final roots = s.treeRootGroups.map((g) => g.name).toSet();
    expect(roots, {'İdari Personel', 'Ev Sahibi', 'Sakin'});
    expect(roots.contains('Site Duyuruları'), isFalse);
  });

  test('İdari Personel çocuksuz — 8 personel doğrudan altında', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('site');

    final idari = s.td.group('sg_idari')!;
    expect(s.childGroupsOf(idari.id), isEmpty);
    expect(s.aggregateMembersOf(idari).length, 8);
  });

  test('Ev Sahibi → Mavi/Yeşil Blok (sahip daireleri) + 2 villa; sayılar '
      'birbirini tutar (FR-71)', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('site');

    final sahip = s.td.group('sg_sahip')!;
    final children = s.childGroupsOf(sahip.id);
    expect(children.map((g) => g.name).toSet(),
        {'Mavi Blok', 'Yeşil Blok', 'Deniz Villa', 'Orman Villa'});

    // Sahip tarafındaki Mavi Blok yalnız sahip daireleri (1, 3) toplar.
    final maviSahip = s.td.group('sg_mavi_sahip')!;
    final maviDaireler = s.childGroupsOf(maviSahip.id);
    expect(maviDaireler.map((g) => g.name).toSet(), {'Daire 1', 'Daire 3'});
    expect(s.aggregateMembersOf(maviSahip).length, 2);

    // Villa doğrudan Ev Sahibi'nin yaprağı (bloklara ayrılmaz).
    final deniz = s.td.group('sg_deniz')!;
    expect(s.childGroupsOf(deniz.id), isEmpty);

    // Üst toplam = alt ağacın birleşimi: 2 (Mavi) + 2 (Yeşil) + 1 + 1 = 6.
    expect(s.aggregateMembersOf(sahip).length, 6);
  });

  test('Sakin → Mavi/Yeşil Blok (kiracı daireleri); sayılar tutar', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('site');

    final sakin = s.td.group('sg_sakin')!;
    final children = s.childGroupsOf(sakin.id);
    expect(children.map((g) => g.name).toSet(), {'Mavi Blok', 'Yeşil Blok'});

    final maviSakin = s.td.group('sg_mavi_sakin')!;
    expect(s.childGroupsOf(maviSakin.id).map((g) => g.name), ['Daire 2']);
    expect(s.aggregateMembersOf(maviSakin).length, 1);

    expect(s.aggregateMembersOf(sakin).length, 2); // 1 (Mavi) + 1 (Yeşil)
  });

  test('Müdür (yetkili) herkesi görür; sakin yalnız personeli (varsayılan '
      'matris)', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501'); // Vedat — Müdür (idari personel)
    s.selectTenant('site');
    expect(s.everyoneVisible.length, 15); // kendisi hariç 15 kişi

    expect(s.canSeeDirectly('staff', 'owner'), isTrue);
    expect(s.canSeeDirectly('owner', 'owner'), isFalse); // komşu komşuyu değil
    expect(s.canSeeDirectly('owner', 'staff'), isTrue); // ama personeli görür
  });

  test('FR-90: dairesinin sakini kendi Daire sohbetinde yazar', () {
    final s = AppState();
    s.setPendingPhone('+90', '5555555501');
    s.selectTenant('site');
    final daire1 = s.td.group('sg_mavi_1')!;
    expect(s.td.member('s_mavi1'), isNotNull);
    expect(daire1.managerId, 's_mavi1'); // kendi dairesinin manager'ı
    expect(daire1.parentGroupId, 'sg_mavi_sahip'); // sahip dalında
  });
}
