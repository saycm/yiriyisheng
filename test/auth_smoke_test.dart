import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  testWidgets('optional app update is shown before auth page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      PingShengApp(
        enableAuth: true,
        updateResponseOverride: () async => {
          'latestVersionCode': 7,
          'latestVersionName': '1.0.6',
          'forceUpdate': false,
          'hasUpdate': true,
          'downloadUrl': 'http://example.com/pingsheng.apk',
          'message': '发现 1.0.6 新版本，建议更新。',
          'releaseNotes': ['普通更新也要提示'],
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('稍后再说'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
  });

  testWidgets('auth preview smoke', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp(authPreview: true));
    await tester.pump();

    expect(find.text('创建账号'), findsOneWidget);
    expect(find.text('注册'), findsOneWidget);
  });

  testWidgets('phone input is limited to 11 digits', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp(authPreview: true));
    await tester.pump();

    await tester.tap(find.text('手机号'));
    await tester.pumpAndSettle();

    final phoneField = find.byType(TextField).at(1);
    await tester.enterText(phoneField, '13800000000123');
    await tester.pump();

    final field = tester.widget<TextField>(phoneField);
    expect(field.controller?.text, '13800000000');
  });

  testWidgets('switching auth mode clears form inputs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp(authPreview: true));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), '阿生');
    await tester.enterText(find.byType(TextField).at(1), 'say1024@qq.com');
    await tester.enterText(find.byType(TextField).at(2), '123456');
    await tester.pump();

    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    final accountField = tester.widget<TextField>(find.byType(TextField).at(0));
    final passwordField =
        tester.widget<TextField>(find.byType(TextField).at(1));
    expect(accountField.controller?.text, isEmpty);
    expect(passwordField.controller?.text, isEmpty);
  });
}
