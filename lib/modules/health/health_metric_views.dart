// 中文注释：健康模块源码，负责健康数据、手动记录和系统健康数据接入。

part of 'health.dart';

class _HealthSensorCard extends StatelessWidget {
  const _HealthSensorCard({required this.snapshot});

  final HealthSensorSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final values = [
      (
        '计步器',
        snapshot.stepCounterSinceBoot == null
            ? (snapshot.stepCounterAvailable ? '可用' : '无')
            : '${snapshot.stepCounterSinceBoot} 步'
      ),
      (
        '心率',
        snapshot.heartRateBpm == null
            ? (snapshot.heartRateSensorAvailable ? '待读取' : '无')
            : '${snapshot.heartRateBpm!.round()} bpm'
      ),
      (
        '加速度',
        snapshot.accelerationMagnitude == null
            ? (snapshot.accelerometerAvailable ? '可用' : '无')
            : snapshot.accelerationMagnitude!.toStringAsFixed(1)
      ),
    ];
    return ModuleLinkedSummaryCard(
      title: '手机传感器',
      subtitle: '来自系统 SensorManager 的实时设备能力和读数。',
      icon: Icons.sensors_rounded,
      values: values,
    );
  }
}

class _HealthMetricCard extends StatelessWidget {
  const _HealthMetricCard({
    required this.metric,
    required this.onTap,
  });

  final HealthMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: metric.bars.isEmpty
                  ? Center(
                      child: Text(
                        metric.hasData ? metric.source : '等待系统数据',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: TinyBarsPainter(
                        values: metric.bars,
                        color: metric.color,
                      ),
                      child: const SizedBox.expand(),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(metric.icon, color: metric.color, size: 22),
              ],
            ),
            Text(
              metric.unit,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthMetricSheet extends StatelessWidget {
  const _HealthMetricSheet({
    required this.day,
    required this.metric,
  });

  final HealthDay day;
  final HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final average = metric.bars.isEmpty
        ? null
        : (metric.bars.fold<double>(0, (sum, value) => sum + value) /
                metric.bars.length)
            .toStringAsFixed(1);

    return InfoSheetFrame(
      title: metric.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: metric.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(metric.icon, color: metric.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.title.replaceAll('⌄', ''),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.hasData
                            ? '${metric.value} ${metric.unit}'
                            : metric.value,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 120,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: metric.bars.isEmpty
                ? Center(
                    child: Text(
                      metric.statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: TinyBarsPainter(
                      values: metric.bars,
                      color: metric.color,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 14),
          EmptyCard(
            title: '趋势摘要',
            subtitle: average == null
                ? '当前没有来自 ${metric.source} 的可用采样点。'
                : '最近 ${metric.bars.length} 个真实采样点平均值 $average，当前记录为 ${metric.value} ${metric.unit}。',
          ),
        ],
      ),
    );
  }
}

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
      title: '健康总览',
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

class _ActivityRingsPainter extends CustomPainter {
  const _ActivityRingsPainter({required this.progress});

  final List<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16;
    final rings = [
      (radius: 56.0, color: const Color(0xFF48CE81), value: progress[0]),
      (radius: 38.0, color: const Color(0xFFFF9559), value: progress[1]),
      (radius: 20.0, color: const Color(0xFF7D9CFF), value: progress[2]),
    ];

    for (final ring in rings) {
      paint.color = const Color(0xFFE9ECF4);
      canvas.drawCircle(center, ring.radius, paint);
      paint.color = ring.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ring.radius),
        -math.pi / 2,
        math.pi * 2 * ring.value,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter oldDelegate) {
    return progress != oldDelegate.progress;
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
