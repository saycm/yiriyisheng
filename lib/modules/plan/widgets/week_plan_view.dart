// 中文注释：计划模块页面组件，负责今日总览、待办箱、周计划和统计视图。

part of '../plan.dart';

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
        moduleSwitchBarReservedHeight + 88,
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

  void _autoScheduleWeek(
    BuildContext context,
    DateTime today,
    List<DateTime> days,
    List<TodoItem> unscheduledTodos,
  ) {
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

  void _showUndoableScheduleSnackBar(
    BuildContext context, {
    required String message,
    required List<TodoItem> originalTodos,
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            for (final todo in originalTodos) {
              onUpdate(todo);
            }
          },
        ),
      ),
    );
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
}

class _WeekCommandCenter extends StatelessWidget {
  const _WeekCommandCenter({
    required this.weekTodos,
    required this.completedCount,
    required this.unscheduledCount,
    required this.riskCount,
    required this.insight,
    required this.onAutoSchedule,
  });

  final int weekTodos;
  final int completedCount;
  final int unscheduledCount;
  final int riskCount;
  final String insight;
  final VoidCallback? onAutoSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week_plan_command_center'),
      padding: const EdgeInsets.all(14),
      decoration: _weekCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '一周安排工作台',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WeekMetricTile(
                  label: '本周',
                  value: '$weekTodos',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekMetricTile(
                  label: '完成',
                  value: '$completedCount',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekMetricTile(
                  label: '待安排',
                  value: '$unscheduledCount',
                  color: const Color(0xFFFF9559),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekMetricTile(
                  label: '风险',
                  value: '$riskCount',
                  color: AppColors.financeRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('week_plan_auto_schedule'),
              onPressed: onAutoSchedule,
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: const Text('一键排周'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primarySoft,
                disabledForegroundColor: AppColors.muted,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekMetricTile extends StatelessWidget {
  const _WeekMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayBoard extends StatelessWidget {
  const _WeekDayBoard({
    required this.days,
    required this.selectedDate,
    required this.todos,
    required this.onSelectDate,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final List<TodoItem> todos;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week_plan_day_board'),
      padding: const EdgeInsets.all(14),
      decoration: _weekCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModuleSectionTitle(
            icon: Icons.view_week_rounded,
            title: '7 天任务板',
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.85,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              return _WeekDayCard(
                date: day,
                todos: _dayTodos(day, todos),
                selected: DateUtils.isSameDay(day, selectedDate),
                onTap: () => onSelectDate(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  const _WeekDayCard({
    required this.date,
    required this.todos,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final List<TodoItem> todos;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final load = _loadInfo(todos.length);
    final previewTodos = todos.take(2).toList();

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _weekdayLabel(date),
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '负载 ${load.label} · ${todos.length} 项',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: 0.86)
                    : load.color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            if (previewTodos.isEmpty)
              Text(
                '空档日',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.78)
                      : AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              for (final todo in previewTodos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '· ${todo.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.90)
                          : AppColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _WeekUnscheduledSection extends StatelessWidget {
  const _WeekUnscheduledSection({
    required this.todos,
    required this.onScheduleToday,
    required this.onScheduleTomorrow,
    required this.onScheduleWeek,
  });

  final List<TodoItem> todos;
  final ValueChanged<TodoItem> onScheduleToday;
  final ValueChanged<TodoItem> onScheduleTomorrow;
  final ValueChanged<TodoItem> onScheduleWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week_plan_unscheduled_section'),
      padding: const EdgeInsets.all(14),
      decoration: _weekCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: ModuleSectionTitle(
                  icon: Icons.move_to_inbox_rounded,
                  title: '待安排任务',
                ),
              ),
              Text(
                '待安排 ${todos.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todos.isEmpty)
            const _WeekEmptyHint(
              title: '本周没有待安排任务',
              subtitle: '无日期、过期或需要重新整理的任务会出现在这里。',
            )
          else
            for (final todo in todos)
              _UnscheduledTodoTile(
                todo: todo,
                onScheduleToday: () => onScheduleToday(todo),
                onScheduleTomorrow: () => onScheduleTomorrow(todo),
                onScheduleWeek: () => onScheduleWeek(todo),
              ),
        ],
      ),
    );
  }
}

class _UnscheduledTodoTile extends StatelessWidget {
  const _UnscheduledTodoTile({
    required this.todo,
    required this.onScheduleToday,
    required this.onScheduleTomorrow,
    required this.onScheduleWeek,
  });

  final TodoItem todo;
  final VoidCallback onScheduleToday;
  final VoidCallback onScheduleTomorrow;
  final VoidCallback onScheduleWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: todo.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  todo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _PriorityChip(priority: todo.priority),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScheduleActionChip(label: '排今天', onTap: onScheduleToday),
              _ScheduleActionChip(label: '排明天', onTap: onScheduleTomorrow),
              _ScheduleActionChip(label: '排本周', onTap: onScheduleWeek),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleActionChip extends StatelessWidget {
  const _ScheduleActionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primarySoft,
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TodoPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: priority.color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WeekSelectedTasksPanel extends StatelessWidget {
  const _WeekSelectedTasksPanel({
    required this.selectedDate,
    required this.todos,
    required this.hasBacklog,
    required this.onScheduleBacklogToSelectedDay,
    required this.onScheduleAllBacklogToSelectedDay,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final DateTime selectedDate;
  final List<TodoItem> todos;
  final bool hasBacklog;
  final VoidCallback? onScheduleBacklogToSelectedDay;
  final VoidCallback? onScheduleAllBacklogToSelectedDay;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final load = _loadInfo(todos.length);
    final overloaded = todos.length >= 5;

    return Container(
      key: const ValueKey('week_plan_selected_tasks_panel'),
      padding: const EdgeInsets.all(14),
      decoration: _weekCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatPlanDate(selectedDate)}  ${todos.length} 项',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${_weekdayLabel(selectedDate)} · ${load.label}',
                style: TextStyle(
                  color: load.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (overloaded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.financeRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.financeRed.withValues(alpha: 0.18),
                ),
              ),
              child: const Text(
                '这天任务偏满，建议只排高优先级事项。',
                style: TextStyle(
                  color: AppColors.financeRed,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (hasBacklog) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('week_plan_schedule_selected_day'),
                    onPressed: onScheduleBacklogToSelectedDay,
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('排一项到这天'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey(
                      'week_plan_schedule_all_selected_day',
                    ),
                    onPressed: onScheduleAllBacklogToSelectedDay,
                    icon:
                        const Icon(Icons.playlist_add_check_rounded, size: 18),
                    label: const Text('排全部到这天'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (todos.isEmpty)
            _WeekEmptyHint(
              title: '这天还空着',
              subtitle:
                  hasBacklog ? '可以从上方待安排任务里排入这一天。' : '这天没有任务，适合留作缓冲或新增一个轻量安排。',
            )
          else
            ...todos.map(
              (todo) => _TodoCard(
                todo: todo,
                onTap: () => onToggle(todo),
                onPostpone: () => onPostpone(todo),
                onArchive: () => onArchive(todo),
                onDelete: () => onDelete(todo),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekEmptyHint extends StatelessWidget {
  const _WeekEmptyHint({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

({String label, Color color}) _loadInfo(int count) {
  if (count == 0) {
    return (label: '空档', color: AppColors.success);
  }
  if (count <= 2) {
    return (label: '轻松', color: AppColors.primary);
  }
  if (count <= 4) {
    return (label: '合理', color: const Color(0xFFFF9559));
  }
  return (label: '偏满', color: AppColors.financeRed);
}

List<TodoItem> _dayTodos(DateTime day, List<TodoItem> todos) {
  return todos.where((todo) => todo.isActive && todo.isDueOn(day)).toList()
    ..sort(_sortPlanTodos);
}

BoxDecoration _weekCardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.line),
  );
}
