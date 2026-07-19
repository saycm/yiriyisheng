// 中文注释：验证 App 跨过午夜恢复时会重新计算今日摘要。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  setUp(mockDefaultWidgetSummary);

  testWidgets('resuming on a new day refreshes daily values', (tester) async {
    var now = DateTime(2026, 7, 10, 23, 50);
    final store = _DayRolloverStore(
      LifeSummarySnapshot(
        foodCalories: 0,
        foodLogs: [
          _foodLog(100, DateTime(2026, 7, 10, 12)),
          _foodLog(200, DateTime(2026, 7, 11, 12)),
        ],
        workoutGroupsByAction: const {},
        todos: const [],
        financeRecords: const [],
        workoutPlans: const [],
        workoutHistory: const [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        home: LifeHomePage(
          appDataStore: store,
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final calories = find.byKey(
      const ValueKey('today_overview_metric_热量'),
    );
    expect(find.descendant(of: calories, matching: find.text('100')),
        findsOneWidget);

    now = DateTime(2026, 7, 11, 0, 5);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.descendant(of: calories, matching: find.text('200')),
        findsOneWidget);
    expect(find.descendant(of: calories, matching: find.text('100')),
        findsNothing);
  });

  testWidgets('resuming on a new day never reuses yesterday manual status',
      (tester) async {
    final actualToday = DateTime.now();
    var now =
        DateTime(actualToday.year, actualToday.month, actualToday.day, 23);
    const manualChannel = MethodChannel('pingsheng_life/health_manual');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(manualChannel, (call) async {
      if (call.method == 'loadHealthManualRecords') {
        return jsonEncode([
          {
            'date': _dateIso(now),
            'bodyTag': '疲惫',
            'energyLevel': 1,
            'fatigueLevel': 5,
            'stressLevel': 5,
            'painNote': '',
            'moodNote': '低落',
            'sleep': 'poor',
            'energy': 'tired',
            'stress': 'high',
            'body': 'normal',
            'mood': 'low',
          },
        ]);
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(manualChannel, null);
    });
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
    addTearDown(
      () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
    );
    mockSystemHealthStatus(
      status: 'permissionRequired',
      message: '未授权。',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const SizedBox.shrink(),
        routes: {
          '/health': (_) => LifeHomePage(
                appDataStore: _DayRolloverStore(
                  const LifeSummarySnapshot(
                    foodCalories: 0,
                    workoutGroupsByAction: {},
                    todos: [],
                    financeRecords: [],
                  ),
                ),
                now: () => now,
              ),
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('睡眠感较差'), findsWidgets);

    now = DateUtils.dateOnly(now).add(const Duration(days: 1, minutes: 5));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('睡眠感较差'), findsNothing);
    expect(find.text('睡眠一般'), findsWidgets);
  });
}

String _dateIso(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

FoodLogEntry _foodLog(int calories, DateTime recordedAt) {
  return FoodLogEntry(
    food: FoodItem(
      emoji: '',
      name: '测试食物',
      calorie: calories,
      unit: '1 份',
      group: '自定义',
    ),
    meal: '午餐',
    servings: 1,
    note: '',
    recordedAt: recordedAt,
  );
}

class _DayRolloverStore implements LifeSummaryStore {
  _DayRolloverStore(this.snapshot);

  final LifeSummarySnapshot snapshot;

  @override
  Future<LifeSummarySnapshot?> load() async => snapshot;

  @override
  Future<void> save({
    required int foodCalories,
    required List<FoodLogEntry> foodLogs,
    required Map<String, int> workoutGroupsByAction,
    required DateTime? workoutProgressDate,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
    required List<WorkoutPlan> workoutPlans,
    required ActiveWorkoutSession? activeWorkoutSession,
    required List<WorkoutHistoryEntry> workoutHistory,
    required String aiFinanceEndpoint,
    required String aiFinanceModel,
    required String aiFinanceApiKey,
    required AiFinanceParseStrategy aiFinanceParseStrategy,
    required String aiFinanceCustomPrompt,
  }) async {}
}
