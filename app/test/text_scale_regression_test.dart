// Regresyon: yazı boyutu ölçeği tema yerine MediaQuery.textScaler ile
// uygulanır. Daha önce `textTheme.apply(fontSizeFactor:)` fontSize'ı null olan
// stillerde assertion attırıyordu (kullanıcı "Büyük" seçince çöküyordu).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupconnect/models/enums.dart';
import 'package:groupconnect/theme/app_theme.dart';

void main() {
  for (final scale in AppTextScale.values) {
    testWidgets('Yazı boyutu ${scale.labelTr}: tema + textScaler çökmez',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(
            Appearance(
              accent: const Color(0xFF3D5AFE),
              scale: scale,
              fontFamily: null,
            ),
          ),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(scale.factor),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final t = Theme.of(context).textTheme;
                // fontSize'ı null olabilen stiller dahil çeşitli stiller.
                return Column(
                  children: [
                    Text('başlık', style: t.headlineSmall),
                    Text('gövde', style: t.bodyMedium),
                    Text('etiket', style: t.labelSmall),
                    const Text('düz'),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('düz'), findsOneWidget);
    });
  }
}
