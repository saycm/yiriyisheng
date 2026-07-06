// 中文注释：自动化测试文件，负责验证对应模块行为和回归场景。

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  testWidgets('stored session enters home when update check is offline',
      (tester) async {
    final previousOverrides = HttpOverrides.current;
    final authCalls = <String>[];
    HttpOverrides.global = _OfflineHttpOverrides();
    const authChannel = MethodChannel('pingsheng_life/auth_session');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      authChannel,
      (call) async {
        authCalls.add(call.method);
        if (call.method == 'loadAuthSession') {
          return jsonEncode({
            'accessToken': 'cached-access-token',
            'refreshToken': 'cached-refresh-token',
            'user': {
              'id': 'cached-user',
              'email': 'cached@example.com',
              'displayName': '本地用户',
            },
          });
        }
        return null;
      },
    );
    addTearDown(() {
      HttpOverrides.global = previousOverrides;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        authChannel,
        null,
      );
    });

    await tester.pumpWidget(
      PingShengApp(
        enableAuth: true,
        updateResponseOverride: () async => throw const SocketException(
          'offline',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('module_glass_header_title_plan')),
        findsOneWidget);
    expect(find.text('创建账号'), findsNothing);
    expect(authCalls, contains('loadAuthSession'));
    expect(authCalls, isNot(contains('clearAuthSession')));
  });

  testWidgets('offline update check falls through to auth page',
      (tester) async {
    const authChannel = MethodChannel('pingsheng_life/auth_session');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      authChannel,
      (call) async => null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        authChannel,
        null,
      );
    });

    await tester.pumpWidget(
      PingShengApp(
        enableAuth: true,
        updateResponseOverride: () async => throw const SocketException(
          'offline',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('正在连接服务端'), findsNothing);
    expect(find.text('创建账号'), findsOneWidget);
    expect(find.text('更新检查暂时不可用，请确认服务器连接。'), findsOneWidget);
  });

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
          'downloadUrl': 'http://192.168.20.11:3000/downloads/pingsheng.apk',
          'message': '发现 1.0.6 新版本，建议更新。',
          'releaseNotes': ['普通更新也要提示'],
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('发现新版本'), findsOneWidget);
    expect(find.text('稍后再说'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
    expect(_visibleTexts().join('\n'), isNot(contains('192.168.20.11')));
  });

  testWidgets('force update hides download url', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      PingShengApp(
        enableAuth: true,
        updateResponseOverride: () async => {
          'latestVersionCode': 8,
          'latestVersionName': '1.0.7',
          'forceUpdate': true,
          'hasUpdate': true,
          'downloadUrl':
              'http://192.168.20.11:3000/downloads/pingsheng-force.apk',
          'message': '需要更新才能继续使用。',
          'releaseNotes': ['强制更新也不能展示地址'],
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('需要更新后继续使用'), findsOneWidget);
    expect(find.text('立即更新'), findsOneWidget);
    expect(
      _visibleTexts().join('\n'),
      isNot(contains('192.168.20.11')),
    );
  });

  testWidgets('auth preview smoke', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp(authPreview: true));
    await tester.pump();

    expect(find.text('创建账号'), findsOneWidget);
    expect(find.text('注册'), findsOneWidget);
    expect(find.textContaining('192.168.'), findsNothing);
    expect(find.textContaining('本地服务'), findsNothing);
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

  testWidgets('login password field uses login wording for every channel',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp(authPreview: true));
    await tester.pump();

    final registerPasswordField =
        tester.widget<TextField>(find.byType(TextField).at(2));
    expect(registerPasswordField.decoration?.hintText, '设置密码');

    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    final emailLoginPasswordField =
        tester.widget<TextField>(find.byType(TextField).at(1));
    expect(emailLoginPasswordField.decoration?.hintText, '输入密码');

    await tester.tap(find.text('手机号'));
    await tester.pumpAndSettle();

    final phoneLoginPasswordField =
        tester.widget<TextField>(find.byType(TextField).at(1));
    expect(phoneLoginPasswordField.decoration?.hintText, '输入密码');
  });
}

class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _OfflineHttpClient();
}

class _OfflineHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      throw const SocketException('offline');

  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      throw const SocketException('offline');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<String> _visibleTexts() {
  final texts = find
      .byType(Text)
      .evaluate()
      .map((element) => element.widget)
      .cast<Text>()
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '');
  final selectableTexts = find
      .byType(SelectableText)
      .evaluate()
      .map((element) => element.widget)
      .cast<SelectableText>()
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '');
  return [...texts, ...selectableTexts];
}
