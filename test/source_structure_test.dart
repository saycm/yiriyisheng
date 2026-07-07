// 中文注释：自动化测试文件，负责验证对应模块行为和回归场景。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

int _lineCount(String path) => File(path).readAsLinesSync().length;

String _file(String path) => File(path).readAsStringSync();

String _section(String source, String start, String end) {
  final startIndex = source.indexOf(start);
  expect(startIndex, isNonNegative, reason: start);
  final endIndex = source.indexOf(end, startIndex + start.length);
  expect(endIndex, isNonNegative, reason: end);
  return source.substring(startIndex, endIndex);
}

String _sectionToEnd(String source, String start) {
  final startIndex = source.indexOf(start);
  expect(startIndex, isNonNegative, reason: start);
  return source.substring(startIndex);
}

void main() {
  test('finance ai core is an importable library outside the app part chain',
      () {
    final main = File('lib/main.dart').readAsStringSync();
    final core =
        File('lib/modules/finance/finance_ai_core.dart').readAsStringSync();

    expect(main, isNot(contains('\npart ')));
    expect(
        main, isNot(contains("part 'modules/finance/finance_ai_core.dart';")));
    expect(core, isNot(contains('part of')));
    expect(core, isNot(contains('IconData')));
    expect(core, isNot(contains('_AiFinanceQuickCommand')));
    expect(core, isNot(contains('FinanceRecord')));
  });

  test('largest auth and health entry files are split into focused parts', () {
    expect(_lineCount('lib/auth/auth.dart'), lessThan(900));
    expect(File('lib/auth/auth_update_pages.dart').existsSync(), isTrue);
    expect(File('lib/auth/auth_visuals.dart').existsSync(), isTrue);

    expect(_lineCount('lib/modules/health/health_module.dart'), lessThan(1200));
    expect(File('lib/modules/health/health_manual_views.dart').existsSync(),
        isTrue);
    expect(File('lib/modules/health/health_metric_views.dart').existsSync(),
        isTrue);
    expect(File('lib/modules/health/health_status_views.dart').existsSync(),
        isTrue);
    expect(
        File('lib/modules/health/health_external_source_views.dart')
            .existsSync(),
        isTrue);
  });

  test('android release disables impeller on emulator-hosted Vulkan', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(
      manifest,
      contains('android:name="io.flutter.embedding.android.EnableImpeller"'),
    );
    expect(manifest, contains('android:value="false"'));
  });

  test('android keeps image permissions', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android.permission.READ_MEDIA_IMAGES'));
    expect(manifest, contains('android.permission.READ_EXTERNAL_STORAGE'));
  });

  test('week plan is split into focused part files', () {
    final plan = File('lib/modules/plan/plan.dart').readAsStringSync();
    final weekFiles = [
      'lib/modules/plan/widgets/week/week_plan_view.dart',
      'lib/modules/plan/widgets/week/week_plan_actions.dart',
      'lib/modules/plan/widgets/week/week_feedback.dart',
      'lib/modules/plan/widgets/week/week_command_center.dart',
      'lib/modules/plan/widgets/week/week_day_board.dart',
      'lib/modules/plan/widgets/week/week_backlog_section.dart',
      'lib/modules/plan/widgets/week/week_selected_tasks_panel.dart',
    ];

    for (final path in weekFiles) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(
        File(path).readAsStringSync(),
        contains("part of '../../plan.dart';"),
        reason: path,
      );
    }

    expect(plan, isNot(contains("part 'widgets/week_plan_view.dart';")));
    expect(
      plan,
      contains("part 'widgets/week/week_plan_view.dart';"),
    );
    expect(_lineCount('lib/modules/plan/widgets/week/week_plan_view.dart'),
        lessThan(260));
  });

  test('app data store is split into rows and table helpers', () {
    final storage = File('lib/storage/storage.dart').readAsStringSync();
    final rows = File('lib/storage/app_data_rows.dart');
    final tables = File('lib/storage/app_data_tables.dart');
    final store = File('lib/storage/app_data_store.dart');

    expect(rows.existsSync(), isTrue);
    expect(tables.existsSync(), isTrue);
    expect(rows.readAsStringSync(), contains("part of 'storage.dart';"));
    expect(tables.readAsStringSync(), contains("part of 'storage.dart';"));
    expect(storage, contains("part 'app_data_rows.dart';"));
    expect(storage, contains("part 'app_data_tables.dart';"));
    expect(_lineCount(store.path), lessThan(420));
  });

  test('secondary app entry pages use the liquid glass backdrop', () {
    final auth = _file('lib/auth/auth.dart');
    final authVisuals = _file('lib/auth/auth_visuals.dart');
    final updates = _file('lib/auth/auth_update_pages.dart');
    final assistant = _file('lib/modules/finance/finance_ai_assistant.dart');
    final settings = _file('lib/modules/finance/finance_ai_settings.dart');

    final authPage = _section(auth, 'class _AuthPage', 'class _AuthStatusPage');
    expect(authPage, contains('LiquidModuleBackground'));

    final authPanel =
        _section(authVisuals, 'class _AuthFormPanel', 'class _AuthHeader');
    expect(authPanel, contains('GlassSurface'));

    final statusPage = _sectionToEnd(auth, 'class _AuthStatusPage');
    expect(statusPage, contains('LiquidModuleBackground'));
    expect(statusPage, contains('GlassSurface'));

    for (final page in [
      _section(updates, 'class _ForceUpdatePage', 'class _OptionalUpdatePage'),
      _section(updates, 'class _OptionalUpdatePage', 'class _UpdateLine'),
      _section(
        assistant,
        'class _FinanceAiAssistantPage',
        'class _FinanceAiAssistantHeader',
      ),
      _section(
        settings,
        'class _FinanceAiSettingsPage',
        'class _FinanceAiProviderManagePage',
      ),
    ]) {
      expect(page, contains('LiquidModuleBackground'));
      expect(page, contains('GlassSurface'));
    }
  });

  test('shared bottom sheet frames keep glass material at the shell', () {
    final common = _file('lib/shared/module_common_widgets.dart');
    final infoFrame =
        _section(common, 'class InfoSheetFrame', 'class ModuleSectionTitle');

    expect(infoFrame, contains('LiquidModuleBackground'));
    expect(infoFrame, contains('GlassSurface'));
    expect(infoFrame, isNot(contains('color: AppColors.background')));
  });

  test('module center sheet and detail pages use liquid glass shells', () {
    final moduleCenter = _file('lib/shared/module_center_sheet.dart');
    final workoutDetail =
        _file('lib/modules/workout/workout_action_views.dart');

    final moduleSheet = _section(
        moduleCenter, 'class ModuleSheet', 'class _ModuleTodaySummaryBar');
    expect(moduleSheet, contains('LiquidModuleBackground'));
    expect(moduleSheet, contains('GlassSurface'));
    expect(moduleSheet, isNot(contains('color: AppColors.background')));

    final actionDetail = _section(
      workoutDetail,
      'class _WorkoutActionDetailPage',
      'class _WorkoutProgressBox',
    );
    expect(actionDetail, contains('LiquidModuleBackground'));
    expect(actionDetail, contains('GlassSurface'));
  });

  test('primary record sheets use liquid glass shells around readable forms',
      () {
    final financeRecord =
        _file('lib/modules/finance/finance_record_sheet.dart');
    final foodCustom = _file('lib/modules/food/food_custom_sheet.dart');

    final financeSheet = _section(
      financeRecord,
      'class _FinanceRecordSheet',
      'class _FinanceTypeButton',
    );
    expect(financeSheet, contains('GlassSurface'));
    expect(financeSheet, isNot(contains('LiquidModuleBackground')));

    final foodSheet = _section(
      foodCustom,
      'class _CustomFoodSheet',
      'void _save()',
    );
    expect(foodSheet, contains('LiquidModuleBackground'));
    expect(foodSheet, contains('GlassSurface'));
  });

  test('finance workspace asset card uses a light asset palette', () {
    final workspace = _file('lib/modules/finance/finance_workspace.dart');
    final assetCard = _section(
        workspace, 'class _NetAssetCard', 'class _FinanceWorkspaceMetric');

    expect(assetCard, contains('Color(0xFFF4FBFF)'));
    expect(assetCard, contains('Color(0xFFE6F8F1)'));
    expect(assetCard, contains('Color(0xFFEFF4FF)'));
    expect(assetCard, isNot(contains('Color(0xFF172033)')));
    expect(assetCard, isNot(contains('Color(0xFF2C3D73)')));
  });

  test('food category picker uses the shared glass sheet shell', () {
    final foodCategory =
        _file('lib/modules/food/food_selected_category_views.dart');

    final categorySheet = _section(
      foodCategory,
      'class _FoodCategorySheet',
      'class _FoodCategoryTile',
    );
    expect(categorySheet, contains('InfoSheetFrame'));
    expect(categorySheet, isNot(contains('color: AppColors.background')));

    final categoryTile = _sectionToEnd(foodCategory, 'class _FoodCategoryTile');
    expect(categoryTile, contains('GlassSurface'));
  });

  test('android widget stays content dense and display-only for finance totals',
      () {
    final layout =
        _file('android/app/src/main/res/layout/pingsheng_widget.xml');
    final provider = _file(
      'android/app/src/main/kotlin/com/pingsheng/pingsheng_life/PingShengWidgetProvider.kt',
    );

    expect(layout, contains('@+id/widget_left_summary'));
    expect(layout, contains('@+id/widget_primary_metric_value'));
    expect(layout, contains('@+id/widget_next_todo'));
    expect(layout, contains('@+id/widget_food'));
    expect(layout, contains('@+id/widget_workout'));
    expect(layout, isNot(contains('平生')));

    expect(layout, contains('@+id/widget_finance_expense'));
    expect(layout, contains('@+id/widget_finance_income'));
    expect(layout, contains('android:autoSizeTextType="uniform"'));
    expect(provider, contains('todayExpense(financeRecords)'));
    expect(provider, contains('todayIncome(financeRecords)'));
    expect(provider, isNot(contains('R.id.widget_expense_card,')));
    expect(provider, isNot(contains('R.id.widget_income_card,')));
  });

  test('android step counter exposes daily steps instead of boot total', () {
    final mainActivity = _file(
      'android/app/src/main/kotlin/com/pingsheng/pingsheng_life/MainActivity.kt',
    );
    final sensorSnapshot = _section(mainActivity,
        'private fun buildSensorSnapshot()', 'private fun saveHealthForWidget');

    expect(mainActivity, contains('STEP_COUNTER_BASELINE_PREFS'));
    expect(mainActivity, contains('stepCounterToday'));
    expect(mainActivity, contains('todayStepCounter('));
    expect(sensorSnapshot, contains('"stepCounterToday"'));
    expect(sensorSnapshot, isNot(contains('"stepCounterSinceBoot"')));
  });

  test('android visible module copy uses status naming', () {
    final mainActivity = _file(
      'android/app/src/main/kotlin/com/pingsheng/pingsheng_life/MainActivity.kt',
    );
    final widgetProvider = _file(
      'android/app/src/main/kotlin/com/pingsheng/pingsheng_life/PingShengWidgetProvider.kt',
    );
    final strings = _file('android/app/src/main/res/values/strings.xml');

    expect(strings, contains('状态摘要'));
    expect(mainActivity, contains('状态待授权'));
    expect(widgetProvider, contains('状态待授权'));
    expect(mainActivity, isNot(contains('健康待授权')));
    expect(widgetProvider, isNot(contains('健康待授权')));
    expect(strings, isNot(contains('健康摘要')));
  });
}
