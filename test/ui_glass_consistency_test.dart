// 中文注释：UI 风格回归测试，防止高频页面重新出现旧白底硬卡片。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('high traffic module views use glass surfaces instead of legacy cards',
      () {
    final files = [
      File('lib/modules/workout/workout_plan_views.dart'),
      File('lib/modules/plan/widgets/inbox_view.dart'),
      File('lib/modules/plan/widgets/plan_stats_view.dart'),
      File('lib/modules/finance/finance_assets.dart'),
      File('lib/modules/finance/finance_records.dart'),
      File('lib/shared/module_settings_sheet.dart'),
      File('lib/shared/module_info_sheets.dart'),
      File('lib/modules/workout/workout_more_sheet.dart'),
      File('lib/modules/workout/workout_data_views.dart'),
      File('lib/modules/health/health_external_source_views.dart'),
      File('lib/modules/health/health_metric_views.dart'),
      File('lib/modules/workout/workout_action_views.dart'),
      File('lib/modules/workout/workout_history_views.dart'),
      File('lib/modules/finance/finance_health.dart'),
      File('lib/modules/finance/finance_budget.dart'),
      File('lib/modules/food/food_summary_views.dart'),
      File('lib/modules/food/food_browser_views.dart'),
    ];

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('color: AppColors.surface,')),
        reason: '${file.path} should not use opaque legacy surface cards.',
      );
      expect(
        source,
        contains('GlassSurface'),
        reason: '${file.path} should use the shared liquid glass surface.',
      );
    }
  });
}
