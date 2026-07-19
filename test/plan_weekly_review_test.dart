// 中文注释：验证本周复盘只汇总当前自然周的真实记录。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  setUp(mockDefaultWidgetSummary);

  testWidgets('weekly review excludes records and tasks outside current week',
      (tester) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final previousWeek = weekStart.subtract(const Duration(days: 1));
    final store = _WeeklyReviewStore(
      LifeSummarySnapshot(
        foodCalories: 0,
        foodLogs: [
          _foodLog(100, weekStart),
          _foodLog(900, previousWeek),
        ],
        workoutGroupsByAction: const {},
        workoutPlans: const [],
        workoutHistory: [
          _workoutHistory(3, weekStart),
          _workoutHistory(9, previousWeek),
        ],
        todos: [
          TodoItem(
            title: '本周完成',
            category: '工作',
            color: AppColors.primary,
            status: TodoStatus.completed,
            dueDate: weekStart,
            completedAt: weekStart,
          ),
          TodoItem(
            title: '上周完成',
            category: '工作',
            color: AppColors.primary,
            status: TodoStatus.completed,
            dueDate: previousWeek,
            completedAt: previousWeek,
          ),
        ],
        financeRecords: const [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: LifeHomePage(appDataStore: store)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_3')));
    await tester.pumpAndSettle();

    expect(find.text('已完成 1 项，还有 0 项待处理'), findsOneWidget);
    expect(find.text('100 kcal'), findsWidgets);
    expect(find.text('1,000 kcal'), findsNothing);
    expect(find.text('3 组'), findsWidgets);
    expect(find.text('12 组'), findsNothing);
  });
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

WorkoutHistoryEntry _workoutHistory(int groups, DateTime day) {
  return WorkoutHistoryEntry(
    planId: 'plan-$groups',
    planName: '测试训练',
    startedAt: day,
    finishedAt: day.add(const Duration(minutes: 20)),
    durationMinutes: 20,
    totalGroups: groups,
    estimatedCalories: 0,
    actionResults: const [],
  );
}

class _WeeklyReviewStore implements LifeSummaryStore {
  _WeeklyReviewStore(this.snapshot);

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
