part of '../../../main.dart';

class _TodayOverviewCard extends StatelessWidget {
  const _TodayOverviewCard({
    required this.pendingTodos,
    required this.todayExpense,
    required this.foodCalories,
    required this.workoutGroups,
    required this.healthStatusText,
  });

  final int pendingTodos;
  final double todayExpense;
  final int foodCalories;
  final int workoutGroups;
  final String healthStatusText;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        label: '待办',
        value: '$pendingTodos',
        icon: Icons.checklist_rounded,
        color: AppColors.primary,
      ),
      (
        label: '支出',
        value: _formatMoney(todayExpense),
        icon: Icons.receipt_long_rounded,
        color: AppColors.financeRed,
      ),
      (
        label: '热量',
        value: '$foodCalories',
        icon: Icons.restaurant_rounded,
        color: AppColors.success,
      ),
      (
        label: '训练',
        value: '$workoutGroups 组',
        icon: Icons.fitness_center_rounded,
        color: const Color(0xFF9278F7),
      ),
      (
        label: '健康',
        value: healthStatusText,
        icon: Icons.favorite_rounded,
        color: const Color(0xFFFF6F9D),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        shadows: [_airyShadow(AppColors.primary)],
      ),
      key: const ValueKey('today_overview_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日总览',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metrics
                .map(
                  (metric) => _TodayOverviewMetric(
                    label: metric.label,
                    value: metric.value,
                    icon: metric.icon,
                    color: metric.color,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TodayOverviewMetric extends StatelessWidget {
  const _TodayOverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
