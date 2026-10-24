// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

/// 首页各模块的状态变更方法：饮食、锻炼、待办、财务和事件流。
extension _LifeHomeMutations on _LifeHomePageState {
  // 追加饮食记录，汇总热量，并推送一条生活事件。
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

  // 更新某个训练动作的完成组数；跨天时先清空前一天的进度。
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

  // 开始一次训练会话。
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

  // 更新训练会话中的动作进度。
  void _updateWorkoutSession(ActiveWorkoutSession session) {
    _updateState(() {
      _workoutState.activeSession = session;
      _workoutState.progressDate = DateUtils.dateOnly(session.startedAt);
    });
    _syncLinkedSummaryToWidget();
  }

  // 结束训练会话并写入历史记录。
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

  // 更新训练计划（动作、目标组数等）。
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

  // 勾选/取消待办；完成重复待办时生成下一次实例。
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

  // 用新的待办对象替换旧对象。
  void _updateTodo(TodoItem todo) {
    final index = _planState.todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) {
      return;
    }
    _updateState(() => _planState.todos[index] = todo);
    _syncLinkedSummaryToWidget();
  }

  // 把待办推迟到下一个工作日。
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

  // 格式化待办的简短日期，用于事件描述。
  String _shortTodoDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  // 归档待办。
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

  // 删除待办及其重复系列。
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

  // 新增待办，并在有日期时推入事件流。
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

  // 清理所有已完成待办。
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

  // 待办完成且关联模块时，推送一条联动事件。
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

  // 生成待办完成事件的详情文案。
  String _todoCompletionDetail(TodoItem todo) {
    if (todo.linkedModules.isEmpty) {
      return todo.title;
    }
    return '${todo.title} · ${todo.linkedModules.map((module) => module.label).join('/')}联动';
  }

  // 新增一条财务记录。
  void _addFinanceRecord(FinanceRecord record) {
    _updateState(() => _financeState.records.insert(0, record));
    _syncLinkedSummaryToWidget();
  }

  // 用编辑后的记录替换旧记录。
  void _editFinanceRecord(FinanceRecord oldRecord, FinanceRecord newRecord) {
    final index = _financeState.records.indexOf(oldRecord);
    if (index == -1) {
      return;
    }
    _updateState(() => _financeState.records[index] = newRecord);
    _syncLinkedSummaryToWidget();
  }

  // 更新 AI 记账的接口地址、模型、密钥和解析策略。
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

  // 向首页事件流插入一条事件，最多保留 8 条。
  void _pushLifeEvent(LifeEvent event) {
    // 所有模块产生的关键操作都汇入同一条时间线，计划复盘和模块中心共用。
    _planState.pushEvent(event);
  }
}
