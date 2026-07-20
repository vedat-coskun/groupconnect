// Outlook tarzı çoklu seçim pilotu (kullanıcı tercihi): Rehberim'de avatara
// dokun → seçim modu (avatarlar yerine daireler + üst çubuk); Hepsini Seç ↔
// Tümünü Bırak dönüşümü; toplu silme. 393px'te (dar ekran dersi) çalışır.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/screens/contacts/contacts_screen.dart';
import 'package:groupconnect/state/app_scope.dart';
import 'package:groupconnect/state/app_state.dart';
import 'package:groupconnect/theme/app_theme.dart';
import 'package:groupconnect/widgets/common.dart';

void main() {
  testWidgets('Rehberim: avatara dokun → seçim modu; Hepsini Seç ↔ Bırak; '
      'toplu silme', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    state.setPendingPhone('+90', '5555555501'); // Vedat — akademisyen
    state.selectTenant('uni');
    state.addContactDirect('u_mehmet');
    state.addContactDirect('u_elif');
    final total = state.contacts.length;
    expect(total, greaterThanOrEqualTo(2));

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ContactsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rehberim'));
    await tester.pumpAndSettle();

    // Seçim modu kapalı: çubuk yok.
    expect(find.text('Hepsini Seç'), findsNothing);

    // Avatara dokun → mod açılır, o kişi seçili.
    await tester.tap(find.byType(MemberAvatar).first);
    await tester.pumpAndSettle();
    expect(find.text('Hepsini Seç'), findsOneWidget);
    expect(find.text('1 seçildi'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Hepsini Seç → hepsi işaretli, etiket Tümünü Bırak'a döner.
    await tester.tap(find.text('Hepsini Seç'));
    await tester.pumpAndSettle();
    expect(find.text('Tümünü Bırak'), findsOneWidget);
    expect(find.text('$total seçildi'), findsOneWidget);

    // Toplu sil → mod kapanır, rehber boşalır.
    await tester.tap(find.byIcon(Icons.person_remove_outlined));
    await tester.pumpAndSettle();
    expect(state.contacts, isEmpty);
    expect(find.text('Tümünü Bırak'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Rehberim: Tümünü Bırak seçim modundan çıkarır (başa dön)',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    state.setPendingPhone('+90', '5555555501');
    state.selectTenant('uni');
    state.addContactDirect('u_mehmet');
    state.addContactDirect('u_elif');

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ContactsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rehberim'));
    await tester.pumpAndSettle();

    // Seçim moduna gir, hepsini seç → etiket "Tümünü Bırak".
    await tester.tap(find.byType(MemberAvatar).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hepsini Seç'));
    await tester.pumpAndSettle();
    expect(find.text('Tümünü Bırak'), findsOneWidget);

    // Tümünü Bırak → seçim modu tamamen kapanır (başa dön), kişi silinmez.
    await tester.tap(find.text('Tümünü Bırak'));
    await tester.pumpAndSettle();
    expect(find.text('Hepsini Seç'), findsNothing);
    expect(find.text('Tümünü Bırak'), findsNothing);
    expect(find.byType(MemberAvatar), findsWidgets); // avatarlar geri geldi
    expect(state.contacts.length, 2); // silme YOK
    expect(tester.takeException(), isNull);
  });

  testWidgets('Herkes: roller VARSAYILAN KAPALI; açınca sekme değişse de kalır',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    state.setPendingPhone('+90', '5555555501');
    state.selectTenant('uni');

    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ContactsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Herkes ilk sekme. Varsayılan KAPALI → üye satırı (avatar) görünmez.
    expect(find.byType(MemberAvatar), findsNothing);

    // Akademisyen başlığına dokun → açılır, üyeler görünür.
    await tester.tap(find.textContaining('AKADEM'));
    await tester.pumpAndSettle();
    expect(find.byType(MemberAvatar), findsWidgets);

    // Rehberim'e geç, Herkes'e dön → durum KORUNUR (hâlâ açık).
    await tester.tap(find.text('Rehberim'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Herkes'));
    await tester.pumpAndSettle();
    expect(find.byType(MemberAvatar), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
