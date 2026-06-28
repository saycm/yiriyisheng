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
    final selectedTodos = todos
        .where((todo) => todo.isActive && todo.isDueOn(selectedDate))
        .toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        _moduleSwitchBarReservedHeight + 88,
      ),
      children: [
        const Text(
          '周计划',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 18) / 4;
            return Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final day in days)
                  SizedBox(
                    width: tileWidth,
                    child: _WeekDayCard(
                      date: day,
                      selected: DateUtils.isSameDay(day, selectedDate),
                      todos: todos
                          .where((todo) => todo.isActive && todo.isDueOn(day))
                          .toList(),
                      onTap: () => onSelectDate(day),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          '${_formatPlanDate(selectedDate)}  ${selectedTodos.length} 项',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (selectedTodos.isEmpty)
          const _EmptyCard(
            title: '这天还没有安排',
            subtitle: '周计划会把每天的任务密度摊开，避免都挤到今天。',
          )
        else
          ...selectedTodos.map(
            (todo) => _TodoCard(
              todo: todo,
              onTap: () => onToggle(todo),
              onPostpone: () => onPostpone(todo),
              onArchive: () => onArchive(todo),
              onDelete: () => onDelete(todo),
            ),
          ),
      ],
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  const _WeekDayCard({
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
    final postponedCount =
        todos.where((todo) => todo.status == TodoStatus.postponed).length;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _weekdayLabel(date),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${todos.length} 项',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (mustDoCount > 0 || postponedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (mustDoCount > 0) '必做 $mustDoCount',
                  if (postponedCount > 0) '延后 $postponedCount',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.82)
                      : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
