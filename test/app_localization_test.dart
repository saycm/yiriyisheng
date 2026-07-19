// 中文注释：自动化测试文件，负责验证 App 系统级本地化行为。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  setUp(mockDefaultWidgetSummary);

  testWidgets('material system actions use simplified Chinese labels',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    final capturedContext = tester.element(find.byType(Scaffold).first);
    final localizations = MaterialLocalizations.of(capturedContext);
    expect(localizations.copyButtonLabel, '复制');
    expect(localizations.pasteButtonLabel, '粘贴');
    expect(localizations.cutButtonLabel, '剪切');
    expect(localizations.selectAllButtonLabel, '全选');
  });
}
