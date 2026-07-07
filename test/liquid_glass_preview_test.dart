// 中文注释：液态玻璃新版 UI 预览页测试，负责守住预览入口和核心视觉元素。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  setUp(mockDefaultWidgetSummary);

  testWidgets('liquid glass preview route opens project preview page',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await pumpPingShengApp(tester);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/liquid-glass-preview');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('liquid_glass_preview_page')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('liquid_glass_preview_nav')), findsOneWidget);
    expect(find.text('计划'), findsWidgets);
    expect(find.text('财务'), findsOneWidget);
    expect(find.text('饮食'), findsOneWidget);
    expect(find.text('锻炼'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);
    expect(find.text('今日'), findsOneWidget);
    expect(find.text('待办箱'), findsOneWidget);
    expect(find.text('周计划'), findsOneWidget);
    expect(find.text('复盘'), findsOneWidget);
    expect(find.text('7天任务板'), findsOneWidget);
    expect(find.text('今日支出'), findsOneWidget);
  });
}
