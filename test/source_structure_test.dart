import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

int _lineCount(String path) => File(path).readAsLinesSync().length;

void main() {
  test('finance ai core is an importable library outside the app part chain',
      () {
    final main = File('lib/main.dart').readAsStringSync();
    final core =
        File('lib/modules/finance/finance_ai_core.dart').readAsStringSync();

    expect(main, isNot(contains('\npart ')));
    expect(
        main, isNot(contains("part 'modules/finance/finance_ai_core.dart';")));
    expect(core, isNot(contains('part of')));
    expect(core, isNot(contains('IconData')));
    expect(core, isNot(contains('_AiFinanceQuickCommand')));
    expect(core, isNot(contains('FinanceRecord')));
  });

  test('largest auth and health entry files are split into focused parts', () {
    expect(_lineCount('lib/auth/auth.dart'), lessThan(900));
    expect(File('lib/auth/auth_update_pages.dart').existsSync(), isTrue);
    expect(File('lib/auth/auth_visuals.dart').existsSync(), isTrue);

    expect(_lineCount('lib/modules/health/health_module.dart'), lessThan(1200));
    expect(File('lib/modules/health/health_manual_views.dart').existsSync(),
        isTrue);
    expect(File('lib/modules/health/health_metric_views.dart').existsSync(),
        isTrue);
  });

  test('android release disables impeller on emulator-hosted Vulkan', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(
      manifest,
      contains('android:name="io.flutter.embedding.android.EnableImpeller"'),
    );
    expect(manifest, contains('android:value="false"'));
  });

  test('android declares ai image and speech permissions', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android.permission.RECORD_AUDIO'));
    expect(manifest, contains('android.permission.READ_MEDIA_IMAGES'));
    expect(manifest, contains('android.permission.READ_EXTERNAL_STORAGE'));
  });
}
