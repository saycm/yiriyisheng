// 中文注释：测试辅助工具，负责复用测试里的滚动、点击和平台通道模拟。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void mockDefaultWidgetSummary() {
  const channel = MethodChannel('pingsheng_life/widget_summary');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'loadLifeSummary':
        final today = DateTime.now();
        final todayIso = _dateOnly(today).toIso8601String();
        final tomorrowIso =
            _dateOnly(today.add(const Duration(days: 1))).toIso8601String();
        return {
          'foodCalories': 0,
          'pendingTodos': 6,
          'todosJson': jsonEncode([
            _todoJson('遛狗', '生活', 'shouldDo', todayIso),
            _todoJson('打羽毛球', '健康', 'mustDo', todayIso,
                linkedModules: ['workout', 'health']),
            _todoJson('做报表', '工作', 'mustDo', todayIso,
                status: 'inProgress'),
            _todoJson('还信用卡', '财务', 'mustDo', todayIso,
                linkedModules: ['finance'], note: '完成后补一条还款记录。'),
            _todoJson('早睡', '健康', 'shouldDo', tomorrowIso,
                repeatRule: 'daily', linkedModules: ['health']),
            _todoJson('整理学习清单', '学习', 'canDelay', null,
                note: '无日期任务先放进待办箱。'),
          ]),
          'financeRecordsJson': jsonEncode([
            _financeJson('三餐', '原味板烧鸡腿麦满分', 18, '支出', '现金'),
            _financeJson('数码分期', '手机分期还款', 500, '支出', '信用卡'),
            _financeJson('工资', '本月收入', 3000, '收入', '银行卡'),
            _financeJson('咖啡', '优品豆浆（小杯）', 6, '支出', '支付宝'),
          ]),
          'workoutGroups': 0,
          'workoutGroupsJson': '{}',
        };
      case 'saveLifeSummary':
        return null;
      default:
        return null;
    }
  });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
}

Map<String, Object?> _todoJson(
  String title,
  String category,
  String priority,
  String? dueDate, {
  String status = 'pending',
  String? repeatRule,
  String? note,
  List<String> linkedModules = const [],
}) {
  return {
    'id': 'test_${title.hashCode}',
    'title': title,
    'category': category,
    'priority': priority,
    'status': status,
    'dueDate': dueDate,
    'note': note,
    'repeatRule': repeatRule,
    'linkedModules': linkedModules,
    'postponedCount': 0,
    'createdAt': DateTime.now().toIso8601String(),
    'completedAt': null,
  };
}

Map<String, Object?> _financeJson(
  String title,
  String subtitle,
  double amount,
  String type,
  String account,
) {
  return {
    'title': title,
    'subtitle': subtitle,
    'amount': amount,
    'type': type,
    'date': DateTime.now().toIso8601String(),
    'account': account,
    'tags': const [],
  };
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

Future<void> pumpPingShengApp(WidgetTester tester) async {
  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();
}

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

void mockSystemHealthPermissionFlow() {
  const channel = MethodChannel('pingsheng_life/system_health');
  var granted = false;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'loadHealthSnapshot') {
      return {
        'status': granted ? 'ok' : 'permissionRequired',
        'message': granted ? '已连接 Health Connect 和本机传感器。' : '还没有授予步数、睡眠和心率权限。',
        'lastUpdated': '2026-06-05T08:30:00.000Z',
        'sensors': {
          'stepCounterAvailable': granted,
          'heartRateSensorAvailable': granted,
          'accelerometerAvailable': granted,
        },
        'days': [
          if (granted)
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
      granted = true;
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

VoidCallback mockSystemHealthDelayedSnapshot() {
  const channel = MethodChannel('pingsheng_life/system_health');
  final firstLoad = Completer<Map<String, Object?>>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'loadHealthSnapshot') {
      return firstLoad.future;
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
  return () {
    if (firstLoad.isCompleted) {
      return;
    }
    firstLoad.complete({
      'status': 'ok',
      'message': '已连接 Health Connect 和本机传感器。',
      'lastUpdated': '2026-06-05T08:30:00.000Z',
      'sensors': {
        'stepCounterAvailable': true,
        'heartRateSensorAvailable': true,
        'accelerometerAvailable': true,
      },
      'days': [
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
    });
  };
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

Future<void> openFinanceAiRecord(WidgetTester tester) async {
  final aiRecord = find.byKey(const ValueKey('finance_ai_record'));
  await dragUntilFound(
    tester,
    aiRecord,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(aiRecord);
  await tester.pumpAndSettle();
}

Future<void> tapWorkoutActionByName(
  WidgetTester tester,
  String actionName,
) async {
  final workoutList = find.byKey(const ValueKey('workout_main_list'));
  await dragUntilFound(
    tester,
    find.text(actionName),
    scrollable: workoutList,
    maxDrags: 18,
  );
  await tester.tap(find.text(actionName).first);
  await tester.pumpAndSettle();
}
