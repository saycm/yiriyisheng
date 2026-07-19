// 中文注释：自动化测试文件，负责验证对应模块行为和回归场景。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  const widgetChannel = MethodChannel('pingsheng_life/widget_summary');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (call) async {
      if (call.method == 'loadLifeSummary') {
        return <String, Object?>{
          'foodCalories': 0,
          'foodLogsJson': '[]',
          'workoutGroupsJson': '{}',
          'workoutProgressDate': '',
          'todosJson': '[]',
          'financeRecordsJson': '[]',
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, null);
  });

  test('storage rows preserve finance account tags and date', () {
    final record = FinanceRecord(
      icon: Icons.restaurant_rounded,
      title: '三餐',
      subtitle: '午饭',
      amount: 28,
      type: '支出',
      date: DateTime(2026, 6, 5),
      account: '微信',
      toAccount: '支付宝',
      tags: const ['工作餐', '外卖'],
    );

    final row = AppDataStoreRows.financeRecordToRow(record, 3);
    final restored = AppDataStoreRows.financeRecordFromRow(row);

    expect(row['position'], 3);
    expect(restored.title, '三餐');
    expect(restored.account, '微信');
    expect(restored.toAccount, '支付宝');
    expect(restored.tags, ['工作餐', '外卖']);
    expect(restored.date, DateTime(2026, 6, 5));
  });

  test('legacy monthly todo rows infer anchor from the retained series', () {
    final rows = AppDataStoreRows.todoRowsWithRepeatAnchors([
      <String, Object?>{
        'todoId': 'monthly_todo',
        'repeatRule': 'monthly',
        'dueDate': '2024-01-31T00:00:00.000',
        'repeatAnchorDay': null,
      },
      <String, Object?>{
        'todoId': 'monthly_todo__repeat_20240229',
        'repeatRule': 'monthly',
        'dueDate': '2024-02-29T00:00:00.000',
        'repeatAnchorDay': null,
      },
    ]);

    expect(rows.map((row) => row['repeatAnchorDay']), everyElement(31));
  });

  test('legacy clipped occurrence uses its previous-month generation day', () {
    final rows = AppDataStoreRows.todoRowsWithRepeatAnchors([
      <String, Object?>{
        'todoId': 'monthly_todo__repeat_20240229',
        'repeatRule': 'monthly',
        'dueDate': '2024-02-29T00:00:00.000',
        'createdAt': '2024-01-31T09:00:00.000',
        'repeatAnchorDay': null,
      },
    ]);

    expect(rows.single['repeatAnchorDay'], 31);
  });

  testWidgets('save failures are visible to the user', (tester) async {
    final store = _FailingLifeSummaryStore();
    await tester.pumpWidget(
      MaterialApp(
        home: LifeHomePage(appDataStore: store),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plan_bottom_nav_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plan_inbox_quick_capture')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('plan_inbox_quick_capture_field')),
      '测试保存失败提示',
    );
    await tester.tap(
      find.byKey(const ValueKey('plan_inbox_quick_capture_save')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(store.saveCalls, greaterThan(0));
    expect(find.text('数据保存失败，请稍后重试。'), findsOneWidget);
  });

  testWidgets('load failures never overwrite persisted data', (tester) async {
    final store = _LoadFailingLifeSummaryStore();
    var widgetSaveCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (call) async {
      if (call.method == 'saveLifeSummary') {
        widgetSaveCalls++;
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(widgetChannel, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LifeHomePage(appDataStore: store),
      ),
    );
    await tester.pumpAndSettle();

    expect(store.saveCalls, 0);
    expect(find.text('数据读取失败，已停止自动保存。'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('plan_add_todo_fab')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '读取失败后不覆盖');
    await tester.ensureVisible(find.widgetWithText(FilledButton, '保存'));
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(store.saveCalls, 0);
    expect(widgetSaveCalls, 0);
  });

  testWidgets('home actions wait until persisted data restoration completes',
      (tester) async {
    final store = _DelayedLifeSummaryStore();

    await tester.pumpWidget(
      MaterialApp(home: LifeHomePage(appDataStore: store)),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('plan_add_todo_fab')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('plan_todo_editor_glass_panel')),
        findsNothing);
    expect(store.saveCalls, 0);

    store.complete(
      LifeSummarySnapshot(
        foodCalories: 0,
        workoutGroupsByAction: const {},
        todos: [
          TodoItem(
            title: '已保存任务',
            category: '工作',
            color: todoColorForCategory('工作'),
            dueDate: DateTime.now(),
          ),
        ],
        financeRecords: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
        find.byKey(const ValueKey('app_data_restore_progress')), findsNothing);
    expect(store.savedTodoTitles, contains('已保存任务'));
    await tester.tap(find.byKey(const ValueKey('plan_add_todo_fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan_todo_editor_glass_panel')),
        findsOneWidget);
  });

  testWidgets('widget migration failure exits loading with a visible error',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (call) async {
      if (call.method == 'loadLifeSummary') {
        throw PlatformException(code: 'corrupt_widget_data');
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(widgetChannel, null);
    });

    await tester.pumpWidget(
      MaterialApp(home: LifeHomePage(appDataStore: _NullLifeSummaryStore())),
    );
    await tester.pumpAndSettle();

    expect(find.text('数据读取失败，已停止自动保存。'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('app_data_restore_progress')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy aggregate calories are not assigned to today',
      (tester) async {
    final store = _SnapshotLifeSummaryStore(
      const LifeSummarySnapshot(
        foodCalories: 4653,
        workoutGroupsByAction: {},
        todos: [],
        financeRecords: [],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LifeHomePage(appDataStore: store),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4653'), findsNothing);
    expect(find.text('0'), findsWidgets);
  });
}

class _FailingLifeSummaryStore implements LifeSummaryStore {
  var saveCalls = 0;

  @override
  Future<LifeSummarySnapshot?> load() async => null;

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
  }) async {
    saveCalls++;
    throw StateError('disk full');
  }
}

class _LoadFailingLifeSummaryStore implements LifeSummaryStore {
  var saveCalls = 0;

  @override
  Future<LifeSummarySnapshot?> load() async {
    throw StateError('database corrupt');
  }

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
  }) async {
    saveCalls++;
  }
}

class _SnapshotLifeSummaryStore implements LifeSummaryStore {
  _SnapshotLifeSummaryStore(this.snapshot);

  final LifeSummarySnapshot? snapshot;

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

class _DelayedLifeSummaryStore implements LifeSummaryStore {
  final _loadCompleter = Completer<LifeSummarySnapshot?>();
  var saveCalls = 0;
  List<String> savedTodoTitles = const [];

  void complete(LifeSummarySnapshot snapshot) {
    _loadCompleter.complete(snapshot);
  }

  @override
  Future<LifeSummarySnapshot?> load() => _loadCompleter.future;

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
  }) async {
    saveCalls++;
    savedTodoTitles = todos.map((todo) => todo.title).toList(growable: false);
  }
}

class _NullLifeSummaryStore extends _SnapshotLifeSummaryStore {
  _NullLifeSummaryStore() : super(null);
}
