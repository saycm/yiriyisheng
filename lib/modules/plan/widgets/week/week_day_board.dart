// 中文注释：计划周视图 7 天看板，负责日期卡、负载标签和每日任务摘要。

part of '../../plan.dart';

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
    return KeyedSubtree(
      key: const ValueKey('week_plan_day_board'),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.82),
        padding: const EdgeInsets.all(14),
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
                childAspectRatio: 1.48,
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
            const SizedBox(height: 8),
            if (todos.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : load.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${todos.length}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : load.color,
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
    color: AppColors.surface.withValues(alpha: 0.88),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
    boxShadow: [airyShadow(AppColors.primary)],
  );
}
