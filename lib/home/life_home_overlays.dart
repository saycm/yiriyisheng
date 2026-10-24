// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

/// 首页弹层与跨模块跳转：模块面板、快速记录面板和关联模块动作。
extension _LifeHomeOverlays on _LifeHomePageState {
  // 打开模块总览面板。
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

  // 打开“快速记录”面板。
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

  // 把快速记录动作转换成目标模块，并投递一次性快捷动作。
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

  // 从待办关联模块跳转到对应模块并触发快捷动作。
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
