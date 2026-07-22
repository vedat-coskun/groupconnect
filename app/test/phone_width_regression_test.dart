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
import 'package:groupconnect/screens/chats/chats_screen.dart';
import 'package:groupconnect/screens/groups/groups_screen.dart';
import 'package:groupconnect/state/app_scope.dart';
import 'package:groupconnect/state/app_state.dart';
import 'package:groupconnect/theme/app_theme.dart';
import 'package:groupconnect/widgets/common.dart';

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
    await tester.tap(find.text('Özel Grup Adaylarım'));
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

  testWidgets('Kurumsal 393px: birleşik akordiyon — fakülte→bölüm→üye yerinde',
      (tester) async {
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

    // Kurumsal ilk sekme. Kökler (fakülteler) görünür; VARSAYILAN KAPALI →
    // bölümler görünmez, "DEKANLIK" başlığı da yok.
    expect(find.text('Mühendislik Fakültesi'), findsOneWidget);
    expect(find.text('Tasarım Fakültesi'), findsOneWidget);
    expect(find.text('Bilgisayar Mühendisliği'), findsNothing);
    expect(find.text('DEKANLIK'), findsNothing);

    // Fakülteyi aç → alt-sayfaya GİTMEDEN yerinde açılır: hem bölümler HEM DE
    // fakültenin TOPLAM akademisyen/öğrenci rol başlıkları (kullanıcı hükmü) —
    // ama rol accordion'ları KAPALI (üye avatarı yok). Akademisyen sohbet
    // ikonunu görür (FR-90).
    await tester.tap(find.text('Mühendislik Fakültesi'));
    await tester.pumpAndSettle();
    expect(find.text('Bilgisayar Mühendisliği'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsWidgets);
    expect(find.byIcon(Icons.expand_less), findsWidgets); // fakülte açık
    expect(find.textContaining('AKADEM'), findsWidgets); // fakülte rol başlığı
    expect(find.byType(MemberAvatar), findsNothing); // roller kapalı

    // Fakülte rol başlığına dokun → o rolün üyeleri açılır (rol de accordion).
    await tester.tap(find.textContaining('AKADEM').first);
    await tester.pumpAndSettle();
    expect(find.byType(MemberAvatar), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FR-90: öğrenci bölüm sohbetini Kurum Yapısı\'nda göremez '
      '(mesaj ikonu yok)', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    state.setPendingPhone('+90', '5555555503'); // Arda — öğrenci
    state.selectTenant('uni');

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(theme: AppTheme.light(), home: const GroupsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mühendislik Fakültesi'));
    await tester.pumpAndSettle();

    // Öğrenci bölümü Kurum Yapısı'nda görür (yapı) ama sohbetini göremez →
    // Bilgisayar Mühendisliği satırında mesaj ikonu YOK. Fakülte de authorityOnly
    // olduğundan onun kartında da yok → hiç chat ikonu olmamalı.
    expect(find.text('Bilgisayar Mühendisliği'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sohbetler-Kurumsal 393px: kökler veri sırasıyla, ikinci '
      'seviye accordion; Site Duyuruları yok', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    state.setPendingPhone('+90', '5555555501'); // Vedat — Site Müdürü
    state.selectTenant('site');

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(theme: AppTheme.light(), home: const ChatsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Kategoriler (Kişisel/Kurumsal/Özel) artık AKORDİYON, varsayılan KAPALI →
    // kökler görünmez. Düz "Site Duyuruları" grubu da kalktı.
    expect(find.text('Site Duyuruları'), findsNothing);
    expect(find.text('Personel'), findsNothing);

    // "Kurumsal Grup sohbetleri" kategorisini aç → kökler veri sırasıyla.
    await tester.tap(find.textContaining('Kurumsal Grup'));
    await tester.pumpAndSettle();
    expect(find.text('Personel'), findsOneWidget);
    expect(find.text('Sakin'), findsOneWidget);
    expect(find.text('Ev Sahibi'), findsOneWidget);
    final dyPersonel = tester.getTopLeft(find.text('Personel')).dy;
    final dySakin = tester.getTopLeft(find.text('Sakin')).dy;
    final dySahip = tester.getTopLeft(find.text('Ev Sahibi')).dy;
    expect(dyPersonel, lessThan(dySakin));
    expect(dySakin, lessThan(dySahip));
    expect(find.text('Mavi Blok'), findsNothing);

    // Sakin satırına dokun → accordion açılır: kiracı blokları girintili gelir.
    await tester.tap(find.text('Sakin'));
    await tester.pumpAndSettle();
    expect(find.text('Mavi Blok'), findsOneWidget);
    expect(find.text('Yeşil Blok'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Mavi Blok')).dx,
      greaterThan(tester.getTopLeft(find.text('Sakin')).dx),
    );
    expect(tester.takeException(), isNull);
  });
}
