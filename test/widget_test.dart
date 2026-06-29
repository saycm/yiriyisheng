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

void mockSystemHealthStatus({
  required String status,
  required String message,
  List<Map<String, Object?>> days = const [],
}) {
  const channel = MethodChannel('pingsheng_life/system_health');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'loadHealthSnapshot') {
      return {
        'status': status,
        'message': message,
        'lastUpdated': '2026-06-05T08:30:00.000Z',
        'sensors': {
          'stepCounterAvailable': false,
          'heartRateSensorAvailable': false,
          'accelerometerAvailable': false,
        },
        'days': days,
      };
    }
    if (call.method == 'requestHealthPermissions') {
      return {'granted': status == 'ok'};
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
  test('life data models keep json and display behavior stable', () {
    final todo = TodoItem(
      id: 'todo_test',
      title: '还信用卡',
      category: '财务',
      color: AppColors.success,
      priority: TodoPriority.mustDo,
      status: TodoStatus.completed,
      dueDate: DateTime(2026, 6, 19, 18),
      note: '招商银行',
      repeatRule: TodoRepeatRule.monthly,
      linkedModules: const [TodoLinkedModule.finance, TodoLinkedModule.health],
      postponedCount: 2,
      createdAt: DateTime(2026, 6, 1, 8),
      completedAt: DateTime(2026, 6, 19, 9),
    );

    final restoredTodo =
        TodoItem.fromJson(todo.toJson().cast<String, dynamic>());
    expect(restoredTodo.id, 'todo_test');
    expect(restoredTodo.priority, TodoPriority.mustDo);
    expect(restoredTodo.status, TodoStatus.completed);
    expect(restoredTodo.dueDate, DateTime(2026, 6, 19));
    expect(restoredTodo.repeatRule, TodoRepeatRule.monthly);
    expect(
        restoredTodo.linkedModules,
        containsAll([
          TodoLinkedModule.finance,
          TodoLinkedModule.health,
        ]));
    expect(restoredTodo.postponedCount, 2);

    final record = FinanceRecord.fromJson({
      'title': '工资',
      'subtitle': '6 月',
      'amount': 12800,
      'type': '收入',
    });
    expect(record.displayAmount, '+¥12,800.00');
    expect(record.color, AppColors.success);

    final snapshot = LifeSummarySnapshot(
      foodCalories: 1800,
      workoutGroupsByAction: const {'深蹲': 3},
      todos: [restoredTodo],
      financeRecords: [record],
    );
    expect(snapshot.foodCalories, 1800);
    expect(snapshot.todos?.single.title, '还信用卡');
    expect(snapshot.financeRecords?.single.title, '工资');
  });

  test('life summary snapshot carries workout training state', () {
    final plan = WorkoutPlan(
      id: 'plan-chest',
      name: '胸背强化',
      target: '胸背训练',
      bodyParts: const ['胸背'],
      actionNames: const ['蝴蝶机夹胸'],
      estimatedMinutes: 28,
      createdAt: DateTime(2026, 6, 29),
      updatedAt: DateTime(2026, 6, 29),
    );
    final session = ActiveWorkoutSession(
      id: 'session-1',
      planId: 'plan-chest',
      planName: '胸背强化',
      startedAt: DateTime(2026, 6, 29, 8),
      actionProgress: const {'蝴蝶机夹胸': 2},
    );
    final history = WorkoutHistoryEntry(
      id: 'history-1',
      planId: 'plan-chest',
      planName: '胸背强化',
      startedAt: DateTime(2026, 6, 29, 8),
      finishedAt: DateTime(2026, 6, 29, 8, 30),
      durationMinutes: 30,
      totalGroups: 4,
      estimatedCalories: 128,
      actionResults: const [
        WorkoutActionResult(
          actionName: '蝴蝶机夹胸',
          bodyPart: '胸背',
          targetGroups: 4,
          finishedGroups: 4,
          reps: '8次',
          weight: '30kg',
        ),
      ],
    );

    final snapshot = LifeSummarySnapshot(
      foodCalories: 0,
      workoutGroupsByAction: const {'蝴蝶机夹胸': 4},
      todos: const [],
      financeRecords: const [],
      workoutPlans: [plan],
      activeWorkoutSession: session,
      workoutHistory: [history],
    );

    expect(snapshot.workoutPlans?.single.name, '胸背强化');
    expect(snapshot.activeWorkoutSession?.groupsFor('蝴蝶机夹胸'), 2);
    expect(snapshot.workoutHistory?.single.totalGroups, 4);
  });

  test('workout models serialize and restore training history', () {
    final startedAt = DateTime(2026, 6, 29, 8, 0);
    final finishedAt = DateTime(2026, 6, 29, 8, 32);

    final entry = WorkoutHistoryEntry(
      id: 'history-1',
      planId: 'plan-chest',
      planName: '胸背强化',
      startedAt: startedAt,
      finishedAt: finishedAt,
      durationMinutes: 32,
      totalGroups: 8,
      estimatedCalories: 184,
      actionResults: const [
        WorkoutActionResult(
          actionName: '蝴蝶机夹胸',
          bodyPart: '胸背',
          targetGroups: 4,
          finishedGroups: 4,
          reps: '8次',
          weight: '30kg',
        ),
        WorkoutActionResult(
          actionName: '宽握高位下拉',
          bodyPart: '胸背',
          targetGroups: 4,
          finishedGroups: 4,
          reps: '12次',
          weight: '30kg',
        ),
      ],
      feedback: '适中',
    );

    final restored = WorkoutHistoryEntry.fromJson(entry.toJson());

    expect(restored.id, 'history-1');
    expect(restored.planName, '胸背强化');
    expect(restored.durationMinutes, 32);
    expect(restored.totalGroups, 8);
    expect(restored.estimatedCalories, 184);
    expect(restored.actionResults.map((item) => item.actionName), [
      '蝴蝶机夹胸',
      '宽握高位下拉',
    ]);
  });

  test('workout session restores supported feedback and numeric progress', () {
    final session = ActiveWorkoutSession.fromJson({
      'id': 'session-1',
      'planId': 'plan-chest',
      'planName': '胸背强化',
      'startedAt': '2026-06-29T08:00:00.000',
      'actionProgress': {'蝴蝶机夹胸': '2', '宽握高位下拉': 1},
    });

    expect(session.feedback, '刚好');
    expect(session.groupsFor('蝴蝶机夹胸'), 2);
    expect(session.groupsFor('宽握高位下拉'), 1);

    final history = WorkoutHistoryEntry.fromJson({
      'id': 'history-1',
      'planId': 'plan-chest',
      'planName': '胸背强化',
      'startedAt': '2026-06-29T08:00:00.000',
      'finishedAt': '2026-06-29T08:30:00.000',
      'durationMinutes': 30,
      'totalGroups': 4,
      'estimatedCalories': 128,
      'actionResults': const [],
    });

    expect(history.feedback, '刚好');
  });

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

  test('ai finance client defaults to zhipu glm request', () async {
    Uri? capturedUri;
    Map<String, dynamic>? capturedPayload;
    String? capturedApiKey;
    final client = AiFinanceClient(
      transport: ({
        required apiKey,
        required payload,
        required uri,
      }) async {
        capturedUri = uri;
        capturedPayload = payload;
        capturedApiKey = apiKey;
        return '''
{
  "choices": [
    {
      "message": {
        "content": "[{\\"amount\\":-18,\\"time\\":\\"2026-06-05T12:00:00\\",\\"note\\":\\"午饭\\",\\"category\\":\\"三餐\\",\\"type\\":\\"expense\\"}]"
      }
    }
  ]
}
''';
      },
    );

    final bills = await client.parseText(
      text: '午饭18',
      apiKey: 'glm-key',
      endpoint: '',
      model: '',
    );

    expect(
      capturedUri.toString(),
      'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    );
    expect(capturedPayload?['model'], 'glm-4-flash');
    expect(capturedApiKey, 'glm-key');
    expect(bills.single.amount, -18);
    expect(bills.single.category, '三餐');
  });

  testWidgets('plan page opens add todo sheet', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    expect(find.text('今日计划  4'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('plan_header_date_button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('plan_header_date_scroller')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('home_quick_record_button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('plan_add_todo_fab')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('plan_add_todo_fab'))).width,
      lessThan(56),
    );

    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();

    expect(find.text('新增待办'), findsOneWidget);
    expect(find.text('优先级'), findsOneWidget);
    expect(find.text('任务联动'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(FilledButton, '保存')).height,
      lessThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.widgetWithText(ChoiceChip, '工作').first).height,
      lessThanOrEqualTo(36),
    );
  });

  testWidgets('today overview hides duplicate quick record button',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    final overview = find.byKey(const ValueKey('today_overview_card'));
    expect(find.descendant(of: overview, matching: find.text('今日总览')),
        findsOneWidget);
    expect(find.descendant(of: overview, matching: find.text('待办')),
        findsOneWidget);
    expect(find.descendant(of: overview, matching: find.text('支出')),
        findsOneWidget);
    expect(find.descendant(of: overview, matching: find.text('热量')),
        findsOneWidget);
    expect(find.descendant(of: overview, matching: find.text('训练')),
        findsOneWidget);
    expect(find.descendant(of: overview, matching: find.text('健康')),
        findsOneWidget);
    expect(
      find.descendant(
        of: overview,
        matching: find.byKey(const ValueKey('home_quick_record_button')),
      ),
      findsNothing,
    );
  });

  testWidgets('inbox quick capture creates undated todo', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plan_inbox_quick_capture')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('plan_inbox_quick_capture_field')),
      '买牙膏',
    );
    await tester.tap(
      find.byKey(const ValueKey('plan_inbox_quick_capture_save')),
    );
    await tester.pumpAndSettle();

    expect(find.text('已放入待办箱'), findsOneWidget);
    expect(find.text('买牙膏'), findsOneWidget);
    expect(find.text('待办箱  2'), findsOneWidget);
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

    await dragUntilFound(
      tester,
      find.text('还信用卡'),
      scrollable: find.byType(Scrollable).last,
    );
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

    final now = DateTime.now();
    await tester.tap(
      find.byKey(
        ValueKey('module_heat_day_${now.year}_${now.month}_1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('${now.year}年${now.month}月1日'), findsOneWidget);
    expect(find.text('计划待办'), findsOneWidget);
    expect(find.text('饮食记录'), findsOneWidget);
    expect(find.text('锻炼记录'), findsOneWidget);
    expect(find.text('健康总览'), findsOneWidget);
  });

  testWidgets('module sheet switches heat map month and uses sane stats',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final now = DateTime.now();
    expect(find.text('${now.year}年 ${now.month.toString().padLeft(2, '0')}月'),
        findsOneWidget);
    expect(find.text('984'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('module_heat_prev_month')));
    await tester.pumpAndSettle();

    final previousMonth = DateTime(now.year, now.month - 1);
    expect(
      find.text(
          '${previousMonth.year}年 ${previousMonth.month.toString().padLeft(2, '0')}月'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey(
          'module_heat_day_${previousMonth.year}_${previousMonth.month}_1',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('module_heat_next_month')));
    await tester.pumpAndSettle();

    expect(find.text('${now.year}年 ${now.month.toString().padLeft(2, '0')}月'),
        findsOneWidget);
  });

  testWidgets('module heat map day sheet follows selected month',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);
    await tester.tap(find.byKey(const ValueKey('module_heat_prev_month')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey(
          'module_heat_day_${previousMonth.year}_${previousMonth.month}_1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('${previousMonth.year}年${previousMonth.month}月1日'),
      findsOneWidget,
    );
  });

  testWidgets('module link strip is compact and inner nav stays at bottom',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    final mainLink = find.byKey(const ValueKey('module_link_1'));
    expect(tester.getSize(mainLink).height, lessThanOrEqualTo(40));

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
    expect(find.byType(CalendarDatePicker), findsOneWidget);
  });

  testWidgets('finance workout and health bottom navs use compact capsules',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp());
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
    final healthNav = find.byKey(const ValueKey('health_bottom_nav_0'));
    expect(tester.getSize(healthNav).width, lessThanOrEqualTo(66));
    expect(tester.getSize(healthNav).height, lessThanOrEqualTo(42));
  });

  testWidgets('food selected record bar is compact on narrow screens',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();

    final selectedBar =
        find.byKey(const ValueKey('food_selected_bar_container'));
    expect(selectedBar, findsOneWidget);
    expect(tester.getSize(selectedBar).height, lessThanOrEqualTo(52));

    final decoration =
        tester.widget<Container>(selectedBar).decoration! as BoxDecoration;
    final borderRadius = decoration.borderRadius! as BorderRadius;
    expect(borderRadius.topLeft.x, greaterThanOrEqualTo(16));

    final recordButton =
        find.byKey(const ValueKey('food_record_selected_button'));
    expect(tester.getSize(recordButton).width, lessThanOrEqualTo(104));
    expect(tester.getSize(recordButton).height, lessThanOrEqualTo(40));
  });

  testWidgets('module guide reflects current navigation and linked modules',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

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

    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_1')));
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
    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('finance_add_record')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('finance_category_income')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('finance_category_income')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_category_奖金')));
    await tester.pumpAndSettle();
    expect(find.text('金额'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_subtitle')),
      '项目奖励',
    );
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('save_finance_record')));
    await tester.pumpAndSettle();

    expect(find.text('奖金'), findsOneWidget);
    expect(find.text('+¥888.00'), findsOneWidget);

    await tester.tap(find.text('奖金'));
    await tester.pumpAndSettle();
    expect(find.text('编辑记录'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('finance_record_subtitle')),
      '调整后的奖励',
    );
    await tester.tap(find.byKey(const ValueKey('finance_amount_clear')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_1')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_2')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('finance_amount_key_8')));
    await tester.tap(find.byKey(const ValueKey('save_finance_record')));
    await tester.pumpAndSettle();

    expect(find.text('调整后的奖励'), findsOneWidget);
    expect(find.text('+¥1,288.00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_bottom_nav_1')));
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
    expect(find.text('智谱 GLM 记账'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ai_finance_endpoint')))
          .controller
          ?.text,
      'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ai_finance_model')))
          .controller
          ?.text,
      'glm-4-flash',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ai_finance_input')),
      '昨天中午吃饭50，晚上奶茶12',
    );
    await tester.tap(find.byKey(const ValueKey('run_ai_finance_parse')));
    await tester.pumpAndSettle();

    expect(find.text('请先填写 AI 接口 Key'), findsOneWidget);
  });

  testWidgets('finance glm ai config survives module switches', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_ai_record')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('ai_finance_endpoint')),
      'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ai_finance_model')),
      'glm-4.6',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ai_finance_api_key')),
      'persisted-glm-key',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ai_finance_input')),
      '午饭18',
    );
    await tester.tap(find.byKey(const ValueKey('run_ai_finance_parse')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finance_ai_record')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ai_finance_model')))
          .controller
          ?.text,
      'glm-4.6',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('ai_finance_api_key')))
          .controller
          ?.text,
      'persisted-glm-key',
    );
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

  testWidgets('finance overview shows budgets fixed costs and alerts',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_0')));
    await tester.pumpAndSettle();

    expect(find.text('本月预算'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.text('分类预算'),
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('三餐'), findsWidgets);
    expect(find.text('已用 ¥18.00 / ¥1,000.00'), findsOneWidget);
    expect(find.text('数码分期'), findsWidgets);
    expect(find.text('已用 ¥500.00 / ¥600.00'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.text('固定支出'),
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('手机分期还款'), findsOneWidget);
    expect(find.text('每月预计 ¥500.00'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.text('异常提醒'),
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('数码分期接近分类预算'), findsOneWidget);
    expect(find.textContaining('已使用 83%'), findsOneWidget);
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
    expect(find.text('训练日历'), findsOneWidget);
    expect(find.text('暂无训练记录'), findsOneWidget);
  });

  testWidgets('workout plan opens detail and starts scoped workout',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('workout_plan_plan-chest-back')));
    await tester.pumpAndSettle();

    final detailSheet = find.byKey(const ValueKey('workout_plan_detail_sheet'));
    expect(detailSheet, findsOneWidget);
    expect(find.text('胸背强化'), findsWidgets);
    expect(find.descendant(of: detailSheet, matching: find.text('5 个动作')),
        findsOneWidget);
    expect(find.descendant(of: detailSheet, matching: find.text('20 组')),
        findsOneWidget);
    expect(find.text('开始训练'), findsOneWidget);

    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    expect(find.text('当前计划'), findsOneWidget);
    expect(find.text('胸背强化'), findsWidgets);
    expect(find.text('5 个动作'), findsWidgets);
    expect(find.text('蝴蝶机夹胸'), findsWidgets);
    expect(find.text('宽握高位下拉'), findsWidgets);
    expect(find.text('平板支撑'), findsNothing);
  });

  testWidgets('workout plan opens detail and starts plan training',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('workout_plan_plan-chest-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_plan_detail_sheet')),
        findsOneWidget);
    expect(find.text('胸背强化'), findsWidgets);
    expect(find.text('开始训练'), findsOneWidget);

    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_active_plan_banner')),
        findsOneWidget);
    expect(find.textContaining('胸背强化'), findsWidgets);
    expect(find.text('蝴蝶机夹胸'), findsWidgets);
  });

  testWidgets('finishing planned workout creates history entry',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();
    final planCard = find.byKey(const ValueKey('workout_plan_plan-quick-ten'));
    await tester.scrollUntilVisible(
      planCard,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(planCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    for (final actionName in ['登山跑', '俄罗斯转体', '波比跳']) {
      for (var index = 0; index < 3; index++) {
        final action = find.text(actionName).first;
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();
        await tester.tap(find.text('开始动作'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('完成训练'), findsOneWidget);
    await tester.tap(find.text('完成训练'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_history_real_list')),
        findsOneWidget);
    expect(find.text('快练 10 分钟'), findsWidgets);
  });

  testWidgets('workout data cards open real metric detail', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();
    final planCard = find.byKey(const ValueKey('workout_plan_plan-quick-ten'));
    await tester.scrollUntilVisible(
      planCard,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(planCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    for (final actionName in ['登山跑', '俄罗斯转体', '波比跳']) {
      for (var index = 0; index < 3; index++) {
        final action = find.text(actionName).first;
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();
        await tester.tap(find.text('开始动作'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
      }
    }
    await tester.tap(find.text('完成训练'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_metric_today_groups')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_metric_detail_sheet')),
        findsOneWidget);
    expect(find.text('今日完成组数'), findsWidgets);
    expect(find.textContaining('快练 10 分钟'), findsWidgets);
  });

  testWidgets('workout history detail can restart same plan', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();
    final planCard = find.byKey(const ValueKey('workout_plan_plan-quick-ten'));
    await tester.scrollUntilVisible(
      planCard,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(planCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    for (final actionName in ['登山跑', '俄罗斯转体', '波比跳']) {
      for (var index = 0; index < 3; index++) {
        final action = find.text(actionName).first;
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();
        await tester.tap(find.text('开始动作'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
      }
    }
    await tester.tap(find.text('完成训练'));
    await tester.pumpAndSettle();

    final historyTitle = find.text('快练 10 分钟').last;
    await tester.ensureVisible(historyTitle);
    await tester.pumpAndSettle();
    await tester.tap(historyTitle);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_history_detail_sheet')),
        findsOneWidget);
    expect(find.text('再次训练'), findsOneWidget);

    await tester.tap(find.text('再次训练'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_active_plan_banner')),
        findsOneWidget);
    expect(find.textContaining('快练 10 分钟'), findsWidgets);
  });

  testWidgets('workout plan detail can remove and add existing action',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('workout_plan_plan-chest-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('编辑计划'));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('workout_plan_edit_sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout_plan_remove_蝴蝶机夹胸')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workout_plan_selected_actions')),
        matching: find.text('蝴蝶机夹胸'),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('workout_plan_add_蝴蝶机夹胸')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workout_plan_selected_actions')),
        matching: find.text('蝴蝶机夹胸'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('workout quick action respects active plan scope',
      (tester) async {
    final plans = [
      WorkoutPlan(
        id: 'plan-chest-back',
        name: '胸背强化',
        target: '胸背力量和体态稳定',
        bodyParts: const ['胸背'],
        actionNames: const [
          '蝴蝶机夹胸',
          '宽握高位下拉',
          '器械推胸',
          '坐姿绳索划船',
          '上斜哑铃卧推',
        ],
        estimatedMinutes: 38,
      ),
      WorkoutPlan(
        id: 'plan-leg-stability',
        name: '腿部稳定',
        target: '下肢力量和髋膝稳定',
        bodyParts: const ['腿臀'],
        actionNames: const [
          '杠铃深蹲',
          '腿举',
          '罗马尼亚硬拉',
          '保加利亚分腿蹲',
        ],
        estimatedMinutes: 34,
      ),
    ];
    ActiveWorkoutSession? activeSession;

    Widget buildWorkout({WidgetQuickAction? quickAction, int token = 0}) {
      return MaterialApp(
        home: WorkoutModulePage(
          moduleNav: const SizedBox.shrink(),
          onOpenModules: () {},
          onSwitchModule: (_) {},
          finishedGroupsByAction: const {},
          onUpdateActionGroups: (_, __) {},
          workoutPlans: plans,
          onUpdateWorkoutPlan: (_) {},
          activeWorkoutSession: activeSession,
          workoutHistory: const [],
          onStartWorkoutSession: (session) => activeSession = session,
          onUpdateWorkoutSession: (session) => activeSession = session,
          onFinishWorkoutSession: (_) => activeSession = null,
          foodCalories: 0,
          quickAction: quickAction,
          quickActionToken: token,
          onQuickActionHandled: () {},
        ),
      );
    }

    await tester.pumpWidget(buildWorkout());

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();

    final legPlanCard =
        find.byKey(const ValueKey('workout_plan_plan-leg-stability'));
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(legPlanCard);
    await tester.pumpAndSettle();

    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildWorkout());
    await tester.pumpAndSettle();

    expect(find.text('当前计划'), findsOneWidget);
    expect(find.text('腿部稳定'), findsWidgets);
    expect(find.text('杠铃深蹲'), findsWidgets);

    await tester.pumpWidget(
      buildWorkout(
        quickAction: WidgetQuickAction.startWorkout,
        token: 1,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_action_detail_list')),
        findsOneWidget);
    expect(find.text('杠铃深蹲'), findsWidgets);
    expect(find.text('蝴蝶机夹胸'), findsNothing);
  });

  testWidgets('workout history shows calendar and progress trends',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_3')));
    await tester.pumpAndSettle();

    expect(find.text('训练日历'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('workout_calendar_strip')), findsOneWidget);
    expect(find.text('动作历史曲线'), findsOneWidget);
    expect(find.text('蝴蝶机夹胸'), findsWidgets);
    expect(find.text('重量进步'), findsOneWidget);
    expect(find.text('30kg → 35kg'), findsOneWidget);
    expect(find.text('次数进步'), findsOneWidget);
    expect(find.text('8次 → 12次'), findsOneWidget);
  });

  testWidgets('workout body part filters expose expanded exercise library',
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

    expect(find.text('42 个动作'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workout_action_art_蝴蝶机夹胸')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('workout_body_part_肩颈')));
    await tester.pumpAndSettle();
    expect(find.text('7 个动作'), findsOneWidget);
    expect(find.text('哑铃侧平举'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout_body_part_有氧')));
    await tester.pumpAndSettle();
    expect(find.text('7 个动作'), findsOneWidget);
    expect(find.text('跑步机慢跑'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout_body_part_拉伸')));
    await tester.pumpAndSettle();
    expect(find.text('7 个动作'), findsOneWidget);
    expect(find.text('站姿股四头肌拉伸'), findsOneWidget);
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

    expect(find.text('0/133 组'), findsOneWidget);
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

    expect(find.text('1/133 组'), findsOneWidget);
    expect(find.text('1/4 组 ›'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_2')));
    await tester.pumpAndSettle();

    expect(find.text('1/133'), findsOneWidget);
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

    expect(find.byKey(const ValueKey('food_group_scroller')), findsNothing);
    expect(find.byKey(const ValueKey('food_group_早餐')), findsNothing);
    expect(find.byKey(const ValueKey('food_group_主食杂粮')), findsNothing);
    expect(find.text('混合沙拉'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('food_search_field')), '希腊酸奶');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('food_main_list')),
        matching: find.text('希腊酸奶'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
        find.byKey(const ValueKey('food_search_field')), '麻辣烫');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('food_main_list')),
        matching: find.text('麻辣烫'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const ValueKey('food_search_field')), '');
    await tester.pumpAndSettle();

    await tester.tap(find.text('收藏').first);
    await tester.pumpAndSettle();
    expect(find.text('美式咖啡'), findsOneWidget);
    expect(find.text('混合沙拉'), findsNothing);

    await tester.tap(find.text('常见').first);
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

    await tester.enterText(
        find.byKey(const ValueKey('food_search_field')), 'zzz');
    await tester.pumpAndSettle();

    final foodList = find.byKey(const ValueKey('food_main_list'));
    final trainingSnack = find.byKey(const ValueKey('food_template_训练后加餐'));
    await dragUntilFound(
      tester,
      trainingSnack,
      scrollable: foodList,
      maxDrags: 18,
    );
    await tester.tap(trainingSnack);
    await tester.pumpAndSettle();

    expect(find.text('已记录 加餐 2 项，152 千卡'), findsOneWidget);
    expect(find.textContaining('加餐'), findsWidgets);
    expect(find.text('希腊酸奶'), findsWidgets);
    expect(find.text('1 次 · 59 kcal'), findsOneWidget);
    expect(find.text('香蕉'), findsWidgets);
    expect(find.text('1 次 · 93 kcal'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('food_repeat_last_meal')),
      scrollable: foodList,
      up: false,
    );
    await tester.tap(find.byKey(const ValueKey('food_repeat_last_meal')));
    await tester.pumpAndSettle();

    expect(find.text('已记录 加餐 2 项，152 千卡'), findsOneWidget);
    expect(find.text('2 次 · 118 kcal'), findsOneWidget);
    expect(find.text('2 次 · 186 kcal'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('food_calorie_progress_card')),
      scrollable: foodList,
      up: false,
    );
    expect(find.text('今日热量'), findsOneWidget);
    expect(find.text('304 / 1800 kcal'), findsOneWidget);
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
      maxDrags: 18,
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

  testWidgets('plan visual shell uses top date picker and single add entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('plan_header_date_button')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('plan_header_date_scroller')), findsNothing);
    expect(find.byKey(const ValueKey('today_overview_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('module_link_container')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan_bottom_nav_container')),
        findsOneWidget);
    expect(find.text('今日总览'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home_quick_record_button')), findsNothing);
    expect(find.byKey(const ValueKey('plan_add_todo_fab')), findsOneWidget);
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
