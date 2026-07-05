// 中文注释：计划周视图待安排区，负责无日期、过期和延期待整理任务。

part of '../../plan.dart';

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
