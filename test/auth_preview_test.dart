import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  testWidgets('auth registration preview', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    const previewKey = Key('auth-preview-root');

    await tester.pumpWidget(
      const RepaintBoundary(
        key: previewKey,
        child: PingShengApp(authPreview: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('创建账号'), findsOneWidget);
    expect(find.text('注册'), findsOneWidget);
    await expectLater(
      find.byKey(previewKey),
      matchesGoldenFile('goldens/auth_registration_preview.png'),
    );
  });
}
