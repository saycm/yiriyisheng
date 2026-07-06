// 中文注释：自动化测试文件，负责验证对应模块行为和回归场景。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/api/feedback_api.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  setUp(mockDefaultWidgetSummary);

  testWidgets('module sheet switches to finance overview', (tester) async {
    await pumpPingShengApp(tester);

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

    expect(find.text('资产工作台'), findsOneWidget);
    expect(find.text('¥2,476.00'), findsWidgets);
    expect(find.text('¥1,555.00'), findsNothing);
    await dragUntilFound(
      tester,
      find.text('分类预算'),
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('分类预算'), findsOneWidget);
    expect(find.byKey(const ValueKey('finance_ai_record')), findsOneWidget);
  });

  testWidgets('module settings opens and options are interactive',
      (tester) async {
    final preferenceCalls = <MethodCall>[];
    const preferencesChannel = MethodChannel('pingsheng_life/app_preferences');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      preferencesChannel,
      (call) async {
        preferenceCalls.add(call);
        switch (call.method) {
          case 'loadAppPreferences':
            return {
              'themeMode': 'system',
              'dailyRecordReminderEnabled': false,
            };
          case 'saveThemeMode':
            return null;
          case 'setDailyRecordReminder':
            return {
              'enabled': call.arguments['enabled'] as bool,
              'permissionGranted': true,
            };
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        preferencesChannel,
        null,
      );
    });

    await pumpPingShengApp(tester);

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
    expect(find.text('刷新桌面小组件'), findsNothing);
    expect(find.text('导出本地记录'), findsNothing);

    expect(find.text('外观模式'), findsNothing);
    expect(find.byKey(const ValueKey('setting_choice_深色')), findsNothing);
    expect(
        preferenceCalls.any((call) => call.method == 'saveThemeMode'), isFalse);

    final dailyReminder = find.byKey(const ValueKey('setting_daily_reminder'));
    await tester.ensureVisible(dailyReminder);
    await tester.pumpAndSettle();
    await tester.tap(dailyReminder);
    await tester.pumpAndSettle();

    expect(find.text('每日记录提醒已开启'), findsOneWidget);
    expect(
      preferenceCalls.any(
        (call) =>
            call.method == 'setDailyRecordReminder' &&
            call.arguments['enabled'] == true,
      ),
      isTrue,
    );

    final qaTile = find.text('Q&A');
    await tester.scrollUntilVisible(
      qaTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(qaTile);
    await tester.pumpAndSettle();

    expect(find.text('状态中心的数据从哪里来？'), findsOneWidget);
    await tester.tap(find.text('状态中心的数据从哪里来？'));
    await tester.pumpAndSettle();
    expect(find.textContaining('手动状态记录'), findsWidgets);
    expect(find.textContaining('Health Connect 是可选数据源'), findsWidgets);
  });

  testWidgets('module sheet presents compact module center content',
      (tester) async {
    await pumpPingShengApp(tester);

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('功能模块'), findsWidgets);
    expect(find.byKey(const ValueKey('module_today_summary')), findsOneWidget);
    expect(find.text('今日状态'), findsOneWidget);
    expect(find.text('待办 6 项'), findsOneWidget);
    expect(find.text('饮食 0 kcal'), findsOneWidget);
    expect(find.text('锻炼 0 组'), findsOneWidget);

    expect(find.byKey(const ValueKey('module_sheet_plan')), findsOneWidget);
    expect(find.byKey(const ValueKey('module_sheet_finance')), findsOneWidget);
    expect(find.byKey(const ValueKey('module_sheet_food')), findsOneWidget);
    expect(find.byKey(const ValueKey('module_sheet_workout')), findsOneWidget);
    expect(find.byKey(const ValueKey('module_sheet_health')), findsOneWidget);
    expect(find.byKey(const ValueKey('module_sheet_settings')), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('module_sheet_finance')),
        matching: find.text('今日支出 ¥524'),
      ),
      findsOneWidget,
    );
    expect(find.text('最近动态'), findsOneWidget);
    expect(find.text('今天还没有新记录'), findsOneWidget);
    expect(find.text('热力图'), findsNothing);
  });

  testWidgets('module sheet shows recent activity after app actions',
      (tester) async {
    await pumpPingShengApp(tester);

    await dragUntilFound(
      tester,
      find.text('遛狗'),
      scrollable: find.byType(Scrollable).last,
    );
    final dogCard = find.byKey(const ValueKey('todo_card_遛狗'));
    await tester.tap(find.descendant(of: dogCard, matching: find.text('完成')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('最近动态'), findsOneWidget);
    expect(find.text('完成待办'), findsOneWidget);
    expect(find.text('遛狗'), findsWidgets);
    expect(find.text('待办 5 项'), findsOneWidget);
  });

  testWidgets('module link strip is compact and inner nav stays at bottom',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await pumpPingShengApp(tester);
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('module_glass_header'));
    expect(tester.getSize(header).height, lessThanOrEqualTo(38));

    final mainLink = find.byKey(const ValueKey('module_link_1'));
    expect(tester.getSize(mainLink).height, lessThanOrEqualTo(36));

    final dateButton = find.byKey(const ValueKey('plan_header_date_button'));
    expect(tester.getSize(dateButton).height, lessThanOrEqualTo(30));
    expect(tester.getBottomLeft(dateButton).dy, lessThanOrEqualTo(155));

    final innerNav = find.byKey(const ValueKey('plan_bottom_nav_0'));
    expect(tester.getSize(innerNav).width, lessThanOrEqualTo(66));
    expect(tester.getSize(innerNav).height, lessThanOrEqualTo(42));

    final innerNavFrame =
        find.byKey(const ValueKey('plan_bottom_nav_container'));
    expect(innerNavFrame, findsOneWidget);

    final frame = tester.widget<Container>(innerNavFrame);
    final decoration = frame.decoration! as BoxDecoration;
    final borderRadius = decoration.borderRadius! as BorderRadius;
    expect(borderRadius.topLeft.x, lessThanOrEqualTo(14));

    final innerTop = tester.getTopLeft(innerNavFrame).dy;
    final mainTop = tester.getTopLeft(mainLink).dy;
    expect(mainTop, lessThan(innerTop));
    expect(mainTop, lessThanOrEqualTo(220));
    expect(innerTop, greaterThanOrEqualTo(720));

    await tester.tap(find.byKey(const ValueKey('plan_header_date_button')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('plan_glass_date_picker')), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
  });

  testWidgets('main modules share the unified glass header', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await pumpPingShengApp(tester);
    await tester.pumpAndSettle();

    final modules = [
      (1, 'plan', '计划'),
      (0, 'finance', '财务'),
      (2, 'food', '饮食'),
      (3, 'workout', '锻炼'),
      (4, 'health', '健康'),
    ];

    for (final module in modules) {
      await tester.tap(find.byKey(ValueKey('module_link_${module.$1}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('module_glass_header')), findsOneWidget);
      expect(
        find.byKey(ValueKey('module_glass_header_title_${module.$2}')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('module_link_glass_container')),
          findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('module_link_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan_header_date_button')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('plan_glass_date_picker')), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
  });

  testWidgets('finance workout and health bottom navs use compact capsules',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await pumpPingShengApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final financeNav = find.byKey(const ValueKey('finance_bottom_nav_0'));
    expect(tester.getSize(financeNav).width, lessThanOrEqualTo(66));
    expect(tester.getSize(financeNav).height, lessThanOrEqualTo(42));

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final workoutNav = find.byKey(const ValueKey('workout_bottom_nav_0'));
    expect(tester.getSize(workoutNav).width, lessThanOrEqualTo(66));
    expect(tester.getSize(workoutNav).height, lessThanOrEqualTo(42));

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        find.byKey(const ValueKey('health_status_score_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('health_bottom_nav_0')), findsNothing);
  });

  testWidgets('module guide reflects current navigation and linked modules',
      (tester) async {
    await pumpPingShengApp(tester);

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final guideTile = find.text('使用指导');
    for (var index = 0; index < 4 && guideTile.evaluate().isEmpty; index++) {
      await tester.dragFrom(const Offset(400, 520), const Offset(0, -320));
      await tester.pumpAndSettle();
    }
    expect(guideTile, findsOneWidget);
    await tester.tap(guideTile);
    await tester.pumpAndSettle();

    expect(find.text('底部切换模块'), findsOneWidget);
    expect(find.textContaining('最底部固定显示财务、计划、饮食、锻炼、健康'), findsOneWidget);
    expect(find.text('看联动和小组件'), findsOneWidget);
    expect(find.textContaining('Health Connect'), findsOneWidget);
  });

  testWidgets('module link strip jumps between every main module',
      (tester) async {
    await pumpPingShengApp(tester);

    expect(find.text('今日执行  4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    expect(find.text('净资产'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('module_glass_header_title_food')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    expect(find.text('胸背'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('module_glass_header_title_health')),
        findsOneWidget);
    expect(find.text('状态中心'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_1')));
    await tester.pumpAndSettle();
    expect(find.text('今日执行  4'), findsOneWidget);
  });

  testWidgets('home widget initial route opens target module', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/finance';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await pumpPingShengApp(tester);

    expect(find.text('资产工作台'), findsOneWidget);
    expect(find.text('¥2,476.00'), findsWidgets);
    expect(find.text('¥1,555.00'), findsNothing);
  });

  testWidgets('home widget quick route opens finance detail sheet',
      (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/finance?action=add_finance';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await pumpPingShengApp(tester);
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

    await pumpPingShengApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('自定义食物'), findsWidgets);
    expect(find.text('食物名称'), findsOneWidget);
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

    await pumpPingShengApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('今日状态'), findsOneWidget);
    expect(find.text('待办 1 项'), findsOneWidget);
    expect(find.text('饮食 168 kcal'), findsOneWidget);
    expect(find.text('锻炼 2 组'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    final healthSummarySheet = find.byType(BottomSheet);
    expect(
        find.descendant(
          of: healthSummarySheet,
          matching: find.text('健康总览'),
        ),
        findsOneWidget);
    expect(
        find.descendant(
          of: healthSummarySheet,
          matching: find.text('饮食摄入'),
        ),
        findsOneWidget);
    expect(
        find.descendant(
          of: healthSummarySheet,
          matching: find.text('168 kcal'),
        ),
        findsOneWidget);
    expect(
        find.descendant(
          of: healthSummarySheet,
          matching: find.text('锻炼完成'),
        ),
        findsOneWidget);
    expect(
        find.descendant(
          of: healthSummarySheet,
          matching: find.text('2 组'),
        ),
        findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
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
    expect(args['financeRecordsJson'], '[]');
    expect(args['workoutGroups'], 2);
    expect(args['workoutGroupsJson'], contains('蝴蝶机夹胸'));
  });

  testWidgets('workout bottom nav hides overview and health hides duplicates',
      (tester) async {
    await pumpPingShengApp(tester);

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
    expect(find.byKey(const ValueKey('workout_bottom_nav_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('workout_bottom_nav_1')), findsNothing);
    expect(find.byKey(const ValueKey('workout_bottom_nav_2')), findsNothing);
    expect(find.text('总览'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('workout_bottom_nav_0')));
    await tester.pumpAndSettle();

    expect(find.text('胸背'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('module_glass_header_title_health')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('health_status_score_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('health_bottom_nav_0')), findsNothing);
    expect(find.byKey(const ValueKey('health_bottom_nav_1')), findsNothing);
    expect(find.byKey(const ValueKey('health_bottom_nav_2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();

    expect(find.text('胸背'), findsOneWidget);
  });

  testWidgets('food and workout records update health linked summary',
      (tester) async {
    await pumpPingShengApp(tester);

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('记录').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('健康总览'), findsOneWidget);
    expect(find.text('饮食摄入'), findsOneWidget);
    expect(find.text('80 kcal'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
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

    await dragUntilFound(
      tester,
      find.text('锻炼联动'),
      scrollable: find.byKey(const ValueKey('workout_main_list')),
    );
    expect(find.text('锻炼联动'), findsOneWidget);
    expect(find.text('80 kcal'), findsWidgets);
    expect(find.text('1 组'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('module_link_4')));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    final healthSummarySheet = find.byType(BottomSheet);
    expect(
        find.descendant(
          of: healthSummarySheet,
          matching: find.text('健康总览'),
        ),
        findsOneWidget);
    expect(
        find.descendant(
          of: healthSummarySheet,
          matching: find.text('80 kcal'),
        ),
        findsOneWidget);
    expect(
        find.descendant(
          of: healthSummarySheet,
          matching: find.text('1 组'),
        ),
        findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();

    expect(find.text('财务联动'), findsNothing);

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
    expect(find.text('记录饮食'), findsWidgets);
    expect(find.text('完成锻炼'), findsWidgets);

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('今日状态'), findsOneWidget);
    expect(find.text('最近动态'), findsOneWidget);
    expect(find.text('记录饮食'), findsWidgets);
    expect(find.text('完成锻炼'), findsWidgets);
    expect(find.text('待办 6 项'), findsOneWidget);
    expect(find.text('80 kcal'), findsWidgets);
    expect(find.text('锻炼 1 组'), findsOneWidget);
  });

  testWidgets('feedback sheet validates content before submit', (tester) async {
    await pumpPingShengApp(tester);

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final feedbackTile = find.text('问题反馈');
    await tester.scrollUntilVisible(
      feedbackTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(feedbackTile);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('feedback_submit')));
    await tester.pumpAndSettle();

    expect(find.text('请至少写 5 个字'), findsOneWidget);
  });

  testWidgets('feedback sheet submits to server and shows receipt',
      (tester) async {
    debugFeedbackResponseOverride = (body) async {
      expect(body['type'], '问题');
      expect(body['content'], '小组件显示不全');
      return {
        'feedback': {
          'id': 'fb-123',
          'status': 'pending',
          'createdAt': '2026-07-06T10:00:00Z',
        },
      };
    };
    addTearDown(() => debugFeedbackResponseOverride = null);

    await pumpPingShengApp(tester);
    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();
    final feedbackTile = find.text('问题反馈');
    await tester.scrollUntilVisible(
      feedbackTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(feedbackTile);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('feedback_content')),
      '小组件显示不全',
    );
    await tester.tap(find.byKey(const ValueKey('feedback_submit')));
    await tester.pumpAndSettle();

    expect(find.text('已提交'), findsOneWidget);
    expect(find.textContaining('fb-123'), findsOneWidget);
  });

  testWidgets('feedback sheet keeps content and offers fallback after failure',
      (tester) async {
    debugFeedbackResponseOverride = (body) async {
      throw Exception('offline');
    };
    addTearDown(() => debugFeedbackResponseOverride = null);

    await pumpPingShengApp(tester);
    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();
    final feedbackTile = find.text('问题反馈');
    await tester.scrollUntilVisible(
      feedbackTile,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(feedbackTile);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('feedback_content')),
      '服务器无法提交反馈',
    );
    await tester.tap(find.byKey(const ValueKey('feedback_submit')));
    await tester.pumpAndSettle();

    expect(find.text('提交失败'), findsOneWidget);
    expect(find.text('提交失败，请稍后重试。'), findsOneWidget);
    expect(find.byKey(const ValueKey('feedback_copy_content')), findsOneWidget);
    expect(find.byKey(const ValueKey('feedback_copy_contact')), findsOneWidget);
    expect(find.text('服务器无法提交反馈'), findsOneWidget);
  });
}
