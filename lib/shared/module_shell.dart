// 中文注释：跨模块共享 UI 组件，负责统一卡片、导航、弹层和模块外壳。

part of 'shared.dart';

BoxShadow airyShadow([Color color = AppColors.primary]) {
  return BoxShadow(
    color: color.withValues(alpha: 0.11),
    blurRadius: 22,
    offset: const Offset(0, 10),
  );
}

BoxDecoration airyCardDecoration({
  Color color = AppColors.surface,
  Color? borderColor,
  List<BoxShadow>? shadows,
}) {
  final effectiveColor =
      color == AppColors.surface ? color.withValues(alpha: 0.90) : color;
  return BoxDecoration(
    color: effectiveColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: borderColor ?? Colors.white.withValues(alpha: 0.70),
    ),
    boxShadow: shadows ?? [airyShadow(AppColors.primary)],
  );
}

class PlaceholderModulePage extends StatelessWidget {
  const PlaceholderModulePage({
    super.key,
    required this.module,
    required this.onOpenModules,
    required this.onSwitchModule,
  });

  final LifeModule module;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;

  @override
  Widget build(BuildContext context) {
    final info = switch (module) {
      LifeModule.food => (
          '饮食',
          Icons.restaurant_rounded,
          '下一张会按 1.png/2.png 做食物添加、分类选择、卡路里合计。'
        ),
      LifeModule.workout => (
          '锻炼',
          Icons.fitness_center_rounded,
          '下一步会按 8.png/6.png 做训练列表、动作组、开始动作。'
        ),
      LifeModule.health => (
          '状态',
          Icons.monitor_heart_rounded,
          '后续会按 9.png 做状态圆环、睡眠、步数、心率、能量卡片。'
        ),
      _ => ('模块', Icons.apps_rounded, '这个模块马上补。'),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LiquidModuleBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    IconBubble(
                      icon: Icons.view_sidebar_rounded,
                      color: const Color(0xFF91A3FF),
                      onTap: onOpenModules,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          info.$1,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    IconBubble(
                      icon: Icons.more_horiz_rounded,
                      color: AppColors.primary,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                EmptyCard(
                  title: info.$1,
                  subtitle: info.$3,
                ),
                const Spacer(),
                _ModuleQuickNav(
                  selected: module,
                  onSwitchModule: onSwitchModule,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
