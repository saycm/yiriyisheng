// 中文注释：自动化测试文件，负责验证对应模块行为和回归场景。

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  test('life data models keep json and display behavior stable', () {
    final todo = TodoItem(
      id: 'todo_test',
      title: '还信用卡',
      category: '财务',
      color: AppColors.success,
      priority: TodoPriority.mustDo,
      status: TodoStatus.completed,
      dueDate: DateTime(2026, 6, 19, 18),
      note: '招商银行',
      repeatRule: TodoRepeatRule.monthly,
      linkedModules: const [TodoLinkedModule.finance, TodoLinkedModule.health],
      postponedCount: 2,
      createdAt: DateTime(2026, 6, 1, 8),
      completedAt: DateTime(2026, 6, 19, 9),
    );

    final restoredTodo =
        TodoItem.fromJson(todo.toJson().cast<String, dynamic>());
    expect(restoredTodo.id, 'todo_test');
    expect(restoredTodo.priority, TodoPriority.mustDo);
    expect(restoredTodo.status, TodoStatus.completed);
    expect(restoredTodo.dueDate, DateTime(2026, 6, 19));
    expect(restoredTodo.repeatRule, TodoRepeatRule.monthly);
    expect(
        restoredTodo.linkedModules,
        containsAll([
          TodoLinkedModule.finance,
          TodoLinkedModule.health,
        ]));
    expect(restoredTodo.postponedCount, 2);

    final record = FinanceRecord.fromJson({
      'title': '工资',
      'subtitle': '6 月',
      'amount': 12800,
      'type': '收入',
      'account': '招商储蓄卡',
      'tags': ['工资卡'],
    });
    expect(record.displayAmount, '+¥12,800.00');
    expect(record.color, AppColors.success);
    expect(record.account, '招商储蓄卡');
    expect(record.tags, ['工资卡']);

    final snapshot = LifeSummarySnapshot(
      foodCalories: 1800,
      workoutGroupsByAction: const {'深蹲': 3},
      todos: [restoredTodo],
      financeRecords: [record],
    );
    expect(snapshot.foodCalories, 1800);
    expect(snapshot.todos?.single.title, '还信用卡');
    expect(snapshot.financeRecords?.single.title, '工资');
  });

  test('health linked module is displayed as status', () {
    expect(TodoLinkedModule.health.label, '状态');
    expect(TodoLinkedModule.health.actionLabel, '看状态');
    expect(todoColorForCategory('状态'), const Color(0xFFFF6F9D));
  });

  test('life summary snapshot carries workout training state', () {
    final plan = WorkoutPlan(
      id: 'plan-chest',
      name: '胸背强化',
      target: '胸背训练',
      bodyParts: const ['胸背'],
      actionNames: const ['蝴蝶机夹胸'],
      estimatedMinutes: 28,
      createdAt: DateTime(2026, 6, 29),
      updatedAt: DateTime(2026, 6, 29),
    );
    final session = ActiveWorkoutSession(
      id: 'session-1',
      planId: 'plan-chest',
      planName: '胸背强化',
      startedAt: DateTime(2026, 6, 29, 8),
      actionProgress: const {'蝴蝶机夹胸': 2},
    );
    final history = WorkoutHistoryEntry(
      id: 'history-1',
      planId: 'plan-chest',
      planName: '胸背强化',
      startedAt: DateTime(2026, 6, 29, 8),
      finishedAt: DateTime(2026, 6, 29, 8, 30),
      durationMinutes: 30,
      totalGroups: 4,
      estimatedCalories: 128,
      actionResults: const [
        WorkoutActionResult(
          actionName: '蝴蝶机夹胸',
          bodyPart: '胸背',
          targetGroups: 4,
          finishedGroups: 4,
          reps: '8次',
          weight: '30kg',
        ),
      ],
    );

    final snapshot = LifeSummarySnapshot(
      foodCalories: 0,
      workoutGroupsByAction: const {'蝴蝶机夹胸': 4},
      todos: const [],
      financeRecords: const [],
      workoutPlans: [plan],
      activeWorkoutSession: session,
      workoutHistory: [history],
    );

    expect(snapshot.workoutPlans?.single.name, '胸背强化');
    expect(snapshot.activeWorkoutSession?.groupsFor('蝴蝶机夹胸'), 2);
    expect(snapshot.workoutHistory?.single.totalGroups, 4);
  });

  test('daily summary values only count records for selected day', () {
    final today = DateTime(2026, 7, 7);
    final yesterday = DateTime(2026, 7, 6);
    final financeRecords = [
      FinanceRecord(
        icon: Icons.restaurant_rounded,
        title: '今天午餐',
        subtitle: '三餐',
        amount: 28,
        type: '支出',
        date: today,
      ),
      FinanceRecord(
        icon: Icons.restaurant_rounded,
        title: '昨天午餐',
        subtitle: '三餐',
        amount: 18,
        type: '支出',
        date: yesterday,
      ),
      FinanceRecord(
        icon: Icons.payments_rounded,
        title: '今天收入',
        subtitle: '工资',
        amount: 300,
        type: '收入',
        date: today,
      ),
    ];
    final foodLogs = [
      FoodLogEntry(
        food: const FoodItem(
          emoji: '🍚',
          name: '米饭',
          calorie: 116,
          unit: '100 克',
          group: '主食',
        ),
        meal: '午餐',
        servings: 1,
        note: '',
        recordedAt: today.add(const Duration(hours: 12)),
      ),
      FoodLogEntry(
        food: const FoodItem(
          emoji: '🥚',
          name: '鸡蛋',
          calorie: 144,
          unit: '100 克',
          group: '蛋白',
        ),
        meal: '早餐',
        servings: 1,
        note: '',
        recordedAt: yesterday.add(const Duration(hours: 8)),
      ),
    ];
    final activeSession = ActiveWorkoutSession(
      planId: 'today-plan',
      planName: '今日训练',
      startedAt: today.add(const Duration(hours: 9)),
      actionProgress: const {'深蹲': 2},
    );
    final workoutHistory = [
      WorkoutHistoryEntry(
        planId: 'yesterday-plan',
        planName: '昨日训练',
        startedAt: yesterday.add(const Duration(hours: 18)),
        finishedAt: yesterday.add(const Duration(hours: 19)),
        durationMinutes: 45,
        totalGroups: 6,
        estimatedCalories: 188,
        actionResults: const [],
      ),
      WorkoutHistoryEntry(
        planId: 'today-done',
        planName: '今日完成',
        startedAt: today.add(const Duration(hours: 7)),
        finishedAt: today.add(const Duration(hours: 8)),
        durationMinutes: 35,
        totalGroups: 4,
        estimatedCalories: 152,
        actionResults: const [],
      ),
    ];

    expect(todayFinanceTotal(financeRecords, '支出', today), 28);
    expect(todayFinanceTotal(financeRecords, '收入', today), 300);
    expect(todayFoodCalories(foodLogs, today), 116);
    expect(
      todayWorkoutGroups(
        history: workoutHistory,
        activeSession: activeSession,
        today: today,
      ),
      6,
    );
  });

  test('postponing a todo moves from its own date to next workday', () {
    final fridayTodo = TodoItem(
      title: '周五任务',
      category: '工作',
      color: AppColors.primary,
      dueDate: DateTime(2026, 7, 3),
    );

    fridayTodo.postponeToNextWorkday(today: DateTime(2026, 7, 1));

    expect(fridayTodo.dueDate, DateTime(2026, 7, 6));
    expect(fridayTodo.status, TodoStatus.postponed);
    expect(fridayTodo.postponedCount, 1);

    fridayTodo.postponeToNextWorkday(today: DateTime(2026, 7, 1));

    expect(fridayTodo.dueDate, DateTime(2026, 7, 7));
    expect(fridayTodo.postponedCount, 2);
  });

  test('undated todo postpones from today to next workday', () {
    final todo = TodoItem(
      title: '无日期任务',
      category: '生活',
      color: AppColors.primary,
    );

    todo.postponeToNextWorkday(today: DateTime(2026, 7, 3));

    expect(todo.dueDate, DateTime(2026, 7, 6));
  });
}
