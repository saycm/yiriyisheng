import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preview font loads', () async {
    final fontFile = File(r'C:\Windows\Fonts\simhei.ttf');
    expect(await fontFile.exists(), isTrue);

    final bytes = await fontFile.readAsBytes();
    final loader = FontLoader('sans')
      ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));

    await loader.load().timeout(const Duration(seconds: 10));
  });
}
