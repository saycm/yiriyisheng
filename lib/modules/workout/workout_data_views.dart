// 中文注释：锻炼模块源码，负责动作库、训练计划、训练记录和更多菜单。

part of 'workout.dart';

class _WorkoutDataView extends StatelessWidget {
  const _WorkoutDataView({
    required this.history,
    required this.onOpenMetric,
  });

  final List<WorkoutHistoryEntry> history;
  final ValueChanged<WorkoutMetricDetail> onOpenMetric;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final todayRecords = history
        .where((entry) => DateUtils.isSameDay(entry.finishedAt, today))
        .toList();
    final recentStart = today.subtract(const Duration(days: 6));
    final recentRecords = history
        .where((entry) =>
            !DateUtils.dateOnly(entry.finishedAt).isBefore(recentStart))
        .toList();
    final todayGroups = todayRecords.fold<int>(
      0,
      (total, entry) => total + entry.totalGroups,
    );
    final todayMinutes = todayRecords.fold<int>(
      0,
      (total, entry) => total + entry.durationMinutes,
    );
    final todayCalories = todayRecords.fold<int>(
      0,
      (total, entry) => total + entry.estimatedCalories,
    );
    final recentGroups = recentRecords.fold<int>(
      0,
      (total, entry) => total + entry.totalGroups,
    );
    final maxWeight = _maxWeightFrom(todayRecords);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _WorkoutDataCard(
              cardKey: const ValueKey('workout_metric_today_groups'),
              icon: Icons.fitness_center_rounded,
              value: '$todayGroups 组',
              label: WorkoutMetricKind.todayGroups.label,
              color: AppColors.primary,
              onTap: () => onOpenMetric(
                WorkoutMetricDetail(
                  kind: WorkoutMetricKind.todayGroups,
                  value: '$todayGroups 组',
                  records: todayRecords,
                ),
              ),
            ),
            _WorkoutDataCard(
              cardKey: null,
              icon: Icons.timer_rounded,
              value: '$todayMinutes min',
              label: WorkoutMetricKind.todayMinutes.label,
              color: const Color(0xFF43C6C8),
              onTap: () => onOpenMetric(
                WorkoutMetricDetail(
                  kind: WorkoutMetricKind.todayMinutes,
                  value: '$todayMinutes min',
                  records: todayRecords,
                ),
              ),
            ),
            _WorkoutDataCard(
              cardKey: null,
              icon: Icons.local_fire_department_rounded,
              value: '$todayCalories',
              label: WorkoutMetricKind.todayCalories.label,
              color: const Color(0xFFFF9559),
              onTap: () => onOpenMetric(
                WorkoutMetricDetail(
                  kind: WorkoutMetricKind.todayCalories,
                  value: '$todayCalories kcal',
                  records: todayRecords,
                ),
              ),
            ),
            _WorkoutDataCard(
              cardKey: null,
              icon: Icons.trending_up_rounded,
              value: maxWeight == 0 ? '-' : '${maxWeight}kg',
              label: WorkoutMetricKind.maxWeight.label,
              color: AppColors.success,
              onTap: () => onOpenMetric(
                WorkoutMetricDetail(
                  kind: WorkoutMetricKind.maxWeight,
                  value: maxWeight == 0 ? '-' : '${maxWeight}kg',
                  records: todayRecords,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 118,
          child: _WorkoutDataCard(
            cardKey: null,
            icon: Icons.history_rounded,
            value: '${recentRecords.length} 次 · $recentGroups 组',
            label: '最近 7 天',
            color: AppColors.primary,
            onTap: () => onOpenMetric(
              WorkoutMetricDetail(
                kind: WorkoutMetricKind.recentSessions,
                value: '${recentRecords.length} 次',
                records: recentRecords,
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _maxWeightFrom(List<WorkoutHistoryEntry> records) {
    var maxWeight = 0;
    for (final entry in records) {
      for (final result in entry.actionResults) {
        final weight = result.weight;
        if (weight == null) {
          continue;
        }
        final match = RegExp(r'\d+').firstMatch(weight);
        final parsed = int.tryParse(match?.group(0) ?? '');
        if (parsed != null && parsed > maxWeight) {
          maxWeight = parsed;
        }
      }
    }
    return maxWeight;
  }
}

class _WorkoutDataCard extends StatelessWidget {
  const _WorkoutDataCard({
    required this.cardKey,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final Key? cardKey;
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: cardKey,
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 25),
                const Spacer(),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutMetricDetailSheet extends StatelessWidget {
  const _WorkoutMetricDetailSheet({required this.detail});

  final WorkoutMetricDetail detail;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: KeyedSubtree(
        key: const ValueKey('workout_metric_detail_sheet'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GlassSurface(
            borderRadius: 18,
            color: AppColors.surface.withValues(alpha: 0.86),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detail.kind.label,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  detail.value,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (detail.records.isEmpty)
                  const Text(
                    '暂无训练记录',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  ...detail.records.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.planName,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${entry.totalGroups} 组 · ${entry.durationMinutes} min · ${entry.estimatedCalories} kcal',
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
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
