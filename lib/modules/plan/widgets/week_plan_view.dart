part of '../../../main.dart';

class _WeekPlanView extends StatelessWidget {
  const _WeekPlanView({
    required this.selectedDate,
    required this.todos,
    required this.onSelectDate,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final DateTime selectedDate;
  final List<TodoItem> todos;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    final days = List.generate(
      7,
      (index) => DateUtils.dateOnly(weekStart.add(Duration(days: index))),
    );
    final weekTodos = todos.where((todo) {
      return todo.isActive && days.any((day) => todo.isDueOn(day));
    }).toList();
    final selectedTodos = todos
        .where((todo) => todo.isActive && todo.isDueOn(selectedDate))
        .toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    final mustDoCount =
        weekTodos.where((todo) => todo.priority == TodoPriority.mustDo).length;
    final postponedCount = weekTodos
        .where((todo) =>
            todo.status == TodoStatus.postponed || todo.postponedCount > 0)
        .length;
    final busiestDay = _busiestDay(days, todos);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        _moduleSwitchBarReservedHeight + 88,
      ),
      children: [
        _WeekOverviewCard(
          weekStart: weekStart,
          weekTodos: weekTodos.length,
          mustDoCount: mustDoCount,
          postponedCount: postponedCount,
          busiestDay: busiestDay,
        ),
        const SizedBox(height: 12),
        _WeekDateStrip(
          days: days,
          selectedDate: selectedDate,
          todos: todos,
          onSelectDate: onSelectDate,
        ),
        const SizedBox(height: 12),
        _WeekSelectedTasksPanel(
          selectedDate: selectedDate,
          todos: selectedTodos,
          onToggle: onToggle,
          onPostpone: onPostpone,
          onArchive: onArchive,
          onDelete: onDelete,
        ),
      ],
    );
  }

  DateTime _busiestDay(List<DateTime> days, List<TodoItem> todos) {
    var busiestDay = days.first;
    var busiestCount = -1;
    for (final day in days) {
      final count =
          todos.where((todo) => todo.isActive && todo.isDueOn(day)).length;
      if (count > busiestCount) {
        busiestDay = day;
        busiestCount = count;
      }
    }
    return busiestDay;
  }
}

class _WeekOverviewCard extends StatelessWidget {
  const _WeekOverviewCard({
    required this.weekStart,
    required this.weekTodos,
    required this.mustDoCount,
    required this.postponedCount,
    required this.busiestDay,
  });

  final DateTime weekStart;
  final int weekTodos;
  final int mustDoCount;
  final int postponedCount;
  final DateTime busiestDay;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Container(
      key: const ValueKey('week_plan_overview_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.view_week_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本周概览',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day} · 最忙 ${_weekdayLabel(busiestDay)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _WeekMetricTile(
                  label: '本周任务',
                  value: '$weekTodos',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekMetricTile(
                  label: '必做',
                  value: '$mustDoCount',
                  color: AppColors.financeRed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekMetricTile(
                  label: '延后',
                  value: '$postponedCount',
                  color: const Color(0xFFFF9559),
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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

class _WeekDateStrip extends StatelessWidget {
  const _WeekDateStrip({
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (final day in days) ...[
            Expanded(
              child: _WeekDayPill(
                date: day,
                selected: DateUtils.isSameDay(day, selectedDate),
                todos: todos
                    .where((todo) => todo.isActive && todo.isDueOn(day))
                    .toList(),
                onTap: () => onSelectDate(day),
              ),
            ),
            if (day != days.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _WeekDayPill extends StatelessWidget {
  const _WeekDayPill({
    required this.date,
    required this.selected,
    required this.todos,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final List<TodoItem> todos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mustDoCount =
        todos.where((todo) => todo.priority == TodoPriority.mustDo).length;
    final color = mustDoCount > 0 ? AppColors.financeRed : AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _weekdayLabel(date),
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 22,
              height: 18,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${todos.length}',
                  style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekSelectedTasksPanel extends StatelessWidget {
  const _WeekSelectedTasksPanel({
    required this.selectedDate,
    required this.todos,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final DateTime selectedDate;
  final List<TodoItem> todos;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week_plan_selected_tasks_panel'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
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
                _weekdayLabel(selectedDate),
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
            const _EmptyCard(
              title: '这天还没有安排',
              subtitle: '周计划会把每天的任务密度摊开，避免都挤到今天。',
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
