// 中文注释：跨模块共享 UI 组件，负责统一卡片、导航、弹层和模块外壳。

// ignore_for_file: use_key_in_widget_constructors
part of 'shared.dart';

class ModuleSheet extends StatelessWidget {
  const ModuleSheet({
    required this.selected,
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todayExpense,
    required this.events,
    required this.onSelect,
    this.onSignOut,
  });

  final LifeModule selected;
  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;
  final double todayExpense;
  final List<LifeEvent> events;
  final ValueChanged<LifeModule> onSelect;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: LiquidModuleBackground(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
            child: GlassSurface(
              borderRadius: 18,
              color: AppColors.surface.withValues(alpha: 0.86),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
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
                      const Expanded(
                        child: Center(
                          child: Text(
                            '功能模块',
                            style: TextStyle(
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
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      key: const ValueKey('module_sheet_scroll'),
                      children: [
                        _ModuleTodaySummaryBar(
                          pendingTodos: pendingTodos,
                          foodCalories: foodCalories,
                          workoutGroups: workoutGroups,
                        ),
                        const SizedBox(height: 14),
                        _ModuleCenterGrid(
                          selected: selected,
                          pendingTodos: pendingTodos,
                          foodCalories: foodCalories,
                          workoutGroups: workoutGroups,
                          todayExpense: todayExpense,
                          onSelect: onSelect,
                          onOpenSettings: () => _showSettingsSheet(context),
                        ),
                        const SizedBox(height: 14),
                        _ModuleRecentEventsCard(
                            events: events.take(3).toList()),
                        const SizedBox(height: 14),
                        const ModuleSectionTitle(
                          icon: Icons.more_horiz_rounded,
                          title: '更多',
                        ),
                        const SizedBox(height: 10),
                        _ModuleListItem(
                          icon: Icons.info_outline_rounded,
                          title: '关于 App',
                          onTap: () => _showAboutSheet(context),
                        ),
                        _ModuleListItem(
                          icon: Icons.article_outlined,
                          title: '使用指导',
                          onTap: () => _showGuideSheet(context),
                        ),
                        _ModuleListItem(
                          icon: Icons.edit_rounded,
                          title: '问题反馈',
                          onTap: () => _showFeedbackSheet(context),
                        ),
                        if (onSignOut != null) ...[
                          const SizedBox(height: 8),
                          _ModuleListItem(
                            icon: Icons.logout_rounded,
                            title: '退出登录',
                            iconColor: AppColors.financeRed,
                            titleColor: AppColors.financeRed,
                            onTap: () {
                              Navigator.of(context).pop();
                              unawaited(onSignOut!());
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AboutAppSheet(),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SettingsSheet(),
    );
  }

  void _showGuideSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GuideSheet(),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FeedbackSheet(),
    );
  }
}

class _ModuleTodaySummaryBar extends StatelessWidget {
  const _ModuleTodaySummaryBar({
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
  });

  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('module_today_summary'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderColor: AppColors.line,
        shadows: [airyShadow(AppColors.sky)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 7),
              Text(
                '今日状态',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModuleSummaryChip(text: '待办 $pendingTodos 项'),
              _ModuleSummaryChip(text: '饮食 $foodCalories kcal'),
              _ModuleSummaryChip(text: '锻炼 $workoutGroups 组'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleSummaryChip extends StatelessWidget {
  const _ModuleSummaryChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ModuleCenterGrid extends StatelessWidget {
  const _ModuleCenterGrid({
    required this.selected,
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todayExpense,
    required this.onSelect,
    required this.onOpenSettings,
  });

  final LifeModule selected;
  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;
  final double todayExpense;
  final ValueChanged<LifeModule> onSelect;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final financeText =
        todayExpense > 0 ? '今日支出 ¥${_formatModuleMoney(todayExpense)}' : '查看账本';
    final healthText = foodCalories > 0 || workoutGroups > 0 ? '今日有记录' : '未记录';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ModuleSectionTitle(
          icon: Icons.grid_view_rounded,
          title: '模块状态',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 10) / 2;
            Widget tile(Widget child) {
              return SizedBox(width: tileWidth, child: child);
            }

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_plan'),
                    icon: Icons.event_available_rounded,
                    title: '计划',
                    status: '$pendingTodos 项待办',
                    selected: selected == LifeModule.plan,
                    onTap: () => onSelect(LifeModule.plan),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_finance'),
                    icon: Icons.account_balance_wallet_rounded,
                    title: '财务',
                    status: financeText,
                    selected: selected == LifeModule.finance,
                    onTap: () => onSelect(LifeModule.finance),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_food'),
                    icon: Icons.restaurant_rounded,
                    title: '饮食',
                    status: '$foodCalories kcal',
                    selected: selected == LifeModule.food,
                    onTap: () => onSelect(LifeModule.food),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_workout'),
                    icon: Icons.fitness_center_rounded,
                    title: '锻炼',
                    status: '$workoutGroups 组训练',
                    selected: selected == LifeModule.workout,
                    onTap: () => onSelect(LifeModule.workout),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_health'),
                    icon: Icons.monitor_heart_rounded,
                    title: '状态',
                    status: healthText,
                    selected: selected == LifeModule.health,
                    onTap: () => onSelect(LifeModule.health),
                  ),
                ),
                tile(
                  _ModuleCenterTile(
                    tileKey: const ValueKey('module_sheet_settings'),
                    icon: Icons.settings_rounded,
                    title: '设置',
                    status: '账号与偏好',
                    selected: false,
                    onTap: onOpenSettings,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ModuleCenterTile extends StatelessWidget {
  const _ModuleCenterTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: tileKey,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: airyCardDecoration(
          color: selected
              ? AppColors.primarySoft.withValues(alpha: 0.9)
              : AppColors.surface.withValues(alpha: 0.96),
          borderColor: selected
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.line,
          shadows: [airyShadow(selected ? AppColors.primary : AppColors.sky)],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.muted,
                size: 19,
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
                  const SizedBox(height: 3),
                  Text(
                    status,
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
          ],
        ),
      ),
    );
  }
}

class _ModuleRecentEventsCard extends StatelessWidget {
  const _ModuleRecentEventsCard({required this.events});

  final List<LifeEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 19),
              SizedBox(width: 8),
              Text(
                '最近动态',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            const Text(
              '今天还没有新记录',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (var index = 0; index < events.length; index++)
              _ModuleRecentEventRow(
                event: events[index],
                showDivider: index != events.length - 1,
              ),
        ],
      ),
    );
  }
}

class _ModuleRecentEventRow extends StatelessWidget {
  const _ModuleRecentEventRow({
    required this.event,
    required this.showDivider,
  });

  final LifeEvent event;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      margin: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(event.icon, color: event.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.detail,
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
        ],
      ),
    );
  }
}

String _formatModuleMoney(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toStringAsFixed(0);
  }
  return amount.toStringAsFixed(2);
}

class AppIconMark extends StatelessWidget {
  const AppIconMark({this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.waves_rounded, color: Colors.white, size: size * 0.66),
    );
  }
}

class _ModuleListItem extends StatelessWidget {
  const _ModuleListItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = const Color(0xFF9AA8EC),
    this.titleColor = AppColors.ink,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderColor: AppColors.line.withValues(alpha: 0.78),
        shadows: [airyShadow(iconColor)],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
