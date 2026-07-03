import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  testWidgets('plan page opens add todo sheet', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    final now = DateTime.now();
    final monthText =
        '${now.year}年${now.month.toString().padLeft(2, '0')}月';

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

  testWidgets('today overview uses right side for health summary',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    final healthPanel =
        find.byKey(const ValueKey('today_overview_health_panel'));
    final firstMetric = find.byKey(const ValueKey('today_overview_metric_待办'));

    expect(healthPanel, findsOneWidget);
    expect(firstMetric, findsOneWidget);
    expect(tester.getTopLeft(healthPanel).dx,
        greaterThan(tester.getTopLeft(firstMetric).dx));
    expect(tester.getSize(healthPanel).height,
        greaterThan(tester.getSize(firstMetric).height));
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
        find.byKey(const ValueKey('week_plan_overview_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('week_plan_selected_tasks_panel')),
        findsOneWidget);
    expect(find.text('本周概览'), findsOneWidget);
    expect(find.text('本周任务'), findsOneWidget);
    expect(find.text('必做'), findsWidgets);
    expect(find.text('延后'), findsWidgets);
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
        find.byKey(const ValueKey('plan_header_selected_date')), findsOneWidget);
    expect(find.byKey(const ValueKey('plan_header_month_button')),
        findsNothing);
    expect(
        find.byKey(const ValueKey('plan_header_date_scroller')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('plan_header_date_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan_glass_date_picker')),
        findsOneWidget);
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
