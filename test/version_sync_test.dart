import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app update version defaults match pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final appConfig = File('lib/app/app.dart').readAsStringSync();

    final pubspecVersion = RegExp(r'^version:\s*([0-9.]+)\+([0-9]+)\s*$',
            multiLine: true)
        .firstMatch(pubspec);
    expect(pubspecVersion, isNotNull);

    final appVersionName = RegExp(
      r"PINGSHENG_APP_VERSION_NAME'[\s\S]*?defaultValue:\s*'([^']+)'",
    ).firstMatch(appConfig);
    final appVersionCode = RegExp(
      r'PINGSHENG_APP_VERSION_CODE[\s\S]*?defaultValue:\s*([0-9]+)',
    ).firstMatch(appConfig);
    expect(appVersionName, isNotNull);
    expect(appVersionCode, isNotNull);

    expect(appVersionName!.group(1), pubspecVersion!.group(1));
    expect(appVersionCode!.group(1), pubspecVersion.group(2));
  });
}
