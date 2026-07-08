// 中文注释：跨模块共享 UI 组件，负责统一卡片、导航、弹层和模块外壳。

// ignore_for_file: use_key_in_widget_constructors
part of 'shared.dart';

class InfoSheetFrame extends StatelessWidget {
  const InfoSheetFrame({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: LiquidModuleBackground(
          child: GlassSurface(
            borderRadius: 18,
            color: AppColors.surface.withValues(alpha: 0.86),
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHandle(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconBubble(
                      icon: Icons.close_rounded,
                      color: const Color(0xFF9A8FF7),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [child],
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

class ModuleSectionTitle extends StatelessWidget {
  const ModuleSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class PlanBottomNav extends StatelessWidget {
  const PlanBottomNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.today_rounded, '今日'),
      (Icons.archive_rounded, '待办箱'),
      (Icons.view_week_rounded, '周计划'),
      (Icons.query_stats_rounded, '复盘'),
    ];

    return CapsuleNav(
      selectedIndex: selectedIndex,
      items: items,
      onChanged: onChanged,
      softCompact: true,
      keyPrefix: 'plan_bottom_nav',
    );
  }
}

class FinanceBottomNav extends StatelessWidget {
  const FinanceBottomNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.insert_chart_rounded, '总览'),
      (Icons.receipt_long_rounded, '记录'),
      (Icons.account_balance_rounded, '资产'),
    ];

    return CapsuleNav(
      selectedIndex: selectedIndex,
      items: items,
      onChanged: onChanged,
      softCompact: true,
      keyPrefix: 'finance_bottom_nav',
    );
  }
}

class _ModuleQuickNav extends StatelessWidget {
  const _ModuleQuickNav({
    required this.selected,
    required this.onSwitchModule,
    this.keyPrefix,
    this.glass = false,
  });

  final LifeModule selected;
  final ValueChanged<LifeModule> onSwitchModule;
  final String? keyPrefix;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    return CapsuleNav(
      selectedIndex: switch (selected) {
        LifeModule.finance => 0,
        LifeModule.plan => 1,
        LifeModule.food => 2,
        LifeModule.workout => 3,
        LifeModule.health => 4,
      },
      items: const [
        (Icons.account_balance_wallet_rounded, '财务'),
        (Icons.event_available_rounded, '计划'),
        (Icons.restaurant_rounded, '饮食'),
        (Icons.fitness_center_rounded, '锻炼'),
        (Icons.monitor_heart_rounded, '状态'),
      ],
      compact: true,
      glass: glass,
      keyPrefix: keyPrefix,
      onChanged: (index) {
        final modules = [
          LifeModule.finance,
          LifeModule.plan,
          LifeModule.food,
          LifeModule.workout,
          LifeModule.health,
        ];
        onSwitchModule(modules[index]);
      },
    );
  }
}

const double moduleSwitchBarBottomGap = 8;
const double moduleSwitchBarReservedHeight = 64;

class ModuleBottomNavSlot extends StatelessWidget {
  const ModuleBottomNavSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          moduleSwitchBarBottomGap,
        ),
        child: child,
      ),
    );
  }
}

class LiquidModuleBackground extends StatelessWidget {
  const LiquidModuleBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _ModuleLiquidBackdrop(),
        child,
      ],
    );
  }
}

class _ModuleLiquidBackdrop extends StatelessWidget {
  const _ModuleLiquidBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('module_liquid_backdrop'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7FBFF),
            Color(0xFFEFF4FF),
            Color(0xFFFFF6EE),
            Color(0xFFEFFBF6),
          ],
        ),
      ),
      child: CustomPaint(
        painter: const _ModuleLiquidBackdropPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ModuleLiquidBackdropPainter extends CustomPainter {
  const _ModuleLiquidBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bandPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.20),
          AppColors.sky.withValues(alpha: 0.14),
          AppColors.success.withValues(alpha: 0.10),
        ],
      ).createShader(Offset.zero & size);

    final topBand = Path()
      ..moveTo(-size.width * 0.20, size.height * 0.14)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.02,
        size.width * 0.55,
        size.height * 0.28,
        size.width * 1.18,
        size.height * 0.15,
      )
      ..lineTo(size.width * 1.18, size.height * 0.27)
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.40,
        size.width * 0.20,
        size.height * 0.18,
        -size.width * 0.20,
        size.height * 0.32,
      )
      ..close();
    canvas.drawPath(topBand, bandPaint);

    final warmPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..shader = LinearGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.16),
          AppColors.financeRed.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);
    final lowerBand = Path()
      ..moveTo(-size.width * 0.16, size.height * 0.67)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.52,
        size.width * 0.68,
        size.height * 0.82,
        size.width * 1.16,
        size.height * 0.58,
      )
      ..lineTo(size.width * 1.16, size.height * 0.72)
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.92,
        size.width * 0.22,
        size.height * 0.70,
        -size.width * 0.16,
        size.height * 0.82,
      )
      ..close();
    canvas.drawPath(lowerBand, warmPaint);

    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 22
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.18),
          AppColors.sky.withValues(alpha: 0.14),
          AppColors.accent.withValues(alpha: 0.10),
        ],
      ).createShader(Offset.zero & size);
    final ribbon = Path()
      ..moveTo(-size.width * 0.12, size.height * 0.20)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.08,
        size.width * 0.50,
        size.height * 0.32,
        size.width * 1.10,
        size.height * 0.22,
      )
      ..moveTo(-size.width * 0.10, size.height * 0.72)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.58,
        size.width * 0.68,
        size.height * 0.86,
        size.width * 1.10,
        size.height * 0.64,
      );
    canvas.drawPath(ribbon, ribbonPaint);

    final linePaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.28);
    for (var index = 0; index < 18; index++) {
      final x = -36.0 + index * 25;
      canvas.drawLine(
        Offset(x, size.height * 0.09),
        Offset(x + 64, size.height * 0.36),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 18,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? AppColors.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.78),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.07),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: AppColors.sky.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.52),
                          Colors.white.withValues(alpha: 0.16),
                          AppColors.sky.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _LiquidGlassRimPainter(radius: borderRadius),
                  ),
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

class _LiquidGlassRimPainter extends CustomPainter {
  const _LiquidGlassRimPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.90),
          Colors.white.withValues(alpha: 0.12),
          AppColors.primary.withValues(alpha: 0.13),
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.55), Radius.circular(radius)),
      borderPaint,
    );

    final flarePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3
      ..color = Colors.white.withValues(alpha: 0.42);
    final flare = Path()
      ..moveTo(14, 8)
      ..quadraticBezierTo(size.width * 0.24, 2, size.width * 0.46, 10);
    canvas.drawPath(flare, flarePaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassRimPainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}

class ModuleGlassHeader extends StatelessWidget {
  const ModuleGlassHeader({
    required this.module,
    required this.title,
    required this.onOpenModules,
    required this.onOpenMore,
  });

  final LifeModule module;
  final String title;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: GlassSurface(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          key: const ValueKey('module_glass_header'),
          children: [
            _GlassIconButton(
              icon: Icons.view_sidebar_rounded,
              color: AppColors.primary,
              onTap: onOpenModules,
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  key: ValueKey('module_glass_header_title_${module.name}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            _GlassIconButton(
              icon: Icons.more_horiz_rounded,
              color: AppColors.primary,
              onTap: onOpenMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class HeaderActionPill extends StatelessWidget {
  const HeaderActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: GlassSurface(
        borderRadius: 16,
        color: AppColors.surface.withValues(alpha: 0.52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModuleLinkStrip extends StatelessWidget {
  const ModuleLinkStrip({
    required this.selected,
    required this.onSwitchModule,
  });

  final LifeModule selected;
  final ValueChanged<LifeModule> onSwitchModule;

  @override
  Widget build(BuildContext context) {
    // 这里是所有主模块共用的联动入口，保证任意模块都能直接跳到其它模块。
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: GlassSurface(
          borderRadius: 16,
          padding: const EdgeInsets.all(3),
          color: AppColors.surface.withValues(alpha: 0.58),
          child: FittedBox(
            key: const ValueKey('module_link_glass_container'),
            fit: BoxFit.scaleDown,
            child: _ModuleQuickNav(
              selected: selected,
              onSwitchModule: onSwitchModule,
              keyPrefix: 'module_link',
              glass: true,
            ),
          ),
        ),
      ),
    );
  }
}

class CapsuleNav extends StatelessWidget {
  const CapsuleNav({
    required this.selectedIndex,
    required this.items,
    required this.onChanged,
    this.compact = false,
    this.softCompact = false,
    this.glass = false,
    this.keyPrefix,
  });

  final int selectedIndex;
  final List<(IconData, String)> items;
  final ValueChanged<int> onChanged;
  final bool compact;
  final bool softCompact;
  final bool glass;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final outerPadding = compact
        ? 3.0
        : softCompact
            ? 3.0
            : 7.0;
    final outerRadius = compact
        ? 14.0
        : softCompact
            ? 12.0
            : 18.0;
    final itemRadius = compact
        ? 10.0
        : softCompact
            ? 9.0
            : 15.0;
    final itemWidth = compact
        ? 40.0
        : softCompact
            ? 44.0
            : 88.0;
    final itemVerticalPadding = compact
        ? 2.0
        : softCompact
            ? 2.0
            : 9.0;
    final iconSize = compact
        ? 16.0
        : softCompact
            ? 14.0
            : 23.0;
    final labelSize = compact
        ? 9.0
        : softCompact
            ? 8.5
            : 12.0;
    final iconLabelGap = compact
        ? 0.0
        : softCompact
            ? 0.0
            : 3.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(outerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          key: keyPrefix == null ? null : ValueKey('${keyPrefix}_container'),
          padding: EdgeInsets.all(outerPadding),
          decoration: BoxDecoration(
            color: glass
                ? Colors.transparent
                : AppColors.surface.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(outerRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: glass ? 0.58 : 0.74),
            ),
            boxShadow: glass
                ? null
                : [
                    airyShadow(AppColors.primary),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = selectedIndex == index;
              return InkWell(
                key: keyPrefix == null ? null : ValueKey('${keyPrefix}_$index'),
                borderRadius: BorderRadius.circular(itemRadius),
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: itemWidth,
                  padding: EdgeInsets.symmetric(vertical: itemVerticalPadding),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.sky, AppColors.primary],
                          )
                        : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(itemRadius),
                    border: selected
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.46),
                          )
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.$1,
                        size: iconSize,
                        color: selected ? Colors.white : AppColors.muted,
                      ),
                      SizedBox(height: iconLabelGap),
                      Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.muted,
                          fontSize: labelSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        shadows: [airyShadow(AppColors.sky)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class IconBubble extends StatelessWidget {
  const IconBubble({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: airyCardDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          borderColor: color.withValues(alpha: 0.16),
          shadows: [airyShadow(color)],
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD7DBE8),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class LinkedValue extends StatelessWidget {
  const LinkedValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class ModuleLinkedSummaryCard extends StatelessWidget {
  const ModuleLinkedSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.values,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<(String label, String value)> values;

  @override
  Widget build(BuildContext context) {
    // 所有模块共用这个摘要卡片，保证跨模块数据的展示口径一致。
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.82),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final entry in values)
                  LinkedValue(label: entry.$1, value: entry.$2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TinyBarsPainter extends CustomPainter {
  TinyBarsPainter({
    required this.values,
    required this.color,
  });

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFE9ECF4)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      axisPaint,
    );
    if (values.isEmpty) {
      return;
    }

    final maxValue = math.max(1.0, values.reduce(math.max));
    final barWidth = size.width / (values.length * 1.55);
    final gap = barWidth * 0.55;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < values.length; i++) {
      final x = i * (barWidth + gap) + barWidth / 2;
      final height = (size.height - 8) * values[i] / maxValue;
      paint.strokeWidth = barWidth;
      canvas.drawLine(
        Offset(x, size.height - 4),
        Offset(x, size.height - 4 - height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TinyBarsPainter oldDelegate) {
    return values != oldDelegate.values || color != oldDelegate.color;
  }
}

class SheetTextField extends StatelessWidget {
  const SheetTextField({
    required this.keyName,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  final String keyName;
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey(keyName),
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
