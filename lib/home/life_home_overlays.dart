// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

extension _LifeHomeOverlays on _LifeHomePageState {
  void _openModuleSheet() {
    final today = DateTime.now();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ModuleSheet(
          selected: _module,
          pendingTodos: _pendingTodoCount,
          foodCalories: todayFoodCaloriesFromState(today),
          workoutGroups: todayWorkoutGroupsFromState(today),
          todayExpense: todayFinanceTotal(_financeState.records, '支出', today),
          events: _planState.events,
          onSelect: (module) {
            Navigator.of(context).pop();
            _setModule(module);
          },
          onSignOut: widget.onSignOut,
        );
      },
    );
  }

  void _openQuickRecordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _QuickRecordSheet(
          onSelect: (action) {
            Navigator.of(context).pop();
            _dispatchQuickRecordAction(action);
          },
        );
      },
    );
  }

  void _dispatchQuickRecordAction(WidgetQuickAction action) {
    final module = switch (action) {
      WidgetQuickAction.addTodo => LifeModule.plan,
      WidgetQuickAction.addFinance => LifeModule.finance,
      WidgetQuickAction.addFood => LifeModule.food,
      WidgetQuickAction.startWorkout => LifeModule.workout,
      WidgetQuickAction.openHealth => LifeModule.health,
    };
    _updateState(() {
      _module = module;
      _pendingQuickAction = action;
      _quickActionToken++;
    });
  }

  void _openLinkedModuleAction(TodoLinkedModule linkedModule) {
    final target = linkedModule.lifeModule;
    final action = linkedModule.quickAction;
    _updateState(() {
      _module = target;
      _pendingQuickAction = action;
      _quickActionToken++;
    });
  }
}
