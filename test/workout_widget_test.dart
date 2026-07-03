import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  const quickPlanGroups = {
    '上斜俯卧撑': 3,
    '箱式深蹲': 3,
    '平板触肩': 3,
    '低冲击开合步': 3,
    '胸椎旋转': 2,
  };

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
    expect(find.text('今日完成组数'), findsOneWidget);

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
    expect(find.descendant(of: detailSheet, matching: find.text('6 个动作')),
        findsOneWidget);
    expect(find.descendant(of: detailSheet, matching: find.text('22 组')),
        findsOneWidget);
    expect(find.text('开始训练'), findsOneWidget);

    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    expect(find.text('当前计划'), findsOneWidget);
    expect(find.text('胸背强化'), findsWidgets);
    expect(find.text('6 个动作'), findsWidgets);
    expect(find.text('器械推胸'), findsWidgets);
    expect(find.text('宽握高位下拉'), findsWidgets);
    await dragUntilFound(
      tester,
      find.text('弹力带拉开'),
      scrollable: find.byKey(const ValueKey('workout_main_list')),
    );
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
    expect(find.text('器械推胸'), findsWidgets);
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

    for (final entry in quickPlanGroups.entries) {
      for (var index = 0; index < entry.value; index++) {
        await tapWorkoutActionByName(tester, entry.key);
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

    for (final entry in quickPlanGroups.entries) {
      for (var index = 0; index < entry.value; index++) {
        await tapWorkoutActionByName(tester, entry.key);
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

    for (final entry in quickPlanGroups.entries) {
      for (var index = 0; index < entry.value; index++) {
        await tapWorkoutActionByName(tester, entry.key);
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

    await tester.tap(find.byKey(const ValueKey('workout_plan_remove_器械推胸')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workout_plan_selected_actions')),
        matching: find.text('器械推胸'),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('workout_plan_add_器械推胸')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workout_plan_selected_actions')),
        matching: find.text('器械推胸'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('workout training templates open matching plan detail',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();

    expect(find.text('6 动作 · 22 组'), findsOneWidget);
    expect(find.text('6 动作 · 16 组'), findsOneWidget);

    final planList = find.byType(Scrollable).last;
    await dragUntilFound(
      tester,
      find.text('新手全身基础'),
      scrollable: planList,
    );
    await dragUntilFound(
      tester,
      find.text('久坐肩颈修复'),
      scrollable: planList,
    );
    await dragUntilFound(
      tester,
      find.text('低冲击燃脂'),
      scrollable: planList,
    );

    final template =
        find.byKey(const ValueKey('workout_template_plan-quick-ten'));
    await dragUntilFound(
      tester,
      template,
      scrollable: planList,
      up: false,
    );
    await tester.ensureVisible(template);
    await tester.pumpAndSettle();
    await tester.tap(template);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_plan_detail_sheet')),
        findsOneWidget);
    expect(find.text('快练 10 分钟'), findsWidgets);
    expect(find.text('开始训练'), findsOneWidget);
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
        name: '腿臀训练',
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
    expect(find.text('腿臀训练'), findsWidgets);
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

    final workoutList = find.byKey(const ValueKey('workout_main_list'));
    expect(find.text('84 个动作'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workout_action_art_蝴蝶机夹胸')),
      findsOneWidget,
    );
    await dragUntilFound(
      tester,
      find.text('上斜俯卧撑'),
      scrollable: workoutList,
    );

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('workout_body_part_肩颈')),
      scrollable: workoutList,
      up: false,
    );
    await tester.tap(find.byKey(const ValueKey('workout_body_part_肩颈')));
    await tester.pumpAndSettle();
    expect(find.text('14 个动作'), findsOneWidget);
    expect(find.text('哑铃侧平举'), findsOneWidget);
    await dragUntilFound(tester, find.text('墙滑'), scrollable: workoutList);

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('workout_body_part_有氧')),
      scrollable: workoutList,
      up: false,
    );
    await tester.tap(find.byKey(const ValueKey('workout_body_part_有氧')));
    await tester.pumpAndSettle();
    expect(find.text('14 个动作'), findsOneWidget);
    expect(find.text('跑步机慢跑'), findsOneWidget);
    await dragUntilFound(tester, find.text('坡度快走'), scrollable: workoutList);

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('workout_body_part_拉伸')),
      scrollable: workoutList,
      up: false,
    );
    await tester.tap(find.byKey(const ValueKey('workout_body_part_拉伸')));
    await tester.pumpAndSettle();
    expect(find.text('14 个动作'), findsOneWidget);
    expect(find.text('站姿股四头肌拉伸'), findsOneWidget);
    await dragUntilFound(tester, find.text('胸椎旋转'), scrollable: workoutList);
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

    expect(find.text('0/257 组'), findsOneWidget);
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

    expect(find.text('1/257 组'), findsOneWidget);
    expect(find.text('1/4 组 ›'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_2')));
    await tester.pumpAndSettle();

    final todayGroupsCard =
        find.byKey(const ValueKey('workout_metric_today_groups'));
    expect(todayGroupsCard, findsOneWidget);
    expect(
      find.descendant(of: todayGroupsCard, matching: find.text('0 组')),
      findsOneWidget,
    );
    expect(find.text('0 min'), findsOneWidget);
    expect(find.text('今日预估消耗'), findsOneWidget);
    await dragUntilFound(
      tester,
      find.text('最近 7 天'),
      scrollable: find.byType(Scrollable).last,
      maxDrags: 4,
    );
    expect(find.text('0 次 · 0 组'), findsOneWidget);
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
      maxDrags: 40,
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
    expect(find.byKey(const ValueKey('module_glass_header_title_food')),
        findsOneWidget);
  });
}
