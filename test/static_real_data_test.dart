// 中文注释：自动化测试文件，负责验证界面统计不再使用演示假数据。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home and widget summaries do not fall back to demo records', () {
    final homeSeed = File('lib/home/life_home_seed_data.dart').readAsStringSync();
    final widgetProvider = File(
      'android/app/src/main/kotlin/com/pingsheng/pingsheng_life/PingShengWidgetProvider.kt',
    ).readAsStringSync();
    final mainActivity = File(
      'android/app/src/main/kotlin/com/pingsheng/pingsheng_life/MainActivity.kt',
    ).readAsStringSync();

    for (final source in [homeSeed, widgetProvider, mainActivity]) {
      expect(source, isNot(contains('原味板烧鸡腿麦满分')));
      expect(source, isNot(contains('手机分期还款')));
      expect(source, isNot(contains('本月收入')));
      expect(source, isNot(contains('遛狗')));
      expect(source, isNot(contains('做报表')));
    }
    expect(widgetProvider, isNot(contains('defaultFinanceRecordsJson')));
    expect(widgetProvider, isNot(contains('defaultTodosJson')));
    expect(mainActivity, isNot(contains('KEY_PENDING_TODOS, 4')));
  });

  test('finance trend chart is calculated from records only', () {
    final trend = File('lib/modules/finance/finance_trend.dart').readAsStringSync();

    expect(trend, isNot(contains('[410, 358, 492')));
    expect(trend, isNot(contains('[2800, 3000, 3000')));
    expect(trend, contains('final List<FinanceRecord> records;'));
  });
}
