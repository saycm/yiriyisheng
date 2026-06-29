part of '../main.dart';

extension _LifeHomePersistence on _LifeHomePageState {
  Future<void> _restoreAppData() async {
    final stored = await _LifeHomePageState._appDataStore.load();
    if (!mounted) {
      return;
    }
    if (stored != null) {
      _updateState(() => _applyLifeSummarySnapshot(stored));
      _syncLinkedSummaryToWidget();
      return;
    }

    final snapshot = await _LifeHomePageState._widgetStore.load();
    if (!mounted) {
      return;
    }
    // 兼容旧版本：首次有 SQLite 前，从桌面小组件共享摘要迁移一次。
    _updateState(() => _applyLifeSummarySnapshot(snapshot));
    _syncLinkedSummaryToWidget();
  }

  void _applyLifeSummarySnapshot(LifeSummarySnapshot snapshot) {
    _recordedFoodCalories = snapshot.foodCalories;
    _workoutGroupsByAction
      ..clear()
      ..addAll(snapshot.workoutGroupsByAction);
    final restoredTodos = snapshot.todos;
    if (restoredTodos != null) {
      _todos
        ..clear()
        ..addAll(restoredTodos);
    }
    final restoredFinanceRecords = snapshot.financeRecords;
    if (restoredFinanceRecords != null) {
      _financeRecords
        ..clear()
        ..addAll(restoredFinanceRecords);
    }
    final restoredWorkoutPlans = snapshot.workoutPlans;
    if (restoredWorkoutPlans != null && restoredWorkoutPlans.isNotEmpty) {
      _workoutPlans
        ..clear()
        ..addAll(restoredWorkoutPlans);
    }
    _activeWorkoutSession = snapshot.activeWorkoutSession;
    final restoredWorkoutHistory = snapshot.workoutHistory;
    if (restoredWorkoutHistory != null) {
      _workoutHistory
        ..clear()
        ..addAll(restoredWorkoutHistory);
    }
    _aiFinanceEndpoint = snapshot.aiFinanceEndpoint.trim().isEmpty
        ? _defaultGlmChatEndpoint
        : snapshot.aiFinanceEndpoint;
    _aiFinanceModel = snapshot.aiFinanceModel.trim().isEmpty
        ? _defaultGlmTextModel
        : snapshot.aiFinanceModel;
    _aiFinanceApiKey = snapshot.aiFinanceApiKey;
  }

  void _syncLinkedSummaryToWidget() {
    // App 主数据写 SQLite；桌面小组件只接收摘要和快捷入口数据。
    unawaited(
      _LifeHomePageState._appDataStore.save(
        foodCalories: _recordedFoodCalories,
        workoutGroupsByAction: _workoutGroupsByAction,
        todos: _todos,
        financeRecords: _financeRecords,
        workoutPlans: _workoutPlans,
        activeWorkoutSession: _activeWorkoutSession,
        workoutHistory: _workoutHistory,
        aiFinanceEndpoint: _aiFinanceEndpoint,
        aiFinanceModel: _aiFinanceModel,
        aiFinanceApiKey: _aiFinanceApiKey,
      ),
    );
    unawaited(
      _LifeHomePageState._widgetStore.save(
        foodCalories: _recordedFoodCalories,
        workoutGroupsByAction: _workoutGroupsByAction,
        todos: _todos,
        financeRecords: _financeRecords,
      ),
    );
  }
}
