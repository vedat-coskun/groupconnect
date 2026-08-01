// Kişiler → Davetler → "Gönderdiğim" rehber daveti geçmişi (durum + tarih).
//
// Vedat'ın mock'ta seed'li giden davetleri: Ece (kabul), Aslı (red). Bekleyen
// durum Vedat (akademisyen) için oluşmaz — matris herkesi doğrudan gördüğünden
// onay daveti hiç kurulmaz (bkz. mock_data yorumu). Bu test render'ı + durum
// çiplerini doğrular (sim otomasyonu Xcode 26.6 ile kırık olduğundan güvence).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/models/enums.dart';
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

    // State katmanı: GÖNDERDİĞİM yalnız çözülmemiş/başarısız (beklemede+red)
    // gösterir — KABUL edilenler çıkarılır (çift kayıt olmasın). Vedat'ta yalnız
    // Aslı (red) kalır; Ece (kabul) "Kabul Edilenler"e düşer.
    final sent = state.sentContactInvites;
    expect(sent.length, 1);
    expect(sent.every((i) => i.status != InviteStatus.accepted), isTrue);

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

    // GÖNDERDİĞİM'de yalnız "Reddedildi" (Aslı); "Kabul edildi" çipi HİÇ yok
    // (kabul edilen Ece "Kabul Edilenler" bölümüne düştü). Ece yine ekranda.
    expect(find.text('Reddedildi'), findsOneWidget);
    expect(find.text('Kabul edildi'), findsNothing);
    expect(find.text('Aslı Bozkurt'), findsOneWidget);
    expect(find.text('Ece Yalman'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
