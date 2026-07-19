// Dar ekran (393px) yerleşim regresyonları.
//
// Bu prototipte aynı hata sınıfı üç kez tekrarladı ve her seferinde **ekranın
// tamamı bomboş** kaldı — çünkü yerleşim assertion'ı satırı değil, gövdeyi
// çizilemez yapıyor:
//   1. ListTile'da geniş `leading`  → "Leading widget consumes the entire tile"
//   2. ListTile'da geniş `trailing` → aynı hata, trailing tarafında
//   3. Row içinde FilledButton      → tema minimumSize: Size.fromHeight(52)
//      verdiği için minGenişlik = sonsuz; Row sınırsız ölçtüğünden zorlanır.
//
// Neden host testleri kaçırdı: `flutter test` varsayılan ekranı 800px geniştir
// (1 ve 2 orada sığar) ve TabBarView yalnız AÇIK sekmeyi kurar. Bu yüzden test
// hem 393px'e sabitlenmeli, hem sekmeye GERÇEKTEN dokunmalı, hem de sekme
// GÖVDESİNİ (yalnız başlık etiketini değil) doğrulamalıdır.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/screens/groups/groups_screen.dart';
import 'package:groupconnect/state/app_scope.dart';
import 'package:groupconnect/state/app_state.dart';
import 'package:groupconnect/theme/app_theme.dart';

void main() {
  testWidgets('Katılabileceklerim: davet + açık gruplar 393px\'te çizilir',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();

    // Arda kendi özel grubunu kurar ve Vedat'ı davet eder.
    state.setPendingPhone('+90', '5555555503');
    state.selectTenant('uni');
    state.addContactDirect('u_me');
    state.createPrivateGroup(
      name: 'Arda Test Grubu',
      description: 'deneme',
      inviteMessage: 'gel',
      invitedIds: ['u_me'],
      autoIncludeIds: const [],
    );

    // Vedat girer: daveti "Davetli Olduklarım" sekmesinde görmeli.
    state.logout();
    state.setPendingPhone('+90', '5555555501');
    state.selectTenant('uni');
    expect(state.joinableGroups.map((g) => g.name), contains('Arda Test Grubu'));

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(theme: AppTheme.light(), home: const GroupsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Katılabileceklerim'));
    await tester.pumpAndSettle();

    // Gövde gerçekten çizilmeli: satır + "Katıl" butonu görünür, hata yok.
    expect(find.text('Arda Test Grubu'), findsOneWidget);
    expect(find.text('Katıl'), findsWidgets);
    // FR-82: davet edilen ile açık olan aynı listede, ayırt edilebilir.
    expect(find.text('Fotoğrafçılık Kulübü'), findsOneWidget);
    expect(find.text('Davet'), findsWidgets);
    expect(find.text('Açık'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kurumsal sekmesi: yazar olmayan üyede mesaj ikonu yok (FR-90), '
      '393px\'te çizilir, accordion açılır', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    state.setPendingPhone('+90', '5555555501'); // Vedat (akademisyen)
    state.selectTenant('uni');

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(theme: AppTheme.light(), home: const GroupsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Kurumsal ilk sekmedir (FR-42). İki fakülte olduğundan (Mühendislik +
    // Tasarım) "tek kök varsa atla" devreye girmez — kök listesi görünür,
    // Mühendislik'e girmek için dokunmak gerekir.
    expect(find.text('Mühendislik Fakültesi'), findsOneWidget);
    expect(find.text('Tasarım Fakültesi'), findsOneWidget);
    await tester.tap(find.text('Mühendislik Fakültesi'));
    await tester.pumpAndSettle();

    expect(find.text('Bilgisayar Mühendisliği'), findsOneWidget);
    // İkon = "buraya yazabilirim" (kullanıcı hükmü), üyelik değil (FR-90).
    // Vedat her iki düğümde de ÜYE ama yazar değil (yalnız Prof. Demir) —
    // ikon hiç çıkmaz. Test kimliği olması özel muamele hakkı vermez.
    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);

    // Bölüme dokun → satır accordion olarak açılır (chevron yön değiştirir).
    // Not: rol başlığı sayısı SAYILMAZ — ListView lazy olduğundan viewport
    // dışına itilen başlıklar hiç build edilmez.
    expect(find.byIcon(Icons.expand_less), findsNothing);
    await tester.tap(find.text('Bilgisayar Mühendisliği'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kurumsal sekmesi: yazar-işaretli üyede mesaj ikonu çıkar '
      '(FR-90 pozitif dal)', (tester) async {
    final state = AppState();
    state.setPendingPhone('+90', '5555555501'); // Vedat
    state.selectTenant('uni');
    // Vedat'ı Bölüm'ün yazarı yap — kuralın pozitif dalını da doğrula.
    state.td.group('g_dept_cs')!.writerIds.add('u_me');

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(theme: AppTheme.light(), home: const GroupsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // İki fakülteli kök listesinden Mühendislik'e gir — g_dept_cs satırı
    // yalnız orada render edilir.
    await tester.tap(find.text('Mühendislik Fakültesi'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });
}
