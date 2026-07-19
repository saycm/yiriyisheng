// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

extension _LifeHomeMutations on _LifeHomePageState {
  void _recordFoodLogs(List<FoodLogEntry> entries) {
    if (entries.isEmpty) {
      return;
    }
    final calories = entries.fold<int>(
      0,
      (total, entry) => total + entry.calories,
    );
    // 饮食模块的记录会进入应用级共享状态，状态模块据此展示今日摄入。
    _updateState(() {
      _foodState.logs.addAll(entries);
      _pushLifeEvent(
        LifeEvent(
          title: '记录饮食',
          detail: '$calories kcal 已同步到状态和计划',
          icon: Icons.restaurant_rounded,
          color: AppColors.success,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _updateWorkoutGroups(String actionName, int finishedGroups) {
    // 锻炼模块完成组数保存在父级，切换到状态/饮食/计划后仍能联动展示。
    final today = DateUtils.dateOnly(_now);
    final startsNewDay = !isSameLocalDay(_workoutState.progressDate, today);
    final previousGroups =
        startsNewDay ? 0 : _workoutState.groupsByAction[actionName] ?? 0;
    _updateState(() {
      if (startsNewDay) {
        _workoutState.groupsByAction.clear();
      }
      _workoutState.progressDate = today;
      _workoutState.groupsByAction[actionName] = finishedGroups;
      if (finishedGroups > previousGroups) {
        _pushLifeEvent(
          LifeEvent(
            title: '完成锻炼',
            detail: '$actionName · $finishedGroups 组',
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
          ),
        );
      }
    });
    _syncLinkedSummaryToWidget();
  }

  void _startWorkoutSession(ActiveWorkoutSession session) {
    _updateState(() {
      _workoutState.activeSession = session;
      _workoutState.progressDate = DateUtils.dateOnly(session.startedAt);
      _pushLifeEvent(
        LifeEvent(
          title: '开始训练',
          detail: session.planName,
          icon: Icons.fitness_center_rounded,
          color: AppColors.primary,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _updateWorkoutSession(ActiveWorkoutSession session) {
    _updateState(() {
      _workoutState.activeSession = session;
      _workoutState.progressDate = DateUtils.dateOnly(session.startedAt);
    });
    _syncLinkedSummaryToWidget();
  }

  void _finishWorkoutSession(WorkoutHistoryEntry entry) {
    _updateState(() {
      _workoutState.history.insert(0, entry);
      _workoutState.activeSession = null;
      _workoutState.progressDate = DateUtils.dateOnly(entry.finishedAt);
      _pushLifeEvent(
        LifeEvent(
          title: '完成训练',
          detail: '${entry.planName} · ${entry.totalGroups} 组',
          icon: Icons.fitness_center_rounded,
          color: AppColors.primary,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _updateWorkoutPlan(WorkoutPlan plan) {
    final index = _workoutState.plans.indexWhere((item) => item.id == plan.id);
    if (index == -1) {
      // 三点菜单的新建/复制计划会产生新 id，这里负责把它纳入首页状态。
      _updateState(() => _workoutState.plans.add(plan));
      _syncLinkedSummaryToWidget();
      return;
    }
    _updateState(() => _workoutState.plans[index] = plan);
    _syncLinkedSummaryToWidget();
  }

  void _toggleTodo(TodoItem todo) {
    final wasDone = todo.done;
    final generatedOccurrence = wasDone ? todo.createNextOccurrence() : null;
    _updateState(() {
      todo.done = !todo.done;
      final nextOccurrence = !wasDone ? todo.createNextOccurrence() : null;
      if (nextOccurrence != null &&
          !_planState.todos.any((item) => item.id == nextOccurrence.id)) {
        _planState.todos.add(nextOccurrence);
      }
      if (generatedOccurrence != null) {
        _planState.todos.removeWhere(
          (item) => isUntouchedTodoOccurrence(item, generatedOccurrence),
        );
      }
      _pushLifeEvent(
        LifeEvent(
          title: todo.done ? '完成待办' : '重新打开待办',
          detail: todo.done ? _todoCompletionDetail(todo) : todo.title,
          icon: Icons.event_available_rounded,
          color: todo.color,
        ),
      );
      if (!wasDone && todo.done) {
        _pushLinkedTodoEvent(todo);
      }
    });
    _syncLinkedSummaryToWidget();
  }

  void _updateTodo(TodoItem todo) {
    final index = _planState.todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) {
      return;
    }
    _updateState(() => _planState.todos[index] = todo);
    _syncLinkedSummaryToWidget();
  }

  void _postponeTodo(TodoItem todo) {
    _updateState(() {
      final targetDate = todo.postponeToNextWorkday();
      _pushLifeEvent(
        LifeEvent(
          title: '延后待办',
          detail: '${todo.title} · ${_shortTodoDate(targetDate)}处理',
          icon: Icons.event_repeat_rounded,
          color: todo.color,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  String _shortTodoDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  void _archiveTodo(TodoItem todo) {
    _updateState(() {
      todo.archive();
      _pushLifeEvent(
        LifeEvent(
          title: '归档待办',
          detail: todo.title,
          icon: Icons.archive_rounded,
          color: AppColors.muted,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _deleteTodo(TodoItem todo) {
    _updateState(() {
      _planState.todos.removeWhere((item) => item.id == todo.id);
      _pushLifeEvent(
        LifeEvent(
          title: '删除待办',
          detail: todo.title,
          icon: Icons.delete_outline_rounded,
          color: AppColors.financeRed,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _addTodo(TodoItem todo) {
    _updateState(() {
      _planState.todos.add(todo);
      _pushLifeEvent(
        LifeEvent(
          title: '新增待办',
          detail: todo.title,
          icon: Icons.add_task_rounded,
          color: todo.color,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _clearCompletedTodos() {
    final count = _planState.todos.where((todo) => todo.done).length;
    _updateState(() {
      _planState.todos.removeWhere((todo) => todo.done);
      if (count > 0) {
        _pushLifeEvent(
          LifeEvent(
            title: '清理待办箱',
            detail: '移除 $count 项完成记录',
            icon: Icons.archive_rounded,
            color: AppColors.muted,
          ),
        );
      }
    });
    _syncLinkedSummaryToWidget();
  }

  void _pushLinkedTodoEvent(TodoItem todo) {
    for (final module in todo.linkedModules) {
      _pushLifeEvent(
        LifeEvent(
          title: '${module.label}提醒',
          detail: linkedTodoPrompt(todo, module),
          icon: module.icon,
          color: module.color,
        ),
      );
    }
  }

  String _todoCompletionDetail(TodoItem todo) {
    if (todo.linkedModules.isEmpty) {
      return todo.title;
    }
    return '${todo.title} · ${todo.linkedModules.map((module) => module.label).join('/')}联动';
  }

  void _addFinanceRecord(FinanceRecord record) {
    _updateState(() => _financeState.records.insert(0, record));
    _syncLinkedSummaryToWidget();
  }

  void _editFinanceRecord(FinanceRecord oldRecord, FinanceRecord newRecord) {
    final index = _financeState.records.indexOf(oldRecord);
    if (index == -1) {
      return;
    }
    _updateState(() => _financeState.records[index] = newRecord);
    _syncLinkedSummaryToWidget();
  }

  void _updateAiFinanceConfig({
    required String endpoint,
    required String model,
    required String apiKey,
    AiFinanceParseStrategy? parseStrategy,
    String? customPrompt,
  }) {
    _updateState(() {
      _financeState.updateAiConfig(
        endpoint: endpoint,
        model: model,
        apiKey: apiKey,
        parseStrategy: parseStrategy,
        customPrompt: customPrompt,
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _pushLifeEvent(LifeEvent event) {
    // 所有模块产生的关键操作都汇入同一条时间线，计划复盘和模块中心共用。
    _planState.pushEvent(event);
  }
}
