// 中文注释：财务模块源码，负责账目、资产、预算、财产健康值和 AI 记账。

part of 'finance.dart';

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.showExpense,
    required this.trendRange,
    required this.onToggleTrend,
    required this.onChangeRange,
  });

  final bool showExpense;
  final String trendRange;
  final ValueChanged<bool> onToggleTrend;
  final ValueChanged<String> onChangeRange;

  @override
  Widget build(BuildContext context) {
    final values = _trendValues(showExpense, trendRange);
    final total = values.fold<double>(0, (sum, value) => sum + value).round();
    final unit = showExpense ? '支出' : '收入';

    return Container(
      height: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
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
                values: values,
                range: trendRange,
                color: showExpense
                    ? AppColors.financeRed
                    : const Color(0xFF58CE82),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  List<double> _trendValues(bool showExpense, String range) {
    if (range == '6个月') {
      return showExpense
          ? const [410, 358, 492, 283, 591, 518]
          : const [2800, 3000, 3000, 3200, 3000, 3000];
    }
    return showExpense
        ? const [0, 0, 0, 2, 12, 15, 1, 14]
        : const [4, 6, 5, 7, 8, 9, 8, 10];
  }
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
    required this.color,
  });

  final List<double> values;
  final String range;
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
    final startLabel = range == '6个月' ? '1月' : '5/17';
    final endLabel = range == '6个月' ? '6月' : '5/23';

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
        color != oldDelegate.color;
  }
}
