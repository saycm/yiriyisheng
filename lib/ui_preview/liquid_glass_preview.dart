// 中文注释：新版液态玻璃 UI 独立预览页，用于确认视觉方向，不参与正式业务流程。

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_core.dart';

class LiquidGlassPreviewPage extends StatelessWidget {
  const LiquidGlassPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFF),
      body: RepaintBoundary(
        key: const ValueKey('liquid_glass_preview_page'),
        child: Stack(
          children: [
            const Positioned.fill(child: _LiquidBackdrop()),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _PreviewTopBar(),
                    SizedBox(height: 10),
                    _ModuleLinkPreviewStrip(),
                    SizedBox(height: 12),
                    _TodayDateStrip(),
                    SizedBox(height: 12),
                    _TodayPlanHero(),
                    SizedBox(height: 14),
                    _MetricGrid(),
                    SizedBox(height: 14),
                    _WeekTaskBoard(),
                    SizedBox(height: 14),
                    _PendingTasksPanel(),
                    SizedBox(height: 14),
                    _FinancePanel(),
                  ],
                ),
              ),
            ),
            const _PreviewBottomNav(),
          ],
        ),
      ),
    );
  }
}

class _LiquidBackdrop extends StatelessWidget {
  const _LiquidBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5FBFF),
            Color(0xFFEAF2FF),
            Color(0xFFFFF3EB),
            Color(0xFFE9FBF4),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _LiquidBackdropPainter(),
      ),
    );
  }
}

class _LiquidBackdropPainter extends CustomPainter {
  const _LiquidBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: 0.28),
          AppColors.sky.withValues(alpha: 0.20),
          AppColors.success.withValues(alpha: 0.14),
        ],
      ).createShader(Offset.zero & size)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final sweep = Path()
      ..moveTo(-size.width * 0.18, size.height * 0.16)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.04,
        size.width * 0.58,
        size.height * 0.26,
        size.width * 1.18,
        size.height * 0.15,
      )
      ..lineTo(size.width * 1.18, size.height * 0.30)
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.42,
        size.width * 0.24,
        size.height * 0.22,
        -size.width * 0.18,
        size.height * 0.34,
      )
      ..close();
    canvas.drawPath(sweep, fill);

    final warmFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.accent.withValues(alpha: 0.20),
          AppColors.financeRed.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.04),
        ],
      ).createShader(Offset.zero & size)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final warmSweep = Path()
      ..moveTo(-size.width * 0.12, size.height * 0.66)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.52,
        size.width * 0.66,
        size.height * 0.78,
        size.width * 1.12,
        size.height * 0.58,
      )
      ..lineTo(size.width * 1.12, size.height * 0.72)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.92,
        size.width * 0.26,
        size.height * 0.70,
        -size.width * 0.12,
        size.height * 0.82,
      )
      ..close();
    canvas.drawPath(warmSweep, warmFill);

    final cardPaint = Paint();
    final glassBehind = [
      (const Rect.fromLTWH(-28, 94, 160, 76), AppColors.primary),
      (Rect.fromLTWH(size.width - 132, 128, 176, 92), AppColors.sky),
      (Rect.fromLTWH(26, 438, 132, 82), AppColors.accent),
      (Rect.fromLTWH(size.width - 178, 560, 142, 74), AppColors.success),
      (Rect.fromLTWH(52, 688, 180, 82), AppColors.lavender),
    ];
    for (final entry in glassBehind) {
      cardPaint
        ..color = entry.$2.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(entry.$1, const Radius.circular(24)),
        cardPaint,
      );
    }

    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 30
      ..shader = const LinearGradient(
        colors: [
          Color(0x665D72F6),
          Color(0x4438BDF8),
          Color(0x34FFB35C),
        ],
      ).createShader(Offset.zero & size);

    final path = Path()
      ..moveTo(-size.width * 0.16, size.height * 0.18)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.08,
        size.width * 0.48,
        size.height * 0.34,
        size.width * 1.12,
        size.height * 0.22,
      )
      ..moveTo(-size.width * 0.08, size.height * 0.68)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.54,
        size.width * 0.68,
        size.height * 0.84,
        size.width * 1.1,
        size.height * 0.64,
      );
    canvas.drawPath(path, ribbonPaint);

    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..strokeWidth = 1.1;
    for (var index = 0; index < 24; index++) {
      final x = -48.0 + index * 22;
      canvas.drawLine(
        Offset(x, size.height * 0.08),
        Offset(x + 72, size.height * 0.42),
        stripePaint,
      );
    }
    for (var index = 0; index < 15; index++) {
      final y = 94.0 + index * 72.0;
      canvas.drawLine(
        Offset(18, y),
        Offset(size.width - 18, y + 8),
        stripePaint..color = Colors.white.withValues(alpha: 0.26),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 26,
    this.blur = 18,
    this.opacity = 0.34,
    this.tint = AppColors.sky,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final double opacity;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.82),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: tint.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.58),
                blurRadius: 10,
                offset: const Offset(-4, -4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.58),
                        Colors.white.withValues(alpha: 0.16),
                        tint.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _GlassHighlightPainter(radius: radius),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassHighlightPainter extends CustomPainter {
  const _GlassHighlightPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final topPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.94),
          Colors.white.withValues(alpha: 0.12),
          AppColors.primary.withValues(alpha: 0.16),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(0.6), topPaint);

    final flarePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.46);
    final flare = Path()
      ..moveTo(16, 10)
      ..quadraticBezierTo(size.width * 0.28, 3, size.width * 0.50, 12);
    canvas.drawPath(flare, flarePaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.primary.withValues(alpha: 0.12);
    canvas.drawArc(
      Rect.fromLTWH(size.width - 74, size.height - 66, 96, 86),
      math.pi,
      math.pi * 0.54,
      false,
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassHighlightPainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}

class _PreviewTopBar extends StatelessWidget {
  const _PreviewTopBar();

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      radius: 24,
      opacity: 0.38,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _IconCapsule(
            icon: Icons.view_sidebar_rounded,
            color: AppColors.primary,
            background: AppColors.primarySoft,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Center(
              child: Text(
                '计划',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
          ),
          _IconCapsule(
            icon: Icons.more_horiz_rounded,
            color: AppColors.primary,
            background: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _ModuleLinkPreviewStrip extends StatelessWidget {
  const _ModuleLinkPreviewStrip();

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      radius: 20,
      blur: 16,
      opacity: 0.32,
      padding: const EdgeInsets.all(5),
      child: const Row(
        children: [
          _ModuleLinkItem(icon: Icons.wallet_rounded, label: '财务'),
          _ModuleLinkItem(
            icon: Icons.task_alt_rounded,
            label: '计划',
            active: true,
          ),
          _ModuleLinkItem(icon: Icons.restaurant_rounded, label: '饮食'),
          _ModuleLinkItem(icon: Icons.fitness_center_rounded, label: '锻炼'),
          _ModuleLinkItem(icon: Icons.monitor_heart_rounded, label: '状态'),
        ],
      ),
    );
  }
}

class _TodayDateStrip extends StatelessWidget {
  const _TodayDateStrip();

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      radius: 18,
      blur: 18,
      opacity: 0.30,
      tint: AppColors.lavender,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          Expanded(
            child: Text(
              '今天  07.07  星期二',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _CompactGlassBadge(label: '切换日期'),
        ],
      ),
    );
  }
}

class _CompactGlassBadge extends StatelessWidget {
  const _CompactGlassBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ModuleLinkItem extends StatelessWidget {
  const _ModuleLinkItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : AppColors.muted,
                size: 18,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayPlanHero extends StatelessWidget {
  const _TodayPlanHero();

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      opacity: 0.34,
      tint: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日执行',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '先完成必须做，再处理可延后事项',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 86,
                height: 86,
                child: CustomPaint(
                  painter: _ProgressRingPainter(progress: 0.68),
                  child: const Center(
                    child: Text(
                      '68%',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: _HeroNumber(label: '已完成', value: '4'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _HeroNumber(label: '待处理', value: '2'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _HeroNumber(label: '联动', value: '3'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroNumber extends StatelessWidget {
  const _HeroNumber({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.64)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    const metrics = [
      _PreviewMetric(
          '今日支出', '¥524', Icons.payments_rounded, AppColors.financeRed),
      _PreviewMetric('今日收入', '¥3,000', Icons.account_balance_wallet_rounded,
          AppColors.success),
      _PreviewMetric(
          '摄入', '168 kcal', Icons.restaurant_rounded, AppColors.accent),
      _PreviewMetric('消耗', '610 kcal', Icons.local_fire_department_rounded,
          AppColors.lavender),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              SizedBox(width: width, child: _MetricCard(metric: metric)),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _PreviewMetric metric;

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      radius: 22,
      blur: 14,
      opacity: 0.30,
      tint: metric.color,
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _IconCapsule(
                  icon: metric.icon,
                  color: metric.color,
                  background: metric.color.withValues(alpha: 0.12),
                  size: 34,
                ),
                const Spacer(),
                Icon(
                  Icons.trending_flat_rounded,
                  size: 18,
                  color: AppColors.muted.withValues(alpha: 0.86),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekTaskBoard extends StatelessWidget {
  const _WeekTaskBoard();

  @override
  Widget build(BuildContext context) {
    const days = [
      _PreviewDay('一', 3, false),
      _PreviewDay('二', 6, true),
      _PreviewDay('三', 2, false),
      _PreviewDay('四', 4, false),
      _PreviewDay('五', 5, false),
      _PreviewDay('六', 1, false),
      _PreviewDay('日', 0, false),
    ];
    return _GlassSurface(
      opacity: 0.34,
      tint: AppColors.lavender,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  '7天任务板',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '+5',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _DayPill(day: day),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _TaskLine(
            color: AppColors.primary,
            title: '做报表',
            meta: '工作 · 必须做',
          ),
          const SizedBox(height: 8),
          const _TaskLine(
            color: AppColors.accent,
            title: '记录晚餐',
            meta: '饮食 · 自动联动',
          ),
        ],
      ),
    );
  }
}

class _PendingTasksPanel extends StatelessWidget {
  const _PendingTasksPanel();

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      opacity: 0.32,
      tint: AppColors.accent,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '待办任务',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '卡片不再点一下完成，底部动作保留完成、延后、归档',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          _TaskLine(
            color: AppColors.financeRed,
            title: '还信用卡',
            meta: '财务联动 · 今天',
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.day});

  final _PreviewDay day;

  @override
  Widget build(BuildContext context) {
    final background =
        day.selected ? AppColors.ink : Colors.white.withValues(alpha: 0.54);
    final foreground = day.selected ? Colors.white : AppColors.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: day.selected
              ? AppColors.ink
              : Colors.white.withValues(alpha: 0.66),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day.label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.count}',
              style: TextStyle(
                color: foreground.withValues(alpha: day.selected ? 0.86 : 0.64),
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

class _TaskLine extends StatelessWidget {
  const _TaskLine({
    required this.color,
    required this.title,
    required this.meta,
  });

  final Color color;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.66)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancePanel extends StatelessWidget {
  const _FinancePanel();

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      opacity: 0.32,
      tint: AppColors.success,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '财务速览',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '收入覆盖支出，预算仍在安全区间',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 104,
            height: 62,
            child: CustomPaint(
              painter: _SparklinePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBottomNav extends StatelessWidget {
  const _PreviewBottomNav();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 18,
      child: SafeArea(
        top: false,
        child: _GlassSurface(
          radius: 28,
          blur: 22,
          opacity: 0.36,
          tint: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            key: const ValueKey('liquid_glass_preview_nav'),
            children: const [
              _NavItem(icon: Icons.today_rounded, label: '今日', active: true),
              _NavItem(icon: Icons.archive_rounded, label: '待办箱'),
              _NavItem(icon: Icons.view_week_rounded, label: '周计划'),
              _NavItem(icon: Icons.query_stats_rounded, label: '复盘'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : AppColors.muted,
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconCapsule extends StatelessWidget {
  const _IconCapsule({
    required this.icon,
    required this.color,
    required this.background,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.42),
        border: Border.all(color: Colors.white.withValues(alpha: 0.66)),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.62);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.sky, AppColors.success],
      ).createShader(Offset.zero & size);

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.68)
      ..cubicTo(size.width * 0.22, size.height * 0.44, size.width * 0.32,
          size.height * 0.82, size.width * 0.48, size.height * 0.54)
      ..cubicTo(size.width * 0.62, size.height * 0.28, size.width * 0.76,
          size.height * 0.32, size.width, size.height * 0.16)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.primary.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    final linePath = Path()
      ..moveTo(0, size.height * 0.68)
      ..cubicTo(size.width * 0.22, size.height * 0.44, size.width * 0.32,
          size.height * 0.82, size.width * 0.48, size.height * 0.54)
      ..cubicTo(size.width * 0.62, size.height * 0.28, size.width * 0.76,
          size.height * 0.32, size.width, size.height * 0.16);
    canvas.drawPath(
      linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreviewMetric {
  const _PreviewMetric(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _PreviewDay {
  const _PreviewDay(this.label, this.count, this.selected);

  final String label;
  final int count;
  final bool selected;
}
