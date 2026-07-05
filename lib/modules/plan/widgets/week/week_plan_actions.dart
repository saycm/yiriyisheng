// 中文注释：计划周视图动作，负责自动排周、均衡、清理和安排任务。

part of '../../plan.dart';

extension _WeekPlanActions on _WeekPlanView {
  void _autoScheduleWeek(
    BuildContext context,
    DateTime today,
    List<DateTime> days,
    List<TodoItem> unscheduledTodos,
  ) {
    // 自动安排会边更新外部状态，边维护 plannedTodos，保证下一项能看到最新负载。
    final plannedTodos = List<TodoItem>.of(todos);
    final originalTodos = <TodoItem>[];
    var scheduledCount = 0;
    for (final todo in unscheduledTodos) {
      final targetDay = _bestScheduleDay(days, plannedTodos, today);
      final updated = _scheduledCopy(todo, targetDay);
      originalTodos.add(todo.copyWith());
      onUpdate(updated);
      scheduledCount++;

      final index = plannedTodos.indexWhere((item) => item.id == todo.id);
      if (index == -1) {
        plannedTodos.add(updated);
      } else {
        plannedTodos[index] = updated;
      }
    }
    _showUndoableScheduleSnackBar(
      context,
      message: '已安排 $scheduledCount 项到本周',
      originalTodos: originalTodos,
    );
  }

  void _balanceWeek(BuildContext context, DateTime today, List<DateTime> days) {
    final unscheduledTodos = _unscheduledTodos(today, days);
    if (unscheduledTodos.isNotEmpty) {
      _autoScheduleWeek(context, today, days, unscheduledTodos);
      return;
    }
    final movableTodos = _weekTodos(days)
        .where((todo) => todo.priority == TodoPriority.canDelay)
        .toList()
      ..sort(_sortPlanTodos);
    if (movableTodos.isEmpty) {
      _showPlainWeekSnackBar(context, '本周已经比较均衡，没有需要移动的低优先级任务');
      return;
    }
    final plannedTodos = List<TodoItem>.of(todos);
    final originalTodos = <TodoItem>[];
    var movedCount = 0;
    for (final todo in movableTodos.take(3)) {
      final targetDay = _bestScheduleDay(days, plannedTodos, today);
      if (todo.isDueOn(targetDay)) {
        continue;
      }
      final updated = _scheduledCopy(todo, targetDay);
      originalTodos.add(todo.copyWith());
      onUpdate(updated);
      movedCount++;
      final index = plannedTodos.indexWhere((item) => item.id == todo.id);
      if (index != -1) {
        plannedTodos[index] = updated;
      }
    }
    if (movedCount == 0) {
      _showPlainWeekSnackBar(context, '本周已经比较均衡');
      return;
    }
    _showUndoableScheduleSnackBar(
      context,
      message: '已平衡本周 $movedCount 项任务',
      originalTodos: originalTodos,
    );
  }

  void _moveLowPriorityToNextWeek(BuildContext context, List<DateTime> days) {
    final movableTodos = _weekTodos(days)
        .where((todo) => todo.priority == TodoPriority.canDelay)
        .toList()
      ..sort(_sortPlanTodos);
    if (movableTodos.isEmpty) {
      _showPlainWeekSnackBar(context, '本周没有低优先级任务需要移动');
      return;
    }
    final originalTodos = <TodoItem>[];
    for (final todo in movableTodos) {
      final dueDate = todo.dueDate;
      if (dueDate == null) {
        continue;
      }
      originalTodos.add(todo.copyWith());
      onUpdate(
        todo.copyWith(
          dueDate: DateUtils.dateOnly(dueDate.add(const Duration(days: 7))),
          status: TodoStatus.postponed,
          postponedCount: todo.postponedCount + 1,
        ),
      );
    }
    if (originalTodos.isEmpty) {
      _showPlainWeekSnackBar(context, '本周没有低优先级任务需要移动');
      return;
    }
    _showUndoableScheduleSnackBar(
      context,
      message: '已把 ${originalTodos.length} 项低优先级任务移到下周',
      originalTodos: originalTodos,
    );
  }

  void _cleanOverdueTodos(
    BuildContext context,
    DateTime today,
    List<DateTime> days,
  ) {
    final overdueTodos = todos.where((todo) {
      final dueDate = todo.dueDate;
      return todo.isActive && dueDate != null && dueDate.isBefore(today);
    }).toList()
      ..sort(_sortPlanTodos);
    if (overdueTodos.isEmpty) {
      _showPlainWeekSnackBar(context, '没有逾期任务需要清理');
      return;
    }
    final plannedTodos = List<TodoItem>.of(todos);
    final originalTodos = <TodoItem>[];
    for (final todo in overdueTodos) {
      final targetDay = _bestScheduleDay(days, plannedTodos, today);
      final updated = _scheduledCopy(todo, targetDay);
      originalTodos.add(todo.copyWith());
      onUpdate(updated);
      final index = plannedTodos.indexWhere((item) => item.id == todo.id);
      if (index != -1) {
        plannedTodos[index] = updated;
      }
    }
    _showUndoableScheduleSnackBar(
      context,
      message: '已重新安排 ${originalTodos.length} 项逾期任务',
      originalTodos: originalTodos,
    );
  }

  void _scheduleTodo(BuildContext context, TodoItem todo, DateTime targetDay) {
    onUpdate(_scheduledCopy(todo, targetDay));
    _showUndoableScheduleSnackBar(
      context,
      message: '已安排到 ${_formatPlanDate(targetDay)}',
      originalTodos: [todo.copyWith()],
    );
  }

  void _scheduleBacklogToSelectedDay(
    BuildContext context,
    List<TodoItem> backlogTodos,
    DateTime selectedDate,
  ) {
    if (backlogTodos.isEmpty) {
      return;
    }
    final todo = backlogTodos.first;
    onUpdate(_scheduledCopy(todo, selectedDate));
    _showUndoableScheduleSnackBar(
      context,
      message: '已安排 1 项到选中日期',
      originalTodos: [todo.copyWith()],
    );
  }

  void _scheduleAllBacklogToSelectedDay(
    BuildContext context,
    List<TodoItem> backlogTodos,
    DateTime selectedDate,
  ) {
    if (backlogTodos.isEmpty) {
      return;
    }
    final scheduledTodos =
        backlogTodos.take(_maxScheduleToSelectedDay).toList(growable: false);
    for (final todo in scheduledTodos) {
      onUpdate(_scheduledCopy(todo, selectedDate));
    }
    final remainingCount = backlogTodos.length - scheduledTodos.length;
    final message = remainingCount > 0
        ? '已安排 ${scheduledTodos.length} 项到选中日期，还有 $remainingCount 项留在待安排'
        : '已安排 ${scheduledTodos.length} 项到选中日期';
    _showUndoableScheduleSnackBar(
      context,
      message: message,
      originalTodos: scheduledTodos.map((todo) => todo.copyWith()).toList(),
    );
  }
}

TodoItem _scheduledCopy(TodoItem todo, DateTime targetDay) {
  return todo.copyWith(
    dueDate: DateUtils.dateOnly(targetDay),
    status: todo.status == TodoStatus.postponed
        ? TodoStatus.notStarted
        : todo.status,
  );
}

DateTime _bestScheduleDay(
  List<DateTime> days,
  List<TodoItem> plannedTodos,
  DateTime today,
) {
  final candidates = days.where((day) => !day.isBefore(today)).toList();
  final usableDays = candidates.isEmpty ? days : candidates;
  usableDays.sort((a, b) {
    final aCount = _dayTodos(a, plannedTodos).length;
    final bCount = _dayTodos(b, plannedTodos).length;
    final countCompare = aCount.compareTo(bCount);
    if (countCompare != 0) {
      return countCompare;
    }
    return a.compareTo(b);
  });
  return usableDays.first;
}
