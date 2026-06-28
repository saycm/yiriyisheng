part of '../main.dart';

extension _LifeHomeMutations on _LifeHomePageState {
  void _recordFoodCalories(int calories) {
    // 饮食模块的记录会进入应用级共享状态，健康模块据此展示今日摄入。
    _updateState(() {
      _recordedFoodCalories += calories;
      _pushLifeEvent(
        LifeEvent(
          title: '记录饮食',
          detail: '$calories kcal 已同步到健康和计划',
          icon: Icons.restaurant_rounded,
          color: AppColors.success,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _updateWorkoutGroups(String actionName, int finishedGroups) {
    // 锻炼模块完成组数保存在父级，切换到健康/饮食/计划后仍能联动展示。
    final previousGroups = _workoutGroupsByAction[actionName] ?? 0;
    _updateState(() {
      _workoutGroupsByAction[actionName] = finishedGroups;
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

  void _toggleTodo(TodoItem todo) {
    final wasDone = todo.done;
    var shouldShowLinkedActions = false;
    _updateState(() {
      todo.done = !todo.done;
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
        shouldShowLinkedActions = todo.linkedModules.isNotEmpty;
      }
    });
    _syncLinkedSummaryToWidget();
    if (shouldShowLinkedActions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openTodoLinkedActionSheet(todo);
        }
      });
    }
  }

  void _updateTodo(TodoItem todo) {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) {
      return;
    }
    _updateState(() => _todos[index] = todo);
    _syncLinkedSummaryToWidget();
  }

  void _postponeTodo(TodoItem todo) {
    _updateState(() {
      todo.postponeToTomorrow();
      _pushLifeEvent(
        LifeEvent(
          title: '延后待办',
          detail: '${todo.title} · 明天处理',
          icon: Icons.event_repeat_rounded,
          color: todo.color,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
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
      _todos.removeWhere((item) => item.id == todo.id);
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
      _todos.add(todo);
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
    final count = _todos.where((todo) => todo.done).length;
    _updateState(() {
      _todos.removeWhere((todo) => todo.done);
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
          detail: _linkedTodoPrompt(todo, module),
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
    _updateState(() => _financeRecords.insert(0, record));
    _syncLinkedSummaryToWidget();
  }

  void _editFinanceRecord(FinanceRecord oldRecord, FinanceRecord newRecord) {
    final index = _financeRecords.indexOf(oldRecord);
    if (index == -1) {
      return;
    }
    _updateState(() => _financeRecords[index] = newRecord);
    _syncLinkedSummaryToWidget();
  }

  void _updateAiFinanceConfig({
    required String endpoint,
    required String model,
    required String apiKey,
  }) {
    _updateState(() {
      _aiFinanceEndpoint =
          endpoint.trim().isEmpty ? _defaultGlmChatEndpoint : endpoint.trim();
      _aiFinanceModel =
          model.trim().isEmpty ? _defaultGlmTextModel : model.trim();
      _aiFinanceApiKey = apiKey.trim();
    });
    _syncLinkedSummaryToWidget();
  }

  void _pushLifeEvent(LifeEvent event) {
    // 所有模块产生的关键操作都汇入同一条时间线，计划复盘和模块中心共用。
    _events.insert(0, event);
    if (_events.length > 8) {
      _events.removeRange(8, _events.length);
    }
  }
}
