import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
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

    final foodList = find.byKey(const ValueKey('food_main_list'));
    Finder foodInList(String name) => find.descendant(
          of: foodList,
          matching: find.text(name),
        );
    Future<void> tapFoodCategory(String category) async {
      final categoryFinder = find.byKey(ValueKey('food_category_$category'));
      await tester.scrollUntilVisible(
        categoryFinder,
        80,
        scrollable: find.byKey(const ValueKey('food_category_scroller')),
      );
      await tester.pumpAndSettle();
      await tester.tap(categoryFinder.first);
      await tester.pumpAndSettle();
    }

    expect(
        find.byKey(const ValueKey('food_category_scroller')), findsOneWidget);
    expect(find.byKey(const ValueKey('food_category_常用')), findsOneWidget);
    expect(find.byKey(const ValueKey('food_category_主食')), findsOneWidget);
    expect(find.byKey(const ValueKey('food_category_蛋白')), findsOneWidget);
    expect(find.byKey(const ValueKey('food_category_蔬果')), findsOneWidget);
    expect(find.byKey(const ValueKey('food_category_饮品')), findsOneWidget);
    expect(find.byKey(const ValueKey('food_category_自定义')), findsOneWidget);
    expect(foodInList('混合沙拉'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('food_search_field')), '希腊酸奶');
    await tester.pumpAndSettle();
    expect(foodInList('希腊酸奶'), findsOneWidget);

    await tester.enterText(
        find.byKey(const ValueKey('food_search_field')), '麻辣烫');
    await tester.pumpAndSettle();
    expect(foodInList('麻辣烫'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('food_search_field')), '');
    await tester.pumpAndSettle();

    await tapFoodCategory('饮品');
    expect(foodInList('美式咖啡'), findsOneWidget);
    expect(foodInList('珍珠奶茶'), findsOneWidget);
    expect(foodInList('鸡胸肉'), findsNothing);

    await tapFoodCategory('常用');

    await tester.enterText(
        find.byKey(const ValueKey('food_search_field')), '鸡胸肉');
    await tester.pumpAndSettle();

    expect(foodInList('鸡胸肉'), findsWidgets);

    await tester.enterText(find.byKey(const ValueKey('food_search_field')), '');
    await tester.pumpAndSettle();

    await tapFoodCategory('主食');
    expect(foodInList('米饭'), findsOneWidget);
    expect(foodInList('鸡胸肉'), findsNothing);

    await tapFoodCategory('蛋白');
    expect(foodInList('鸡胸肉'), findsOneWidget);
    expect(foodInList('米饭'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('food_search_field')), '');
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('food_search_field')), '披萨');
    await tester.pumpAndSettle();

    expect(foodInList('披萨（芝士）'), findsOneWidget);
    expect(foodInList('混合沙拉'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('food_search_field')), '');
    await tester.pumpAndSettle();

    await tapFoodCategory('自定义');
    await tester.tap(find.byKey(const ValueKey('add_custom_food_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom_food_group_主食')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom_food_group_蛋白')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom_food_group_蔬果')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom_food_group_自定义')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom_food_group_主食杂粮')), findsNothing);
    expect(find.byKey(const ValueKey('custom_food_group_肉蛋奶')), findsNothing);

    await tester.enterText(
        find.byKey(const ValueKey('custom_food_name')), '燕麦酸奶');
    await tester.enterText(
        find.byKey(const ValueKey('custom_food_calorie')), '168');
    await tester.enterText(
        find.byKey(const ValueKey('custom_food_unit')), '1 碗');
    await tester.tap(find.byKey(const ValueKey('save_custom_food_button')));
    await tester.pumpAndSettle();

    expect(foodInList('燕麦酸奶'), findsOneWidget);
    expect(foodInList('168 千卡 / 1 碗'), findsOneWidget);
  });

  testWidgets('food selected items can be reduced after tapping add too much',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('module_link_2')));
    await tester.pumpAndSettle();

    final foodList = find.byKey(const ValueKey('food_main_list'));
    final stapleCategory = find.byKey(const ValueKey('food_category_主食'));
    await tester.scrollUntilVisible(
      stapleCategory,
      80,
      scrollable: find.byKey(const ValueKey('food_category_scroller')),
    );
    await tester.pumpAndSettle();
    await tester.tap(stapleCategory.first);
    await tester.pumpAndSettle();

    await dragUntilFound(
      tester,
      find.text('米饭'),
      scrollable: foodList,
      maxDrags: 8,
    );
    await tester.tap(find.byKey(const ValueKey('food_add_米饭')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('food_add_米饭')));
    await tester.pumpAndSettle();

    expect(find.text('已选 2 项 · 232 千卡'), findsOneWidget);
    expect(find.byKey(const ValueKey('food_selected_count_米饭')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('food_remove_米饭')));
    await tester.pumpAndSettle();

    expect(find.text('已选 1 项 · 116 千卡'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('food_remove_米饭')));
    await tester.pumpAndSettle();

    expect(find.text('已选 0 项 · 0 千卡'), findsOneWidget);
    expect(find.byKey(const ValueKey('food_remove_米饭')), findsNothing);
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
}
