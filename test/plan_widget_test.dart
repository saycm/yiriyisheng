// 中文注释：自动化测试文件，负责验证对应模块行为和回归场景。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  testWidgets('plan page opens add todo sheet', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    final now = DateTime.now();
    final monthText = '${now.year}年${now.month.toString().padLeft(2, '0')}月';

    expect(find.text('今日计划  4'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('plan_header_date_button')), findsOneWidget);
    expect(find.text(monthText), findsNothing);
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
    expect(find.byKey(const ValueKey('plan_todo_editor_glass_panel')),
        findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('plan_todo_editor_glass_panel')),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );

    final tomorrowChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '明天').first,
    );
    final inProgressChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '进行中').first,
    );
    expect(tomorrowChip.labelStyle?.color, isNot(AppColors.muted));
    expect(inProgressChip.labelStyle?.color, isNot(AppColors.muted));
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

  testWidgets('today overview uses balanced metric grid and health strip',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    final healthPanel =
        find.byKey(const ValueKey('today_overview_health_panel'));
    final todoMetric = find.byKey(const ValueKey('today_overview_metric_待办'));
    final expenseMetric =
        find.byKey(const ValueKey('today_overview_metric_支出'));
    final caloriesMetric =
        find.byKey(const ValueKey('today_overview_metric_热量'));
    final workoutMetric =
        find.byKey(const ValueKey('today_overview_metric_训练'));

    expect(healthPanel, findsOneWidget);
    expect(todoMetric, findsOneWidget);
    expect(expenseMetric, findsOneWidget);
    expect(caloriesMetric, findsOneWidget);
    expect(workoutMetric, findsOneWidget);

    final todoTopLeft = tester.getTopLeft(todoMetric);
    final expenseTopLeft = tester.getTopLeft(expenseMetric);
    final caloriesTopLeft = tester.getTopLeft(caloriesMetric);
    final workoutTopLeft = tester.getTopLeft(workoutMetric);
    final metricSize = tester.getSize(todoMetric);
    final healthTopLeft = tester.getTopLeft(healthPanel);
    final healthSize = tester.getSize(healthPanel);

    expect(expenseTopLeft.dy, closeTo(todoTopLeft.dy, 1));
    expect(expenseTopLeft.dx, greaterThan(todoTopLeft.dx));
    expect(caloriesTopLeft.dy, greaterThan(todoTopLeft.dy));
    expect(workoutTopLeft.dy, closeTo(caloriesTopLeft.dy, 1));
    expect(workoutTopLeft.dx, greaterThan(caloriesTopLeft.dx));
    expect(healthTopLeft.dy, greaterThan(workoutTopLeft.dy));
    expect(healthSize.width, greaterThan(metricSize.width * 1.9));
    expect(healthSize.height, lessThanOrEqualTo(metricSize.height));
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

    expect(find.text('今日状态'), findsOneWidget);
    expect(find.text('待办 5 项'), findsOneWidget);
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

  testWidgets('week plan shows redesigned weekly overview', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_2')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('week_plan_command_center')), findsOneWidget);
    expect(find.byKey(const ValueKey('week_plan_day_board')), findsOneWidget);
    expect(find.text('一周安排工作台'), findsOneWidget);
    expect(find.text('一键排周'), findsOneWidget);
    expect(find.textContaining('本周节奏'), findsOneWidget);
    expect(find.textContaining('负载'), findsWidgets);

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('week_plan_unscheduled_section')),
      scrollable: find.byKey(const ValueKey('week_plan_list')),
    );
    expect(find.byKey(const ValueKey('week_plan_unscheduled_section')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('week_plan_selected_tasks_panel')),
        findsOneWidget);
    expect(find.text('待安排任务'), findsOneWidget);
  });

  testWidgets('week plan auto schedules inbox todos into this week',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_2')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('待安排 1'),
      scrollable: find.byKey(const ValueKey('week_plan_list')),
    );

    expect(find.text('待安排 1'), findsOneWidget);
    expect(find.text('整理学习清单'), findsOneWidget);

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('week_plan_auto_schedule')),
      scrollable: find.byKey(const ValueKey('week_plan_list')),
      up: false,
    );

    await tester.tap(find.byKey(const ValueKey('week_plan_auto_schedule')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('待安排 0'),
      scrollable: find.byKey(const ValueKey('week_plan_list')),
    );

    expect(find.text('已安排 1 项到本周'), findsOneWidget);
    expect(find.text('待安排 0'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_1')));
    await tester.pumpAndSettle();

    expect(find.text('待办箱  0'), findsOneWidget);
    expect(find.text('整理学习清单'), findsNothing);
  });

  testWidgets('week plan schedules backlog into selected day', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_2')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('week_plan_schedule_selected_day')),
      scrollable: find.byKey(const ValueKey('week_plan_list')),
    );

    await tester
        .tap(find.byKey(const ValueKey('week_plan_schedule_selected_day')));
    await tester.pumpAndSettle();

    expect(find.text('已安排 1 项到选中日期'), findsOneWidget);
    expect(find.text('整理学习清单'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_1')));
    await tester.pumpAndSettle();

    expect(find.text('待办箱  0'), findsOneWidget);
    expect(find.text('整理学习清单'), findsNothing);
  });

  testWidgets('week plan undoes scheduling one backlog item', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_2')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('week_plan_schedule_selected_day')),
      scrollable: find.byKey(const ValueKey('week_plan_list')),
    );

    await tester
        .tap(find.byKey(const ValueKey('week_plan_schedule_selected_day')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_1')));
    await tester.pumpAndSettle();

    expect(find.text('待办箱  1'), findsOneWidget);
    expect(find.text('整理学习清单'), findsOneWidget);
  });

  testWidgets('week plan schedules all backlog into selected day and undoes',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await _addInboxTodo(tester, '买打印纸');
    await _addInboxTodo(tester, '整理票据');

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_1')));
    await tester.pumpAndSettle();

    expect(find.text('待办箱  3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_2')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('week_plan_schedule_all_selected_day')),
      scrollable: find.byKey(const ValueKey('week_plan_list')),
    );

    await tester
        .tap(find.byKey(const ValueKey('week_plan_schedule_all_selected_day')));
    await tester.pumpAndSettle();

    expect(find.text('已安排 3 项到选中日期'), findsOneWidget);
    expect(find.text('整理学习清单'), findsWidgets);
    expect(find.text('买打印纸'), findsWidgets);
    expect(find.text('整理票据'), findsWidgets);

    await tester.tap(find.text('撤销'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_1')));
    await tester.pumpAndSettle();

    expect(find.text('待办箱  3'), findsOneWidget);
    expect(find.text('整理学习清单'), findsOneWidget);
    expect(find.text('买打印纸'), findsOneWidget);
    expect(find.text('整理票据'), findsOneWidget);
  });

  testWidgets('week plan warns when selected day is overloaded',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_2')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.byKey(const ValueKey('week_plan_schedule_selected_day')),
      scrollable: find.byKey(const ValueKey('week_plan_list')),
    );

    await tester
        .tap(find.byKey(const ValueKey('week_plan_schedule_selected_day')));
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('这天任务偏满，建议只排高优先级事项。'),
      scrollable: find.byKey(const ValueKey('week_plan_list')),
      up: false,
    );

    expect(find.textContaining('偏满'), findsWidgets);
    expect(find.text('这天任务偏满，建议只排高优先级事项。'), findsOneWidget);
  });

  testWidgets('plan visual shell uses top date picker and single add entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('plan_header_date_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan_header_selected_date')),
        findsOneWidget);
    const screenCenterX = 390.0 / 2;
    final dateButtonCenterX = tester
        .getCenter(find.byKey(const ValueKey('plan_header_date_button')))
        .dx;
    expect(dateButtonCenterX, closeTo(screenCenterX, 2));
    expect(
        find.byKey(const ValueKey('plan_header_month_button')), findsNothing);
    expect(
        find.byKey(const ValueKey('plan_header_date_scroller')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('plan_header_date_button')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('plan_glass_date_picker')), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('today_overview_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('module_link_container')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan_bottom_nav_container')),
        findsOneWidget);
    expect(find.text('今日总览'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home_quick_record_button')), findsNothing);
    expect(find.byKey(const ValueKey('plan_add_todo_fab')), findsOneWidget);
  });
}

Future<void> _addInboxTodo(WidgetTester tester, String title) async {
  await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('plan_inbox_quick_capture')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('plan_inbox_quick_capture_field')),
    title,
  );
  await tester.tap(
    find.byKey(const ValueKey('plan_inbox_quick_capture_save')),
  );
  await tester.pumpAndSettle();
  final closeButton = find.byIcon(Icons.close_rounded);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton.last);
    await tester.pumpAndSettle();
  }
}
