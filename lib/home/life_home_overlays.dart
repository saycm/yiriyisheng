part of '../main.dart';

extension _LifeHomeOverlays on _LifeHomePageState {
  void _openModuleSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ModuleSheet(
          selected: _module,
          pendingTodos: _pendingTodoCount,
          foodCalories: _recordedFoodCalories,
          workoutGroups: _workoutFinishedGroups,
          todayExpense: _todayExpense,
          events: _events,
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

  void _openTodoLinkedActionSheet(TodoItem todo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _TodoLinkedActionSheet(
          todo: todo,
          onSelect: (module) {
            Navigator.of(context).pop();
            _openLinkedModuleAction(module);
          },
        );
      },
    );
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
