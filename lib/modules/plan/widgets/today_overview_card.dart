// 中文注释：计划模块页面组件，负责今日总览、待办箱、周计划和统计视图。

part of '../plan.dart';

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
        value: formatMoney(todayExpense),
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
    ];
    final metricTiles = metrics
        .map(
          (metric) => _TodayOverviewMetric(
            label: metric.label,
            value: metric.value,
            icon: metric.icon,
            color: metric.color,
          ),
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        shadows: [airyShadow(AppColors.primary)],
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
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final tileWidth = (constraints.maxWidth - spacing) / 2;
              return Column(
                children: [
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final tile in metricTiles)
                        SizedBox(width: tileWidth, child: tile),
                    ],
                  ),
                  const SizedBox(height: spacing),
                  _TodayOverviewHealthPanel(statusText: healthStatusText),
                ],
              );
            },
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
    return Container(
      key: ValueKey('today_overview_metric_$label'),
      height: 82,
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
          const Spacer(),
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
    );
  }
}

class _TodayOverviewHealthPanel extends StatelessWidget {
  const _TodayOverviewHealthPanel({required this.statusText});

  final String statusText;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFF6F9D);
    return Container(
      key: const ValueKey('today_overview_health_panel'),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite_rounded, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '健康',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
