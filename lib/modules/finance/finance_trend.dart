// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.showExpense,
    required this.trendRange,
    required this.records,
    required this.onToggleTrend,
    required this.onChangeRange,
  });

  final bool showExpense;
  final String trendRange;
  final List<FinanceRecord> records;
  final ValueChanged<bool> onToggleTrend;
  final ValueChanged<String> onChangeRange;

  @override
  Widget build(BuildContext context) {
    final series = _trendSeries(records, showExpense, trendRange);
    final total =
        series.values.fold<double>(0, (sum, value) => sum + value).round();
    final unit = showExpense ? '支出' : '收入';

    return SizedBox(
      height: 250,
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.82),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '收支趋势',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _SegmentButton(
                  label: '支出',
                  selected: showExpense,
                  onTap: () => onToggleTrend(true),
                ),
                const SizedBox(width: 8),
                _SegmentButton(
                  label: '收入',
                  selected: !showExpense,
                  onTap: () => onToggleTrend(false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _RangeChip(
                  label: '7天',
                  selected: trendRange == '7天',
                  onTap: () => onChangeRange('7天'),
                ),
                const SizedBox(width: 8),
                _RangeChip(
                  label: '6个月',
                  selected: trendRange == '6个月',
                  onTap: () => onChangeRange('6个月'),
                ),
                const Spacer(),
                Text(
                  '$trendRange$unit ¥$total',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CustomPaint(
                painter: _TrendPainter(
                  values: series.values,
                  range: trendRange,
                  startLabel: series.startLabel,
                  endLabel: series.endLabel,
                  color: showExpense
                      ? AppColors.financeRed
                      : const Color(0xFF58CE82),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendSeries {
  const _TrendSeries({
    required this.values,
    required this.startLabel,
    required this.endLabel,
  });

  final List<double> values;
  final String startLabel;
  final String endLabel;
}

_TrendSeries _trendSeries(
  List<FinanceRecord> records,
  bool showExpense,
  String range,
) {
  final now = DateTime.now();
  final type = showExpense ? '支出' : '收入';
  final values = <double>[];

  if (range == '6个月') {
    final months = List.generate(6, (index) {
      return DateTime(now.year, now.month - 5 + index);
    });
    for (final month in months) {
      values.add(records.where((record) {
        final date = record.date ?? now;
        return record.type == type &&
            date.year == month.year &&
            date.month == month.month;
      }).fold<double>(0, (sum, record) => sum + record.amount));
    }
    return _TrendSeries(
      values: values,
      startLabel: '${months.first.month}月',
      endLabel: '${months.last.month}月',
    );
  }

  final days = List.generate(7, (index) {
    return DateUtils.dateOnly(now.subtract(Duration(days: 6 - index)));
  });
  for (final day in days) {
    values.add(records.where((record) {
      final recordDay = DateUtils.dateOnly(record.date ?? now);
      return record.type == type && DateUtils.isSameDay(recordDay, day);
    }).fold<double>(0, (sum, record) => sum + record.amount));
  }
  return _TrendSeries(
    values: values,
    startLabel: '${days.first.month}/${days.first.day}',
    endLabel: '${days.last.month}/${days.last.day}',
  );
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.range,
    required this.startLabel,
    required this.endLabel,
    required this.color,
  });

  final List<double> values;
  final String range;
  final String startLabel;
  final String endLabel;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE9ECF4)
      ..strokeWidth = 1;
    final textStyle = TextStyle(
      color: AppColors.muted.withValues(alpha: 0.72),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    const left = 4.0;
    const right = 26.0;
    const top = 8.0;
    const bottom = 24.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    for (var i = 0; i <= 3; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    final maxValue = math.max(1.0, values.reduce(math.max));
    final highLabel = maxValue.round().toString();
    final middleLabel = (maxValue * 2 / 3).round().toString();
    final lowLabel = (maxValue / 3).round().toString();
    _drawText(canvas, highLabel, Offset(size.width - 24, top - 2), textStyle);
    _drawText(canvas, middleLabel,
        Offset(size.width - 24, top + chartHeight / 3 - 5), textStyle);
    _drawText(canvas, lowLabel,
        Offset(size.width - 24, top + chartHeight * 2 / 3 - 5), textStyle);
    _drawText(
        canvas, '0', Offset(size.width - 14, top + chartHeight - 8), textStyle);
    _drawText(canvas, startLabel, Offset(left, size.height - 14), textStyle);
    _drawText(
        canvas, endLabel, Offset(size.width - 34, size.height - 14), textStyle);

    final points = List.generate(values.length, (index) {
      final x = left + chartWidth * index / (values.length - 1);
      final y = top + chartHeight * (1 - values[index] / maxValue);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final point = points[i];
      final controlX = (previous.dx + point.dx) / 2;
      path.cubicTo(
          controlX, previous.dy, controlX, point.dy, point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, top + chartHeight)
      ..lineTo(points.first.dx, top + chartHeight)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final last = points.last;
    canvas.drawCircle(last, 4, Paint()..color = Colors.white);
    canvas.drawCircle(
        last,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return values != oldDelegate.values ||
        range != oldDelegate.range ||
        startLabel != oldDelegate.startLabel ||
        endLabel != oldDelegate.endLabel ||
        color != oldDelegate.color;
  }
}
