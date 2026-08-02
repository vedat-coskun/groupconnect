// Kişiler → Davetler → "Gönderdiğim": gönderdiğim rehber davetlerinin durumu
// (Beklemede / Reddedildi) + tarih. Kabul edilenler burada YOK (Kabul
// Edilenler'e/Rehberim'e düşer). Giden davet yalnız temel-rol (öğrenci) için
// oluşur — akademisyen herkesi doğrudan ekler (seed kaldırıldı 2026-08-02).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/models/enums.dart';
import 'package:groupconnect/models/models.dart';
import 'package:groupconnect/screens/contacts/contacts_screen.dart';
import 'package:groupconnect/state/app_scope.dart';
import 'package:groupconnect/state/app_state.dart';
import 'package:groupconnect/theme/app_theme.dart';

void main() {
  testWidgets('Davetler → Gönderdiğim: durum çipleri (beklemede + red)',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    state.setPendingPhone('+90', '5555555502'); // Suden — öğrenci
    state.selectTenant('uni');

    // Gönderdiğim: biri beklemede, biri reddedilmiş (kabul edilen dahil değil).
    state.td.invitations.addAll([
      Invitation(
        id: 's_pending',
        kind: InviteKind.contact,
        direction: InviteDirection.outgoing,
        fromMemberId: 'u_zeynep',
        toMemberId: 'u_asli',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Invitation(
        id: 's_rejected',
        kind: InviteKind.contact,
        direction: InviteDirection.outgoing,
        fromMemberId: 'u_zeynep',
        toMemberId: 'u_burak',
        status: InviteStatus.rejected,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ]);

    // State: iki giden davet, en yeni üstte, kabul olmadığından ikisi de var.
    expect(state.sentContactInvites.length, 2);

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
    expect(find.text('Davetler'), findsWidgets);
    await tester.tap(find.text('Davetler'));
    await tester.pumpAndSettle();

    expect(find.text('Beklemede'), findsOneWidget);
    expect(find.text('Reddedildi'), findsOneWidget);
    expect(find.text('Kabul edildi'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
