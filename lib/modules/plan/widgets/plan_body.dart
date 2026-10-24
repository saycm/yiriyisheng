// 中文注释：计划模块页面组件，负责今日总览、待办箱、周计划和统计视图。

part of '../plan.dart';

/// 计划页主体：根据顶部页签切换今日执行、待办箱、周计划和统计四个视图。
class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.selectedTab,
    required this.selectedDate,
    required this.activeFilter,
    required this.todos,
    required this.events,
    required this.foodCalories,
    required this.workoutGroups,
    required this.weeklyFoodCalories,
    required this.weeklyWorkoutGroups,
    required this.todayExpense,
    required this.healthStatusText,
    required this.onSelectDate,
    required this.onToggleTodo,
    required this.onUpdateTodo,
    required this.onPostponeTodo,
    required this.onArchiveTodo,
    required this.onDeleteTodo,
    required this.onQuickCapture,
    required this.onAddTodo,
    required this.onClearCompletedTodos,
  });

  final int selectedTab;
  final DateTime selectedDate;
  final String activeFilter;
  final List<TodoItem> todos;
  final List<LifeEvent> events;
  final int foodCalories;
  final int workoutGroups;
  final int weeklyFoodCalories;
  final int weeklyWorkoutGroups;
  final double todayExpense;
  final String healthStatusText;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<TodoItem> onToggleTodo;
  final ValueChanged<TodoItem> onUpdateTodo;
  final ValueChanged<TodoItem> onPostponeTodo;
  final ValueChanged<TodoItem> onArchiveTodo;
  final ValueChanged<TodoItem> onDeleteTodo;
  final ValueChanged<String> onQuickCapture;
  final ValueChanged<TodoItem> onAddTodo;
  final VoidCallback onClearCompletedTodos;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    // 今日视图只展示“未完成且到期日不晚于今天”的待办。
    final actionableTodayTodos = todos.where((todo) {
      final dueDate = todo.dueDate;
      return todo.isActive && dueDate != null && !dueDate.isAfter(today);
    }).toList()
      ..sort(_sortPlanTodos);
    // 再按分类筛选；分类为“全部”时保留所有今日待办。
    final filteredTodayTodos = activeFilter == '全部'
        ? actionableTodayTodos
        : actionableTodayTodos
            .where((todo) => todo.category == activeFilter)
            .toList();

    // 页签 1：待办箱（收集箱、已完成、已归档）。
    if (selectedTab == 1) {
      return _InboxView(
        inboxTodos: todos.where((todo) => todo.isInbox).toList()
          ..sort(_sortPlanTodos),
        completedTodos: todos.where((todo) => todo.done).toList()
          ..sort(_sortPlanTodos),
        archivedTodos:
            todos.where((todo) => todo.status == TodoStatus.archived).toList()
              ..sort(_sortPlanTodos),
        onToggle: onToggleTodo,
        onPostpone: onPostponeTodo,
        onArchive: onArchiveTodo,
        onDelete: onDeleteTodo,
        onQuickCapture: onQuickCapture,
        onUpdate: onUpdateTodo,
      );
    }
    // 页签 2：周计划（按天看板）。
    if (selectedTab == 2) {
      return _WeekPlanView(
        selectedDate: selectedDate,
        todos: todos,
        onSelectDate: onSelectDate,
        onToggle: onToggleTodo,
        onUpdate: onUpdateTodo,
        onPostpone: onPostponeTodo,
        onArchive: onArchiveTodo,
        onDelete: onDeleteTodo,
      );
    }
    // 页签 3：计划统计（完成率、饮食/锻炼汇总）。
    if (selectedTab == 3) {
      return _PlanStatsView(
        todos: todos,
        events: events,
        foodCalories: weeklyFoodCalories,
        workoutGroups: weeklyWorkoutGroups,
      );
    }
    // 默认页签 0：今日执行列表，顶部带今日总览卡片。
    return _TodayExecutionView(
      title: '今日执行',
      emptyTitle: '今天没有待处理事项',
      emptySubtitle: '可以把无日期任务从待办箱安排到今天，或新增一个今日任务。',
      todos: filteredTodayTodos,
      activeFilter: activeFilter,
      header: _TodayOverviewCard(
        pendingTodos: actionableTodayTodos.length,
        todayExpense: todayExpense,
        foodCalories: foodCalories,
        workoutGroups: workoutGroups,
        healthStatusText: healthStatusText,
      ),
      onToggle: onToggleTodo,
      onPostpone: onPostponeTodo,
      onArchive: onArchiveTodo,
      onDelete: onDeleteTodo,
    );
  }
}

// 计划列表排序：优先级高的在前，同优先级按到期日升序，无日期排最后。
int _sortPlanTodos(TodoItem a, TodoItem b) {
  final priority = a.priority.index.compareTo(b.priority.index);
  if (priority != 0) {
    return priority;
  }
  final aDate = a.dueDate ?? DateTime(9999);
  final bDate = b.dueDate ?? DateTime(9999);
  return aDate.compareTo(bDate);
}
