// 中文注释：计划周视图选中日期面板，负责展示当天任务和批量排入入口。

part of '../../plan.dart';

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
