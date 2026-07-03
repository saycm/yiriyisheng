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

  testWidgets('health date switch opens metric detail and summary',
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
    expect(find.text('系统健康数据已连接'), findsOneWidget);

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
    final stepsMetric = find.text('今日步数');
    await dragUntilFound(tester, stepsMetric, scrollable: healthList);
    expect(stepsMetric, findsOneWidget);
    await tester.tap(stepsMetric);
    await tester.pumpAndSettle();

    expect(find.text('4,814 步'), findsOneWidget);
    expect(find.text('趋势摘要'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
  });

  testWidgets('health manual body record updates dashboard', (tester) async {
    mockSystemHealthSnapshot();
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
    addTearDown(
      () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
    );

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    final healthList = find.byKey(const ValueKey('health_main_list'));
    final manualCard = find.byKey(const ValueKey('health_manual_status_card'));
    await dragUntilFound(tester, manualCard, scrollable: healthList);
    await tester.tap(manualCard);
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

    expect(find.textContaining('疲惫'), findsWidgets);
    expect(find.text('肩颈紧'), findsOneWidget);
    await dragPageDown(tester);
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('health_reminder_card')),
      scrollable: healthList,
    );
    expect(find.text('健康提醒'), findsOneWidget);
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('health_trend_dashboard_card')),
      scrollable: healthList,
    );
    expect(find.text('最近 7 天趋势'), findsOneWidget);
  });

  testWidgets('health connect status explains setup and empty data states',
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
    expect(find.text('Health Connect 未授权'), findsOneWidget);
    expect(find.textContaining('授予步数、睡眠和心率权限'), findsOneWidget);
    expect(find.text('去授权'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHealthWithStatus(
      status: 'unavailable',
      message: '未安装 Health Connect 或当前系统不支持。',
    );
    expect(find.text('需要安装 Health Connect'), findsOneWidget);
    expect(find.text('去安装'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHealthWithStatus(
      status: 'updateRequired',
      message: 'Health Connect 版本过低。',
    );
    expect(find.text('需要更新 Health Connect'), findsOneWidget);
    expect(find.text('去更新'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHealthWithStatus(
      status: 'ok',
      message: '已授权，但暂时没有读取到今天的数据。',
      days: [
        {'dateIso': '2026-06-05'},
      ],
    );
    expect(find.text('Health Connect 已连接，暂无数据'), findsOneWidget);
    expect(find.text('数据为空'), findsOneWidget);
    expect(find.text('打开设置'), findsOneWidget);
  });
}
