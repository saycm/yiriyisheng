import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  testWidgets('auth registration preview', (tester) async {
    await _loadPreviewFont();
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

Future<void> _loadPreviewFont() async {
  const fontPaths = [
    r'C:\Windows\Fonts\simhei.ttf',
    r'C:\Windows\Fonts\msyh.ttc',
    r'C:\Windows\Fonts\Deng.ttf',
  ];

  for (final path in fontPaths) {
    final fontFile = File(path);
    if (await fontFile.exists()) {
      final bytes = await fontFile.readAsBytes();
      final loader = FontLoader('sans')
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      try {
        await loader.load().timeout(const Duration(seconds: 6));
        return;
      } on TimeoutException {
        continue;
      } on Exception {
        continue;
      }
    }
  }
}
