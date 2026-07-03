import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  test('storage rows preserve finance account tags and date', () {
    final record = FinanceRecord(
      icon: Icons.restaurant_rounded,
      title: '三餐',
      subtitle: '午饭',
      amount: 28,
      type: '支出',
      date: DateTime(2026, 6, 5),
      account: '微信',
      tags: const ['工作餐', '外卖'],
    );

    final row = AppDataStoreRows.financeRecordToRow(record, 3);
    final restored = AppDataStoreRows.financeRecordFromRow(row);

    expect(row['position'], 3);
    expect(restored.title, '三餐');
    expect(restored.account, '微信');
    expect(restored.tags, ['工作餐', '外卖']);
    expect(restored.date, DateTime(2026, 6, 5));
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
}

class _FailingLifeSummaryStore implements LifeSummaryStore {
  var saveCalls = 0;

  @override
  Future<LifeSummarySnapshot?> load() async => null;

  @override
  Future<void> save({
    required int foodCalories,
    required Map<String, int> workoutGroupsByAction,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
    required List<WorkoutPlan> workoutPlans,
    required ActiveWorkoutSession? activeWorkoutSession,
    required List<WorkoutHistoryEntry> workoutHistory,
    required String aiFinanceEndpoint,
    required String aiFinanceModel,
    required String aiFinanceApiKey,
    required AiFinanceParseStrategy aiFinanceParseStrategy,
  }) async {
    saveCalls++;
    throw StateError('disk full');
  }
}
