// 中文注释：自动化测试文件，负责验证对应模块行为和回归场景。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  testWidgets('health module link strip fits narrow screens', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('module_link_4')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('health module shows status center before external data source',
      (tester) async {
    mockSystemHealthStatus(
      status: 'permissionRequired',
      message: '还没有授予步数、睡眠和心率权限。',
    );
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
    addTearDown(
      () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
    );

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    expect(find.text('今日状态'), findsWidgets);
    expect(find.text('状态中心'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('health_status_score_card')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('health_quick_record_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('health_external_source_entry')),
        findsOneWidget);

    final statusTop = tester
        .getTopLeft(find.byKey(const ValueKey('health_status_score_card')))
        .dy;
    final externalTop = tester
        .getTopLeft(find.byKey(const ValueKey('health_external_source_entry')))
        .dy;
    expect(statusTop, lessThan(externalTop));
    expect(find.text('Health Connect 未授权'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('health_external_source_entry')),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('health_main_list')),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('health_manual_status_card')), findsNothing);
    expect(find.byKey(const ValueKey('health_reminder_card')), findsNothing);
    expect(find.byKey(const ValueKey('health_trend_dashboard_card')),
        findsNothing);
    expect(find.text('手机传感器'), findsNothing);
  });

  testWidgets('status center opens summary and shows external source entry',
      (tester) async {
    mockSystemHealthSnapshot();

    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final workoutTile = find.byKey(const ValueKey('module_sheet_workout'));
    await tester.scrollUntilVisible(
      workoutTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(workoutTile);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('module_glass_header_title_health')),
        findsOneWidget);
    expect(find.text('5'), findsWidgets);
    expect(find.text('今日状态'), findsWidgets);
    expect(find.text('状态中心'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('health_status_score_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('health_impact_card')), findsOneWidget);

    await tester.tap(find.text('4').first);
    await tester.pumpAndSettle();

    expect(find.text('4'), findsWidgets);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('健康总览'), findsOneWidget);
    expect(find.text('活动完成'), findsOneWidget);
    expect(find.text('48%'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    final healthList = find.byKey(const ValueKey('health_main_list'));
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('health_status_suggestion_card')),
      scrollable: healthList,
    );
    expect(find.text('状态建议'), findsOneWidget);
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('health_status_trend_card')),
      scrollable: healthList,
    );
    expect(find.text('状态趋势'), findsOneWidget);
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('health_external_source_entry')),
      scrollable: healthList,
    );
    expect(find.text('外部数据源'), findsOneWidget);
  });

  testWidgets('health manual body record updates status center',
      (tester) async {
    mockSystemHealthSnapshot();
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
    addTearDown(
      () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
    );

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('记录状态'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('health_body_tag_疲惫')));
    await tester.enterText(
        find.byKey(const ValueKey('health_pain_note')), '肩颈紧');
    await tester.enterText(
        find.byKey(const ValueKey('health_mood_note')), '焦虑');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final saveHealthRecord =
        find.byKey(const ValueKey('save_health_manual_record'));
    await tester.ensureVisible(saveHealthRecord);
    await tester.pumpAndSettle();
    await tester.tap(saveHealthRecord);
    await tester.pumpAndSettle();

    expect(find.text('精力偏低'), findsWidgets);
    expect(find.text('肩颈不适'), findsWidgets);
    expect(find.text('焦虑'), findsWidgets);
    expect(find.text('身体有不适'), findsOneWidget);
  });

  testWidgets('saving unchanged health record keeps default stress feeling',
      (tester) async {
    mockSystemHealthSnapshot();
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
    addTearDown(
      () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
    );

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('记录状态'));
    await tester.pumpAndSettle();
    final saveHealthRecord =
        find.byKey(const ValueKey('save_health_manual_record'));
    await tester.ensureVisible(saveHealthRecord);
    await tester.pumpAndSettle();
    await tester.tap(saveHealthRecord);
    await tester.pumpAndSettle();

    expect(find.text('压力中等'), findsWidgets);
    expect(find.text('压力较低'), findsNothing);
  });

  testWidgets('quick status record updates score and suggestions',
      (tester) async {
    mockSystemHealthStatus(
      status: 'permissionRequired',
      message: '还没有授予步数、睡眠和心率权限。',
    );
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
    addTearDown(
      () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
    );

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('health_quick_sleep_poor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('health_quick_stress_high')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('health_quick_body_neckPain')));
    await tester.pumpAndSettle();

    expect(find.text('负载偏高'), findsWidgets);
    expect(find.textContaining('压力偏高'), findsWidgets);
    expect(find.textContaining('肩颈不适'), findsWidgets);
  });

  testWidgets('manual save preserves quick status selections', (tester) async {
    mockSystemHealthStatus(
      status: 'permissionRequired',
      message: '还没有授予步数、睡眠和心率权限。',
    );
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
    addTearDown(
      () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
    );

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('health_quick_sleep_poor')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('health_quick_stress_high')));
    await tester.pumpAndSettle();
    final happyMood = find.byKey(const ValueKey('health_quick_mood_happy'));
    await tester.ensureVisible(happyMood);
    await tester.pumpAndSettle();
    await tester.tap(happyMood);
    await tester.pumpAndSettle();

    final recordStatus = find.text('记录状态');
    await tester.ensureVisible(recordStatus);
    await tester.pumpAndSettle();
    await tester.tap(recordStatus);
    await tester.pumpAndSettle();
    final saveHealthRecord =
        find.byKey(const ValueKey('save_health_manual_record'));
    await tester.ensureVisible(saveHealthRecord);
    await tester.pumpAndSettle();
    await tester.tap(saveHealthRecord);
    await tester.pumpAndSettle();

    expect(find.textContaining('睡眠感较差'), findsWidgets);
    expect(find.textContaining('压力偏高'), findsWidgets);
    expect(find.textContaining('心情不错'), findsWidgets);
    expect(find.text('睡眠一般'), findsNothing);
  });

  testWidgets('health connect status stays behind optional source entry',
      (tester) async {
    Future<void> pumpHealthWithStatus({
      required String status,
      required String message,
      List<Map<String, Object?>> days = const [],
    }) async {
      mockSystemHealthStatus(status: status, message: message, days: days);
      tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
      await tester.pumpWidget(const PingShengApp());
      await tester.pumpAndSettle();
      addTearDown(
        () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
      );
    }

    await pumpHealthWithStatus(
      status: 'permissionRequired',
      message: '还没有授予步数、睡眠和心率权限。',
    );
    expect(find.text('状态中心'), findsOneWidget);
    expect(find.byKey(const ValueKey('health_external_source_entry')),
        findsOneWidget);
    expect(find.text('Health Connect 未授权'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHealthWithStatus(
      status: 'unavailable',
      message: '未安装 Health Connect 或当前系统不支持。',
    );
    expect(find.text('今日状态'), findsWidgets);
    expect(find.text('需要安装 Health Connect'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHealthWithStatus(
      status: 'updateRequired',
      message: 'Health Connect 版本过低。',
    );
    expect(find.byKey(const ValueKey('health_external_source_entry')),
        findsOneWidget);
    expect(find.text('需要更新 Health Connect'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHealthWithStatus(
      status: 'ok',
      message: '已授权，但暂时没有读取到今天的数据。',
      days: [
        {'dateIso': '2026-06-05'},
      ],
    );
    expect(find.text('外部数据源'), findsOneWidget);
    expect(find.text('Health Connect 已连接，暂无数据'), findsNothing);
    expect(find.text('数据为空'), findsNothing);
  });
}
