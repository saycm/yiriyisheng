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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
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
        (Icons.monitor_heart_rounded, '健康'),
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
const double moduleSwitchBarReservedHeight = 76;

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
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.surface.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.82),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.sky.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: GlassSurface(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    fontSize: 20,
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
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
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
          borderRadius: 18,
          padding: const EdgeInsets.all(4),
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
        ? 4.0
        : softCompact
            ? 4.0
            : 7.0;
    final outerRadius = compact
        ? 16.0
        : softCompact
            ? 14.0
            : 18.0;
    final itemRadius = compact
        ? 12.0
        : softCompact
            ? 11.0
            : 15.0;
    final itemWidth = compact
        ? 42.0
        : softCompact
            ? 50.0
            : 88.0;
    final itemVerticalPadding = compact
        ? 3.0
        : softCompact
            ? 3.0
            : 9.0;
    final iconSize = compact
        ? 17.0
        : softCompact
            ? 15.0
            : 23.0;
    final labelSize = compact
        ? 9.0
        : softCompact
            ? 9.0
            : 12.0;
    final iconLabelGap = compact
        ? 0.0
        : softCompact
            ? 1.0
            : 3.0;

    return Container(
      key: keyPrefix == null ? null : ValueKey('${keyPrefix}_container'),
      padding: EdgeInsets.all(outerPadding),
      decoration: BoxDecoration(
        color: glass
            ? Colors.transparent
            : AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(outerRadius),
        border: glass
            ? null
            : Border.all(color: AppColors.line.withValues(alpha: 0.88)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
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
