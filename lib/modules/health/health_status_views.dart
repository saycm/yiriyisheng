// 中文注释：健康状态页面组件，负责展示评分、快速记录、影响因素和建议。

part of 'health.dart';

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({
    required this.onOpenModules,
    required this.onOpenSummary,
  });

  final VoidCallback onOpenModules;
  final VoidCallback onOpenSummary;

  @override
  Widget build(BuildContext context) {
    return ModuleGlassHeader(
      module: LifeModule.health,
      title: '健康',
      onOpenModules: onOpenModules,
      onOpenMore: onOpenSummary,
    );
  }
}

class _HealthStatusScoreCard extends StatelessWidget {
  const _HealthStatusScoreCard({
    required this.result,
    required this.onRecord,
  });

  final HealthStatusResult result;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    // 顶部卡片只回答“今天状态如何”和“为什么”，详细输入放在快速记录卡中。
    return Container(
      key: const ValueKey('health_status_score_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日状态',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '状态中心',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onRecord,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('记录状态'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.score.toString(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.level,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.primaryReason,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthQuickRecordCard extends StatelessWidget {
  const _HealthQuickRecordCard({
    required this.sleep,
    required this.energy,
    required this.stress,
    required this.body,
    required this.mood,
    required this.onSleepChanged,
    required this.onEnergyChanged,
    required this.onStressChanged,
    required this.onBodyChanged,
    required this.onMoodChanged,
  });

  final HealthSleepFeeling sleep;
  final HealthEnergyFeeling energy;
  final HealthStressFeeling stress;
  final HealthBodyFeeling body;
  final HealthMoodFeeling mood;
  final ValueChanged<HealthSleepFeeling> onSleepChanged;
  final ValueChanged<HealthEnergyFeeling> onEnergyChanged;
  final ValueChanged<HealthStressFeeling> onStressChanged;
  final ValueChanged<HealthBodyFeeling> onBodyChanged;
  final ValueChanged<HealthMoodFeeling> onMoodChanged;

  @override
  Widget build(BuildContext context) {
    // 快速记录用枚举值驱动，修改后父级立即重算 HealthStatusResult。
    return Container(
      key: const ValueKey('health_quick_record_card'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_rounded,
                  color: AppColors.primary, size: 21),
              SizedBox(width: 8),
              Text(
                '快速记录',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HealthChoiceRow<HealthSleepFeeling>(
            label: '睡眠',
            selected: sleep,
            values: HealthSleepFeeling.values,
            keyPrefix: 'health_quick_sleep',
            labelFor: _sleepLabel,
            onChanged: onSleepChanged,
          ),
          const SizedBox(height: 4),
          _HealthChoiceRow<HealthEnergyFeeling>(
            label: '精力',
            selected: energy,
            values: HealthEnergyFeeling.values,
            keyPrefix: 'health_quick_energy',
            labelFor: _energyLabel,
            onChanged: onEnergyChanged,
          ),
          const SizedBox(height: 4),
          _HealthChoiceRow<HealthStressFeeling>(
            label: '压力',
            selected: stress,
            values: HealthStressFeeling.values,
            keyPrefix: 'health_quick_stress',
            labelFor: _stressLabel,
            onChanged: onStressChanged,
          ),
          const SizedBox(height: 4),
          _HealthChoiceRow<HealthBodyFeeling>(
            label: '身体',
            selected: body,
            values: HealthBodyFeeling.values,
            keyPrefix: 'health_quick_body',
            labelFor: _bodyLabel,
            onChanged: onBodyChanged,
          ),
          const SizedBox(height: 4),
          _HealthChoiceRow<HealthMoodFeeling>(
            label: '心情',
            selected: mood,
            values: HealthMoodFeeling.values,
            keyPrefix: 'health_quick_mood',
            labelFor: _moodLabel,
            onChanged: onMoodChanged,
          ),
        ],
      ),
    );
  }
}

class _HealthChoiceRow<T extends Enum> extends StatelessWidget {
  const _HealthChoiceRow({
    required this.label,
    required this.selected,
    required this.values,
    required this.keyPrefix,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T selected;
  final List<T> values;
  final String keyPrefix;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .map(
                  (value) => _HealthChoiceChip<T>(
                    keyPrefix: keyPrefix,
                    value: value,
                    label: labelFor(value),
                    selected: value == selected,
                    onChanged: onChanged,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _HealthChoiceChip<T extends Enum> extends StatelessWidget {
  const _HealthChoiceChip({
    required this.keyPrefix,
    required this.value,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String keyPrefix;
  final T value;
  final String label;
  final bool selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: selected ? AppColors.primary : AppColors.ink,
      fontSize: 11,
      fontWeight: FontWeight.w900,
    );

    return InkWell(
      key: ValueKey('${keyPrefix}_${value.name}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: selected
            ? Text(label, style: labelStyle)
            : RichText(text: TextSpan(text: label, style: labelStyle)),
      ),
    );
  }
}

class _HealthImpactCard extends StatelessWidget {
  const _HealthImpactCard({required this.impacts});

  final List<HealthStatusImpact> impacts;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('health_impact_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '影响因素',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...impacts.map(
            (impact) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HealthImpactRow(impact: impact),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthImpactRow extends StatelessWidget {
  const _HealthImpactRow({required this.impact});

  final HealthStatusImpact impact;

  @override
  Widget build(BuildContext context) {
    final hasScore = impact.maxScore > 0;
    final progress = hasScore
        ? (impact.score / impact.maxScore).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: impact.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                impact.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (hasScore)
              Text(
                '${impact.score}/${impact.maxScore}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          impact.label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hasScore) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: impact.color,
              backgroundColor: AppColors.background,
            ),
          ),
        ],
      ],
    );
  }
}

class _HealthStatusSuggestionCard extends StatelessWidget {
  const _HealthStatusSuggestionCard({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('health_status_suggestion_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '状态建议',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthStatusTrendCard extends StatelessWidget {
  const _HealthStatusTrendCard({required this.result});

  final HealthStatusResult result;

  @override
  Widget build(BuildContext context) {
    final scoredImpacts =
        result.impacts.where((impact) => impact.maxScore > 0).toList();
    final trendPoints = scoredImpacts
        .map(
          (impact) => _HealthTrendPoint(
            label: impact.title,
            value: impact.score / impact.maxScore * 100,
            color: impact.color,
          ),
        )
        .toList();
    final strongest = trendPoints.isEmpty
        ? null
        : trendPoints.reduce(
            (a, b) => a.value >= b.value ? a : b,
          );
    final weakest = trendPoints.isEmpty
        ? null
        : trendPoints.reduce(
            (a, b) => a.value <= b.value ? a : b,
          );
    final semanticLabel = trendPoints.isEmpty
        ? '状态趋势图，暂无可用数据'
        : '状态趋势图，当前 ${result.score} 分，最高 ${strongest!.label} ${strongest.value.round()} 分，最低 ${weakest!.label} ${weakest.value.round()} 分';

    return Container(
      key: const ValueKey('health_status_trend_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '状态趋势',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${result.score} 分',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            weakest == null
                ? '记录状态后会显示睡眠、精力、压力等维度走势。'
                : '最低项：${weakest.label} ${weakest.value.round()}，优先留意这个维度。',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            key: const ValueKey('health_status_trend_chart'),
            height: 116,
            width: double.infinity,
            child: Semantics(
              label: semanticLabel,
              image: true,
              child: CustomPaint(
                painter: _HealthStatusTrendPainter(points: trendPoints),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trendPoints
                .map(
                  (point) => _HealthTrendLegendPill(point: point),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HealthTrendPoint {
  const _HealthTrendPoint({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _HealthTrendLegendPill extends StatelessWidget {
  const _HealthTrendLegendPill({required this.point});

  final _HealthTrendPoint point;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: point.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${point.label} ${point.value.round()}',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthStatusTrendPainter extends CustomPainter {
  _HealthStatusTrendPainter({required this.points});

  final List<_HealthTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const right = 8.0;
    const top = 8.0;
    const bottom = 22.0;
    final chartWidth = math.max(1.0, size.width - left - right);
    final chartHeight = math.max(1.0, size.height - top - bottom);
    final baselineY = top + chartHeight;

    final gridPaint = Paint()
      ..color = AppColors.line.withValues(alpha: 0.82)
      ..strokeWidth = 1;
    final textStyle = const TextStyle(
      color: AppColors.muted,
      fontSize: 9,
      fontWeight: FontWeight.w800,
    );

    for (final tick in [100, 50, 0]) {
      final y = top + chartHeight * (1 - tick / 100);
      canvas.drawLine(
          Offset(left, y), Offset(size.width - right, y), gridPaint);
      _drawText(canvas, tick.toString(), Offset(0, y - 6), textStyle);
    }

    if (points.isEmpty) {
      return;
    }

    final offsets = List.generate(points.length, (index) {
      final x = points.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * index / (points.length - 1);
      final y = top + chartHeight * (1 - points[index].value / 100);
      return Offset(x, y.clamp(top, baselineY));
    });

    final areaPath = Path()
      ..moveTo(offsets.first.dx, baselineY)
      ..lineTo(offsets.first.dx, offsets.first.dy);
    for (final point in offsets.skip(1)) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath
      ..lineTo(offsets.last.dx, baselineY)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.20),
          AppColors.sky.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));
    canvas.drawPath(areaPath, areaPaint);

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final point in offsets.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final guidePaint = Paint()
      ..color = AppColors.line.withValues(alpha: 0.58)
      ..strokeWidth = 1;
    for (var index = 0; index < offsets.length; index++) {
      final point = offsets[index];
      canvas.drawLine(
        Offset(point.dx, point.dy + 7),
        Offset(point.dx, baselineY),
        guidePaint,
      );
      final fillPaint = Paint()..color = points[index].color;
      final ringPaint = Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(point, 4.6, fillPaint);
      canvas.drawCircle(point, 4.6, ringPaint);
      _drawCenteredText(
        canvas,
        points[index].label,
        Offset(point.dx, baselineY + 8),
        textStyle,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 34);
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _HealthStatusTrendPainter oldDelegate) {
    return points != oldDelegate.points;
  }
}
