// 393px regresyonu: "Özel Grup Yarat" ekranı boş gelmemeli.
//
// BoxedBinaryChoice bir `Row` + `crossAxisAlignment.stretch` kullanıyordu;
// ListView gibi sınırsız-yükseklik bir bağlamda stretch, çocuklara sonsuz
// yükseklik dayatıp gövdeyi çizilemez yapıyordu (kullanıcı "+ Özel Grup Yarat"
// açınca bomboş ekran). Fix: Row artık IntrinsicHeight içinde. Bkz.
// widgets/common.dart BoxedBinaryChoice.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/screens/groups/create_group_screen.dart';
import 'package:groupconnect/state/app_scope.dart';
import 'package:groupconnect/state/app_state.dart';
import 'package:groupconnect/theme/app_theme.dart';
import 'package:groupconnect/widgets/common.dart';

void main() {
  testWidgets('Özel Grup Yarat 393px\'te çizilir (BoxedBinaryChoice)',
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
          home: const CreateGroupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Gövde gerçekten çizilmeli: iki kutu-toggle ve alanlar görünür, hata yok.
    expect(find.text('Özel Grup Yarat'), findsOneWidget);
    expect(find.byType(BoxedBinaryChoice), findsNWidgets(2));
    expect(find.text('Kapalı Grup'), findsOneWidget);
    expect(find.text('Yalnızca Yönetici Yazabilir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
