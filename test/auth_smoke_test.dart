import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  testWidgets('auth preview smoke', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp(authPreview: true));
    await tester.pump();

    expect(find.text('创建账号'), findsOneWidget);
    expect(find.text('注册'), findsOneWidget);
  });
}
