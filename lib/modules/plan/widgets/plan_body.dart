part of '../../../main.dart';

class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.selectedTab,
    required this.selectedDate,
    required this.activeFilter,
    required this.todos,
    required this.events,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todayExpense,
    required this.healthStatusText,
    required this.onSelectDate,
    required this.onToggleTodo,
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
  final double todayExpense;
  final String healthStatusText;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<TodoItem> onToggleTodo;
  final ValueChanged<TodoItem> onPostponeTodo;
  final ValueChanged<TodoItem> onArchiveTodo;
  final ValueChanged<TodoItem> onDeleteTodo;
  final ValueChanged<String> onQuickCapture;
  final ValueChanged<TodoItem> onAddTodo;
  final VoidCallback onClearCompletedTodos;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final todayTodos = todos.where((todo) {
      final dueDate = todo.dueDate;
      return todo.isActive && dueDate != null && !dueDate.isAfter(today);
    }).toList()
      ..sort(_sortPlanTodos);
    final filteredTodayTodos = activeFilter == '全部'
        ? todayTodos
        : todayTodos.where((todo) => todo.category == activeFilter).toList();

    if (selectedTab == 1) {
      return _InboxView(
        inboxTodos: todos.where((todo) => todo.isInbox).toList()
          ..sort(_sortPlanTodos),
        completedTodos: todos.where((todo) => todo.done).toList()
          ..sort(_sortPlanTodos),
        archivedTodos: todos
            .where((todo) => todo.status == TodoStatus.archived)
            .toList()
          ..sort(_sortPlanTodos),
        onToggle: onToggleTodo,
        onPostpone: onPostponeTodo,
        onArchive: onArchiveTodo,
        onDelete: onDeleteTodo,
        onQuickCapture: onQuickCapture,
      );
    }
    if (selectedTab == 2) {
      return _WeekPlanView(
        selectedDate: selectedDate,
        todos: todos,
        onSelectDate: onSelectDate,
        onToggle: onToggleTodo,
        onPostpone: onPostponeTodo,
        onArchive: onArchiveTodo,
        onDelete: onDeleteTodo,
      );
    }
    if (selectedTab == 3) {
      return _PlanStatsView(
        todos: todos,
        events: events,
        foodCalories: foodCalories,
        workoutGroups: workoutGroups,
      );
    }
    return _TodoList(
      title: '今日计划',
      emptyTitle: '今天没有待处理事项',
      emptySubtitle: '可以把无日期任务从待办箱安排到今天，或新增一个今日任务。',
      todos: filteredTodayTodos,
      activeFilter: activeFilter,
      header: _TodayOverviewCard(
        pendingTodos: todayTodos.length,
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

int _sortPlanTodos(TodoItem a, TodoItem b) {
  final priority = a.priority.index.compareTo(b.priority.index);
  if (priority != 0) {
    return priority;
  }
  final aDate = a.dueDate ?? DateTime(9999);
  final bDate = b.dueDate ?? DateTime(9999);
  return aDate.compareTo(bDate);
}
