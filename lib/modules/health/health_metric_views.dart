// 中文注释：健康模块源码，负责健康数据、手动记录和系统健康数据接入。

part of 'health.dart';

class _HealthSummarySheet extends StatelessWidget {
  const _HealthSummarySheet({
    required this.day,
    required this.foodCalories,
    required this.workoutGroups,
    required this.bodyTag,
    required this.moodNote,
  });

  final HealthDay day;
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
      title: '状态总览',
      child: Column(
        children: [
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
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
    );
  }
}

class _MiniRingsPainter extends CustomPainter {
  const _MiniRingsPainter({
    required this.selected,
    required this.progress,
  });

  final bool selected;
  final List<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = selected ? 2.7 : 2.2;
    final colors = [
      const Color(0xFF48CE81),
      const Color(0xFFFF9559),
      const Color(0xFF7D9CFF),
    ];

    for (var i = 0; i < 3; i++) {
      final radius = 15.0 - i * 4;
      paint.color = const Color(0xFFE7EAF2);
      canvas.drawCircle(center, radius, paint);
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress[i],
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRingsPainter oldDelegate) {
    return selected != oldDelegate.selected || progress != oldDelegate.progress;
  }
}
