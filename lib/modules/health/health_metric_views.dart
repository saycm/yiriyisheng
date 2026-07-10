// 中文注释：健康模块源码，负责健康数据、手动记录和系统健康数据接入。

part of 'health.dart';

class _HealthSummarySheet extends StatelessWidget {
  const _HealthSummarySheet({
    required this.day,
    required this.title,
    required this.helperText,
    required this.foodCalories,
    required this.workoutGroups,
    required this.bodyTag,
    required this.moodNote,
  });

  final HealthDay day;
  final String? title;
  final String? helperText;
  final int foodCalories;
  final int workoutGroups;
  final String bodyTag;
  final String moodNote;

  @override
  Widget build(BuildContext context) {
    final steps = day.metrics.firstWhere((metric) => metric.title == '今日步数');
    final energy = day.metrics.firstWhere((metric) => metric.title == '今日能量');
    final sleep = day.metrics.firstWhere((metric) => metric.title == '昨晚睡眠');

    return InfoSheetFrame(
      title: title ?? '${day.monthDayLabel}状态总览',
      child: Column(
        children: [
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                helperText!,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _HealthSummaryTile(
            color: const Color(0xFF48CE81),
            title: '活动完成',
            value: day.ringLabels[0],
          ),
          _HealthSummaryTile(
            color: const Color(0xFFFF9559),
            title: '能量消耗',
            value: '${energy.value} ${energy.unit}',
          ),
          _HealthSummaryTile(
            color: AppColors.primary,
            title: '饮食摄入',
            value: '$foodCalories kcal',
          ),
          _HealthSummaryTile(
            color: const Color(0xFF43C6C8),
            title: '锻炼完成',
            value: '$workoutGroups 组',
          ),
          _HealthSummaryTile(
            color: const Color(0xFF61CE86),
            title: '步数',
            value: '${steps.value} ${steps.unit}',
          ),
          _HealthSummaryTile(
            color: const Color(0xFF8D7CF6),
            title: '睡眠',
            value: sleep.value,
          ),
          _HealthSummaryTile(
            color: const Color(0xFFFF6F9D),
            title: '身体状态',
            value: '$bodyTag · $moodNote',
          ),
        ],
      ),
    );
  }
}

class _HealthSummaryTile extends StatelessWidget {
  const _HealthSummaryTile({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
