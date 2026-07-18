// Minimal smoke test so `flutter analyze`/`flutter test` stay green.
// The full QA test suite is authored separately by the QA stage.

import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/app.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GroupConnectApp());
    await tester.pump();
    // The branded splash shows the app name.
    expect(find.text('GroupConnect'), findsWidgets);
  });
}
