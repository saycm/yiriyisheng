// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

extension _LifeHomePersistence on _LifeHomePageState {
  Future<void> _restoreAppData() async {
    try {
      final stored = await _appDataStore.load();
      if (!mounted) {
        return;
      }
      if (stored != null) {
        _updateState(() {
          _applyLifeSummarySnapshot(stored);
          _appDataRestoreComplete = true;
        });
        _syncLinkedSummaryToWidget();
        return;
      }

      final snapshot = await _LifeHomePageState._widgetStore.load();
      if (!mounted) {
        return;
      }
      // 兼容旧版本：首次有 SQLite 前，从桌面小组件共享摘要迁移一次。
      _updateState(() {
        _applyLifeSummarySnapshot(snapshot);
        _appDataRestoreComplete = true;
      });
      _syncLinkedSummaryToWidget();
    } catch (_) {
      if (mounted) {
        _updateState(() {
          _appDataLoadFailed = true;
          _appDataRestoreComplete = true;
        });
      }
    }
  }

  void _applyLifeSummarySnapshot(LifeSummarySnapshot snapshot) {
    _foodState.applySnapshot(snapshot);
    _workoutState.applySnapshot(snapshot);
    _planState.applySnapshot(snapshot);
    _financeState.applySnapshot(snapshot);
  }

  void _syncLinkedSummaryToWidget() {
    if (!_appDataRestoreComplete || _appDataLoadFailed) {
      return;
    }
    // App 主数据写 SQLite；桌面小组件只接收摘要和快捷入口数据。
    final today = _now;
    final foodCalories = todayFoodCaloriesFromState(today);
    final workoutGroups = todayWorkoutGroupsFromState(today);
    unawaited(_saveAppData());
    unawaited(
      _LifeHomePageState._widgetStore.save(
        foodCalories: foodCalories,
        foodLogs: _foodState.logs,
        workoutGroupsByAction: todayWorkoutGroupsByActionFromState(today),
        workoutProgressDate: _workoutState.progressDate,
        workoutGroups: workoutGroups,
        todos: _planState.todos,
        financeRecords: _financeState.records,
      ),
    );
  }

  Future<void> _saveAppData() async {
    if (!_appDataRestoreComplete || _appDataLoadFailed) {
      return;
    }
    try {
      await _appDataStore.save(
        foodCalories: todayFoodCaloriesFromState(_now),
        foodLogs: _foodState.logs,
        workoutGroupsByAction: _workoutState.groupsByAction,
        workoutProgressDate: _workoutState.progressDate,
        todos: _planState.todos,
        financeRecords: _financeState.records,
        workoutPlans: _workoutState.plans,
        activeWorkoutSession: _workoutState.activeSession,
        workoutHistory: _workoutState.history,
        aiFinanceEndpoint: _financeState.aiEndpoint,
        aiFinanceModel: _financeState.aiModel,
        aiFinanceApiKey: _financeState.aiApiKey,
        aiFinanceParseStrategy: _financeState.aiParseStrategy,
        aiFinanceCustomPrompt: _financeState.aiCustomPrompt,
      );
      if (mounted && _appDataSaveFailed) {
        _updateState(() => _appDataSaveFailed = false);
      }
    } catch (_) {
      _showAppDataSaveFailure();
    }
  }

  void _showAppDataSaveFailure() {
    if (!mounted || _appDataSaveFailed) {
      return;
    }
    _updateState(() => _appDataSaveFailed = true);
  }
}
