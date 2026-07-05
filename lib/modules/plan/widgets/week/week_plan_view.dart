// 中文注释：计划周视图入口，负责周日期计算、任务分组和子面板组装。

part of '../../plan.dart';

const int _maxScheduleToSelectedDay = 6;

class _WeekPlanView extends StatelessWidget {
  const _WeekPlanView({
    required this.selectedDate,
    required this.todos,
    required this.onSelectDate,
    required this.onToggle,
    required this.onUpdate,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final DateTime selectedDate;
  final List<TodoItem> todos;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onUpdate;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final normalizedSelectedDate = DateUtils.dateOnly(selectedDate);
    final weekStart = normalizedSelectedDate.subtract(
      Duration(days: normalizedSelectedDate.weekday % 7),
    );
    final days = List.generate(
      7,
      (index) => DateUtils.dateOnly(weekStart.add(Duration(days: index))),
    );
    final weekTodos = _weekTodos(days);
    final unscheduledTodos = _unscheduledTodos(today, days);
    // 周视图把任务分成“本周已有日期”和“未安排/过期待整理”，后续面板都基于这两组数据。
    final selectedTodos = todos
        .where((todo) => todo.isActive && todo.isDueOn(normalizedSelectedDate))
        .toList()
      ..sort(_sortPlanTodos);
    final overdueCount = todos.where((todo) {
      final dueDate = todo.dueDate;
      return todo.isActive && dueDate != null && dueDate.isBefore(today);
    }).length;

    return ListView(
      key: const ValueKey('week_plan_list'),
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        88,
      ),
      children: [
        _WeekCommandCenter(
          weekTodos: weekTodos.length,
          completedCount: _completedInWeek(days),
          unscheduledCount: unscheduledTodos.length,
          riskCount: overdueCount,
          insight: _weekInsight(
            weekTodos: weekTodos,
            unscheduledTodos: unscheduledTodos,
            days: days,
            today: today,
          ),
          onAutoSchedule: unscheduledTodos.isEmpty
              ? null
              : () => _autoScheduleWeek(context, today, days, unscheduledTodos),
          onBalanceWeek: () => _balanceWeek(context, today, days),
          onMoveLowPriorityNextWeek: () =>
              _moveLowPriorityToNextWeek(context, days),
          onCleanOverdue: overdueCount == 0
              ? null
              : () => _cleanOverdueTodos(context, today, days),
        ),
        const SizedBox(height: 12),
        _WeekDayBoard(
          days: days,
          selectedDate: normalizedSelectedDate,
          todos: todos,
          onSelectDate: onSelectDate,
        ),
        const SizedBox(height: 12),
        _WeekUnscheduledSection(
          todos: unscheduledTodos,
          onScheduleToday: (todo) => _scheduleTodo(context, todo, today),
          onScheduleTomorrow: (todo) => _scheduleTodo(
            context,
            todo,
            today.add(const Duration(days: 1)),
          ),
          onScheduleWeek: (todo) => _scheduleTodo(
            context,
            todo,
            _bestScheduleDay(days, todos, today),
          ),
        ),
        const SizedBox(height: 12),
        _WeekSelectedTasksPanel(
          selectedDate: normalizedSelectedDate,
          todos: selectedTodos,
          hasBacklog: unscheduledTodos.isNotEmpty,
          onScheduleBacklogToSelectedDay: unscheduledTodos.isEmpty
              ? null
              : () => _scheduleBacklogToSelectedDay(
                    context,
                    unscheduledTodos,
                    normalizedSelectedDate,
                  ),
          onScheduleAllBacklogToSelectedDay: unscheduledTodos.isEmpty
              ? null
              : () => _scheduleAllBacklogToSelectedDay(
                    context,
                    unscheduledTodos,
                    normalizedSelectedDate,
                  ),
          onToggle: onToggle,
          onPostpone: onPostpone,
          onArchive: onArchive,
          onDelete: onDelete,
        ),
      ],
    );
  }

  List<TodoItem> _weekTodos(List<DateTime> days) {
    return todos.where((todo) {
      return todo.isActive && days.any((day) => todo.isDueOn(day));
    }).toList()
      ..sort(_sortPlanTodos);
  }

  List<TodoItem> _unscheduledTodos(DateTime today, List<DateTime> days) {
    // 未安排区不仅包含无日期任务，也包含过期任务和延期到本周外的任务。
    return todos.where((todo) {
      if (!todo.isActive) {
        return false;
      }
      final dueDate = todo.dueDate;
      if (dueDate == null) {
        return true;
      }
      final belongsToThisWeek = days.any((day) => todo.isDueOn(day));
      if (dueDate.isBefore(today)) {
        return true;
      }
      return todo.status == TodoStatus.postponed && !belongsToThisWeek;
    }).toList()
      ..sort(_sortPlanTodos);
  }

  int _completedInWeek(List<DateTime> days) {
    return todos.where((todo) {
      return todo.done && days.any((day) => todo.isDueOn(day));
    }).length;
  }

  String _weekInsight({
    required List<TodoItem> weekTodos,
    required List<TodoItem> unscheduledTodos,
    required List<DateTime> days,
    required DateTime today,
  }) {
    if (unscheduledTodos.isNotEmpty) {
      return '本周节奏需要整理：有 ${unscheduledTodos.length} 项待安排，可以先放进空档日。';
    }
    if (weekTodos.isEmpty) {
      return '本周节奏还很空，可以从待办箱挑 1-2 项先安排。';
    }
    final overloadedDays = days.where((day) {
      return _dayTodos(day, todos).length >= 5 && !day.isBefore(today);
    }).length;
    if (overloadedDays > 0) {
      return '本周节奏偏满：有 $overloadedDays 天负载较高，建议把低优先级任务往后挪。';
    }
    return '本周节奏稳定：任务分布比较均衡，按当前安排推进就行。';
  }
}
