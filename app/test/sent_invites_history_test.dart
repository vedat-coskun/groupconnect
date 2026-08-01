// Kişiler → Davetler → "Gönderdiğim" rehber daveti geçmişi (durum + tarih).
//
// Vedat'ın mock'ta seed'li giden davetleri: Ece (kabul), Aslı (red). Bekleyen
// durum Vedat (akademisyen) için oluşmaz — matris herkesi doğrudan gördüğünden
// onay daveti hiç kurulmaz (bkz. mock_data yorumu). Bu test render'ı + durum
// çiplerini doğrular (sim otomasyonu Xcode 26.6 ile kırık olduğundan güvence).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/screens/contacts/contacts_screen.dart';
import 'package:groupconnect/state/app_scope.dart';
import 'package:groupconnect/state/app_state.dart';
import 'package:groupconnect/theme/app_theme.dart';

void main() {
  testWidgets('Davetler → Gönderdiğim: giden davetler durum + geçmişle çizilir',
      (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    state.setPendingPhone('+90', '5555555501'); // Vedat
    state.selectTenant('uni');

    // State katmanı: gönderdiğim rehber davetleri (kabul + red), en yeni üstte.
    final sent = state.sentContactInvites;
    expect(sent.length, 2);
    expect(
      sent.first.createdAt.isAfter(sent.last.createdAt),
      isTrue,
      reason: 'en yeni üstte sıralanmalı',
    );

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

    // "Davetler" sekmesine geç.
    expect(find.text('Davetler'), findsWidgets);
    await tester.tap(find.text('Davetler'));
    await tester.pumpAndSettle();

    // İki durum çipi görünür (kabul + red) — düz metin, büyük harfe çevrilmez.
    expect(find.text('Kabul edildi'), findsOneWidget);
    expect(find.text('Reddedildi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
