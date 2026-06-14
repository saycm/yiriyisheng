import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void mockSystemHealthSnapshot() {
  const channel = MethodChannel('pingsheng_life/system_health');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'loadHealthSnapshot') {
      return {
        'status': 'ok',
        'message': '已连接 Health Connect 和本机传感器。',
        'lastUpdated': '2026-06-05T08:30:00.000Z',
        'sensors': {
          'stepCounterAvailable': true,
          'heartRateSensorAvailable': true,
          'accelerometerAvailable': true,
          'stepCounterSinceBoot': 11880,
          'heartRateBpm': 78.0,
          'accelerationMagnitude': 9.8,
          'lastSensorUpdateMillis': 1780619400000,
        },
        'days': [
          {
            'dateIso': '2026-06-03',
            'steps': 4300,
            'activeCaloriesKcal': 420.0,
            'basalCaloriesKcal': 1588.0,
            'sleepMinutes': 390,
            'heartRateBpm': 84,
            'respiratoryRate': 15.1,
          },
          {
            'dateIso': '2026-06-04',
            'steps': 4814,
            'activeCaloriesKcal': 520.0,
            'basalCaloriesKcal': 1591.0,
            'sleepMinutes': 435,
            'heartRateBpm': 88,
            'respiratoryRate': 15.3,
          },
          {
            'dateIso': '2026-06-05',
            'steps': 6320,
            'activeCaloriesKcal': 610.0,
            'basalCaloriesKcal': 1591.0,
            'sleepMinutes': 408,
            'heartRateBpm': 82,
            'respiratoryRate': 15.8,
          },
        ],
      };
    }
    if (call.method == 'requestHealthPermissions') {
      return {'granted': true, 'grantedCount': 6};
    }
    if (call.method == 'openHealthConnectSettings') {
      return null;
    }
    throw PlatformException(code: 'not_implemented');
  });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
}

Future<void> dragPageUp(WidgetTester tester) async {
  await tester.dragFrom(const Offset(300, 500), const Offset(0, -360));
  await tester.pumpAndSettle();
}

Future<void> dragPageDown(WidgetTester tester) async {
  await tester.dragFrom(const Offset(300, 220), const Offset(0, 360));
  await tester.pumpAndSettle();
}

Future<void> dragUntilFound(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  bool up = true,
  int maxDrags = 8,
}) async {
  for (var index = 0; index < maxDrags && finder.evaluate().isEmpty; index++) {
    await tester.drag(
      scrollable ?? find.byType(Scrollable).first,
      Offset(0, up ? -360 : 360),
    );
    await tester.pumpAndSettle();
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  test('ai finance parser handles markdown json array', () {
    const parser = AiFinanceJsonParser();
    final bills = parser.parse('''
```json
[
  {"amount":-50,"time":"2026-06-05T12:00:00","note":"午饭","category":"三餐","type":"expense",},
  {"amount":3000,"time":"2026-06-05T09:00:00","note":"工资","category":"工资","type":"income"}
]
```
''');

    expect(bills, hasLength(2));
    expect(bills.first.amount, -50);
    expect(bills.first.category, '三餐');
    expect(bills.last.type, AiFinanceBillType.income);
  });

  testWidgets('plan page opens add todo sheet', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    expect(find.text('今日计划  4'), findsOneWidget);

    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();

    expect(find.text('新增待办'), findsOneWidget);
    expect(find.text('优先级'), findsOneWidget);
    expect(find.text('任务联动'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('plan more menu filters category and clears completed todos',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('待办选项'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('plan_filter_工作')));
    await tester.pumpAndSettle();

    expect(find.text('今日计划  1 · 工作'), findsOneWidget);
    expect(find.text('做报表'), findsOneWidget);
    expect(find.text('遛狗'), findsNothing);

    await tester.tap(find.text('做报表'));
    await tester.pumpAndSettle();

    expect(find.text('这个类别没有待办'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_1')));
    await tester.pumpAndSettle();

    expect(find.text('待办箱  1'), findsOneWidget);
    expect(find.text('整理学习清单'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('清理已完成 (1)'));
    await tester.pumpAndSettle();

    expect(find.text('已完成  0'), findsOneWidget);
    expect(find.text('做报表'), findsNothing);

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('今日联动'), findsOneWidget);
    expect(find.text('5 项'), findsOneWidget);
  });

  testWidgets('completed linked todo opens target module action',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await dragPageUp(tester);
    expect(find.text('还信用卡'), findsOneWidget);
    await tester.tap(find.text('还信用卡'));
    await tester.pumpAndSettle();

    expect(find.text('继续记录'), findsOneWidget);
    expect(find.text('去记账'), findsOneWidget);

    await tester.tap(find.text('去记账'));
    await tester.pumpAndSettle();

    expect(find.text('财务'), findsWidgets);
    expect(find.text('记一笔'), findsWidgets);
    expect(find.byKey(const ValueKey('finance_record_amount')), findsOneWidget);
  });

  testWidgets('module sheet switches to finance overview', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('功能模块'), findsWidgets);

    final financeTile = find.byKey(const ValueKey('module_sheet_finance'));
    await tester.scrollUntilVisible(
      financeTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(financeTile);
    await tester.pumpAndSettle();

    expect(find.text('净资产'), findsWidgets);
    expect(find.text('¥1,555.00'), findsOneWidget);
  });

  testWidgets('module settings opens and options are interactive',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final settingsTile = find.byKey(const ValueKey('module_sheet_settings'));
    await tester.scrollUntilVisible(
      settingsTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(settingsTile);
    await tester.pumpAndSettle();

    expect(find.text('桌面小组件'), findsOneWidget);
    expect(find.text('快捷按钮直接记录'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('setting_widget_direct_record')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('setting_choice_晚餐')));
    await tester.pumpAndSettle();

    expect(find.text('默认餐次'), findsOneWidget);
    expect(find.text('晚餐'), findsWidgets);

    final qaTile = find.text('Q&A');
    await tester.scrollUntilVisible(
      qaTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(qaTile);
    await tester.pumpAndSettle();

    expect(find.text('健康模块的数据从哪里来？'), findsOneWidget);
    await tester.tap(find.text('健康模块的数据从哪里来？'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Health Connect'), findsWidgets);
  });

  testWidgets('module heat map day opens linked detail sheet', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_heat_day_1')));
    await tester.pumpAndSettle();

    expect(find.text('2026年5月1日'), findsOneWidget);
    expect(find.text('计划待办'), findsOneWidget);
    expect(find.text('饮食记录'), findsOneWidget);
    expect(find.text('锻炼记录'), findsOneWidget);
    expect(find.text('健康总览'), findsOneWidget);
  });

  testWidgets('module link strip jumps between every main module',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    expect(find.text('今日计划  4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    expect(find.text('净资产'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();
    expect(find.text('添加食物'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    expect(find.text('胸背'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();
    expect(find.textContaining('系统健康'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('module_link_1')));
    await tester.pumpAndSettle();
    expect(find.text('今日计划  4'), findsOneWidget);
  });

  testWidgets('home widget initial route opens target module', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/finance';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await tester.pumpWidget(const PingShengApp());

    expect(find.text('净资产'), findsWidgets);
    expect(find.text('¥1,555.00'), findsOneWidget);
  });

  testWidgets('home widget quick route opens finance detail sheet',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/finance?action=add_finance';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    expect(find.text('记一笔'), findsWidgets);
    expect(find.byKey(const ValueKey('finance_record_amount')), findsOneWidget);
  });

  testWidgets('home widget quick route opens food custom sheet',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/food?action=add_food';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    expect(find.text('自定义食物'), findsWidgets);
    expect(find.text('食物名称'), findsOneWidget);
  });

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

  testWidgets('linked summary restores and syncs with home widget',
      (tester) async {
    const channel = MethodChannel('pingsheng_life/widget_summary');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'loadLifeSummary') {
        return {
          'foodCalories': 168,
          'workoutGroups': 2,
          'workoutGroupsJson': '{"蝴蝶机夹胸":2}',
          'todosJson':
              '[{"title":"写周报","category":"工作","done":false},{"title":"复盘","category":"生活","done":true}]',
        };
      }
      if (call.method == 'saveLifeSummary') {
        return null;
      }
      throw PlatformException(code: 'not_implemented');
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('今日联动'), findsOneWidget);
    expect(find.text('1 项'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();

    await dragPageUp(tester);
    expect(find.text('168 kcal'), findsOneWidget);
    expect(find.text('2 组'), findsOneWidget);

    await dragPageDown(tester);
    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录').last);
    await tester.pumpAndSettle();

    final saveCall = calls.lastWhere(
      (call) => call.method == 'saveLifeSummary',
    );
    final args = saveCall.arguments as Map<Object?, Object?>;
    expect(args['foodCalories'], 248);
    expect(args['pendingTodos'], 1);
    expect(args['todosJson'], contains('写周报'));
    expect(args['financeRecordsJson'], contains('工资'));
    expect(args['workoutGroups'], 2);
    expect(args['workoutGroupsJson'], contains('蝴蝶机夹胸'));
  });

  testWidgets('workout bottom nav switches between health and food',
      (tester) async {
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

    expect(find.text('胸背'), findsOneWidget);

    await tester.tap(find.text('总览').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('系统健康'), findsWidgets);

    await tester.tap(find.text('锻炼').last);
    await tester.pumpAndSettle();

    expect(find.text('胸背'), findsOneWidget);

    await tester.tap(find.text('饮食').last);
    await tester.pumpAndSettle();

    expect(find.text('添加食物'), findsOneWidget);
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

    await tester.tap(find.text('总览').last);
    await tester.pumpAndSettle();

    expect(find.text('6月5日⌄'), findsOneWidget);
    expect(find.text('系统健康数据已连接'), findsOneWidget);

    await tester.tap(find.text('4').first);
    await tester.pumpAndSettle();

    expect(find.text('6月4日⌄'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.grid_view_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('健康总览'), findsOneWidget);
    expect(find.text('活动完成'), findsOneWidget);
    expect(find.text('48%'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    await dragPageUp(tester);
    await dragPageUp(tester);
    final stepsMetric = find.text('今日步数');
    expect(stepsMetric, findsOneWidget);
    await tester.tap(stepsMetric);
    await tester.pumpAndSettle();

    expect(find.text('4,814 步'), findsOneWidget);
    expect(find.text('趋势摘要'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
  });

  testWidgets('finance records filter income and expense', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final financeTile = find.byKey(const ValueKey('module_sheet_finance'));
    await tester.scrollUntilVisible(
      financeTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(financeTile);
    await tester.pumpAndSettle();

    await tester.tap(find.text('记录').last);
    await tester.pumpAndSettle();

    expect(find.text('工资'), findsOneWidget);
    expect(find.text('三餐'), findsOneWidget);

    await tester.tap(find.text('收入').last);
    await tester.pumpAndSettle();

    expect(find.text('工资'), findsOneWidget);
    expect(find.text('三餐'), findsNothing);

    await tester.tap(find.text('支出').last);
    await tester.pumpAndSettle();

    expect(find.text('工资'), findsNothing);
    expect(find.text('三餐'), findsOneWidget);
  });

  testWidgets('finance records can be added and edited', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('finance_add_record')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('收入').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('理财收益'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_title')),
      '奖金',
    );
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_subtitle')),
      '项目奖励',
    );
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_amount')),
      '888',
    );
    await tester.tap(find.byKey(const ValueKey('save_finance_record')));
    await tester.pumpAndSettle();

    expect(find.text('奖金'), findsOneWidget);
    expect(find.text('+¥888.00'), findsOneWidget);

    await tester.tap(find.text('奖金'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_subtitle')),
      '调整后的奖励',
    );
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_amount')),
      '1288',
    );
    await tester.tap(find.byKey(const ValueKey('save_finance_record')));
    await tester.pumpAndSettle();

    expect(find.text('调整后的奖励'), findsOneWidget);
    expect(find.text('+¥1,288.00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录').last);
    await tester.pumpAndSettle();

    expect(find.text('奖金'), findsOneWidget);
    expect(find.text('调整后的奖励'), findsOneWidget);
    expect(find.text('+¥1,288.00'), findsOneWidget);
  });

  testWidgets('finance ai accounting opens and requires api key',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('finance_ai_record')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('finance_ai_record')));
    await tester.pumpAndSettle();

    expect(find.text('AI 记账'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('ai_finance_input')),
      '昨天中午吃饭50，晚上奶茶12',
    );
    await tester.tap(find.byKey(const ValueKey('run_ai_finance_parse')));
    await tester.pumpAndSettle();

    expect(find.text('请先填写 AI 接口 Key'), findsOneWidget);
  });

  testWidgets('finance overview opens assets and switches trend range',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final financeTile = find.byKey(const ValueKey('module_sheet_finance'));
    await tester.scrollUntilVisible(
      financeTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(financeTile);
    await tester.pumpAndSettle();

    await tester.tap(find.text('查看资产详情'));
    await tester.pumpAndSettle();

    expect(find.text('资产占比'), findsOneWidget);
    expect(find.text('银行卡'), findsOneWidget);
    expect(find.text('招商储蓄卡'), findsOneWidget);

    await tester.tap(find.text('总览').last);
    await tester.pumpAndSettle();

    expect(find.text('本月预算'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('支出分类'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('支出分类'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('最近记录'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('最近记录'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('7天支出 ¥44'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('7天支出 ¥44'), findsOneWidget);

    await tester.ensureVisible(find.text('6个月'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6个月'));
    await tester.pumpAndSettle();
    expect(find.text('6个月支出 ¥2652'), findsOneWidget);

    await tester.tap(find.text('收入'));
    await tester.pumpAndSettle();
    expect(find.text('6个月收入 ¥18000'), findsOneWidget);
  });

  testWidgets('workout top tabs show plan data and history', (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();
    expect(find.text('胸背强化'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_2')));
    await tester.pumpAndSettle();
    expect(find.text('已完成组数'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_3')));
    await tester.pumpAndSettle();
    expect(find.text('肩颈恢复'), findsOneWidget);
  });

  testWidgets('workout finished set updates list summary and data',
      (tester) async {
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

    expect(find.text('0/19 组'), findsOneWidget);
    expect(find.text('0/4 组 ›'), findsWidgets);

    await tester.tap(find.text('开始动作'));
    await tester.pumpAndSettle();

    expect(find.text('蝴蝶机夹胸'), findsWidgets);
    expect(find.text('0/4'), findsOneWidget);

    await tester.tap(find.text('开始动作'));
    await tester.pumpAndSettle();

    expect(find.text('1/4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('1/19 组'), findsOneWidget);
    expect(find.text('1/4 组 ›'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_2')));
    await tester.pumpAndSettle();

    expect(find.text('1/19'), findsOneWidget);
    expect(find.text('2 min'), findsOneWidget);
    expect(find.text('538'), findsOneWidget);
  });

  testWidgets('food and workout records update health linked summary',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();

    await dragPageUp(tester);
    expect(find.text('模块联动'), findsOneWidget);
    expect(find.text('80 kcal'), findsOneWidget);

    await dragPageDown(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始动作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始动作'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('锻炼联动'), findsOneWidget);
    expect(find.text('80 kcal'), findsWidgets);
    expect(find.text('1 组'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();

    await dragPageUp(tester);
    expect(find.text('80 kcal'), findsOneWidget);
    expect(find.text('1 组'), findsOneWidget);

    await dragPageDown(tester);
    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();

    await dragPageUp(tester);
    expect(find.text('财务联动'), findsOneWidget);
    expect(find.text('80 kcal'), findsWidgets);
    expect(find.text('1 组'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();

    expect(find.text('饮食联动'), findsOneWidget);
    expect(find.text('80 kcal'), findsWidgets);
    expect(find.text('1 组'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('module_link_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_3')));
    await tester.pumpAndSettle();

    expect(find.text('计划联动'), findsOneWidget);
    expect(find.text('80 kcal'), findsWidgets);
    expect(find.text('1 组'), findsWidgets);
    await dragPageUp(tester);
    expect(find.text('联动记录'), findsOneWidget);
    expect(find.text('记录饮食'), findsOneWidget);
    expect(find.text('完成锻炼'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('今日联动'), findsOneWidget);
    expect(find.text('联动记录'), findsOneWidget);
    expect(find.text('记录饮食'), findsOneWidget);
    expect(find.text('完成锻炼'), findsOneWidget);
    expect(find.text('6 项'), findsOneWidget);
    expect(find.text('80 kcal'), findsWidgets);
    expect(find.text('1 组'), findsWidgets);
  });

  testWidgets('food search filters items and custom food can be added',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final foodTile = find.byKey(const ValueKey('module_sheet_food'));
    await tester.scrollUntilVisible(
      foodTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(foodTile);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('food_group_主食杂粮')));
    await tester.pumpAndSettle();
    expect(find.text('米饭'), findsOneWidget);
    expect(find.text('鸡胸肉'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('food_group_肉蛋奶')));
    await tester.pumpAndSettle();
    expect(find.text('鸡胸肉'), findsWidgets);
    expect(find.text('米饭'), findsNothing);

    final groupScroller = find.byKey(const ValueKey('food_group_scroller'));
    await tester.drag(groupScroller, const Offset(-360, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('food_group_低脂高蛋白')));
    await tester.pumpAndSettle();
    expect(find.text('希腊酸奶'), findsOneWidget);

    await tester.drag(groupScroller, const Offset(-520, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('food_group_外卖快餐')));
    await tester.pumpAndSettle();
    expect(find.text('麻辣烫'), findsOneWidget);

    await tester.drag(groupScroller, const Offset(900, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('food_group_常见')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('food_search_field')), '鸡胸肉');
    await tester.pumpAndSettle();

    expect(find.text('鸡胸肉'), findsWidgets);

    await tester.enterText(find.byKey(const ValueKey('food_search_field')), '');
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('food_search_field')), '披萨');
    await tester.pumpAndSettle();

    expect(find.text('披萨（芝士）'), findsOneWidget);
    expect(find.text('混合沙拉'), findsNothing);

    await tester.tap(find.text('自定义').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_custom_food_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('custom_food_name')), '燕麦酸奶');
    await tester.enterText(
        find.byKey(const ValueKey('custom_food_calorie')), '168');
    await tester.enterText(
        find.byKey(const ValueKey('custom_food_unit')), '1 碗');
    await tester.tap(find.byKey(const ValueKey('save_custom_food_button')));
    await tester.pumpAndSettle();

    expect(find.text('燕麦酸奶'), findsOneWidget);
    expect(find.text('168 千卡 / 1 碗'), findsOneWidget);
  });

  testWidgets('food templates and meal summary update nutrition view',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final foodTile = find.byKey(const ValueKey('module_sheet_food'));
    await tester.scrollUntilVisible(
      foodTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(foodTile);
    await tester.pumpAndSettle();

    final foodList = find.byKey(const ValueKey('food_main_list'));
    final trainingSnack = find.byKey(const ValueKey('food_template_训练后加餐'));
    await dragUntilFound(tester, trainingSnack, scrollable: foodList);
    await tester.tap(trainingSnack);
    await tester.pumpAndSettle();

    expect(find.textContaining('已选 2 项'), findsOneWidget);
    expect(find.textContaining('加餐'), findsWidgets);
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('food_calorie_progress_card')),
      scrollable: foodList,
      up: false,
    );
    expect(find.text('今日热量'), findsOneWidget);
    expect(find.text('蛋白质'), findsOneWidget);
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('food_trend_block')),
      scrollable: foodList,
    );
    expect(find.text('7 天热量趋势'), findsOneWidget);
  });

  testWidgets('workout feedback rest timer and food link are interactive',
      (tester) async {
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

    await tester.tap(find.text('开始动作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始动作'));
    await tester.pumpAndSettle();

    expect(find.text('2:00'), findsOneWidget);
    final workoutDetailList =
        find.byKey(const ValueKey('workout_action_detail_list'));
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('workout_feedback_card')),
      scrollable: workoutDetailList,
    );
    expect(find.text('训练反馈'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workout_feedback_太累')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.byIcon(Icons.arrow_back_ios_new_rounded),
      scrollable: workoutDetailList,
      up: false,
    );
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    await tester.pumpAndSettle();
    final workoutList = find.byKey(const ValueKey('workout_main_list'));
    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('workout_today_stats_card')),
      scrollable: workoutList,
    );
    expect(find.text('太累'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('workout_food_link_card')),
      scrollable: workoutList,
    );
    expect(find.textContaining('加餐'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('workout_open_food_link')));
    await tester.pumpAndSettle();
    expect(find.text('添加食物'), findsOneWidget);
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
}
