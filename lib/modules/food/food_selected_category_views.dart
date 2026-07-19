// 中文注释：饮食模块源码，负责食物类目、餐次记录和营养汇总。

part of 'food.dart';

class _FoodSelectedBar extends StatelessWidget {
  const _FoodSelectedBar({
    required this.count,
    required this.calories,
    required this.onRecord,
  });

  final int count;
  final int calories;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        moduleSwitchBarBottomGap,
      ),
      child: Container(
        key: const ValueKey('food_selected_bar_container'),
        height: 48,
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9FA8C7).withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '已选 $count 项 · $calories 千卡',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              width: 88,
              height: 36,
              child: FilledButton(
                key: const ValueKey('food_record_selected_button'),
                onPressed: onRecord,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '记录',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodToolsSheet extends StatelessWidget {
  const _FoodToolsSheet({
    required this.selectedCount,
    required this.todayCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.activeMeal,
    required this.onAddCustomFood,
    required this.onRepeatLastMeal,
    required this.onShowTodayLogs,
    required this.onClearSelected,
  });

  final int selectedCount;
  final int todayCalories;
  final double protein;
  final double carbs;
  final double fat;
  final String activeMeal;
  final VoidCallback onAddCustomFood;
  final VoidCallback onRepeatLastMeal;
  final VoidCallback onShowTodayLogs;
  final VoidCallback? onClearSelected;

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '饮食工具',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FoodToolSection(
            icon: Icons.edit_note_rounded,
            title: '记录',
            children: [
              _FoodToolTile(
                keyValue: 'food_tool_add_custom',
                icon: Icons.add_circle_rounded,
                title: '添加自定义食物',
                subtitle: '新增名称、热量、单位和分类',
                onTap: onAddCustomFood,
              ),
              _FoodToolTile(
                keyValue: 'food_tool_repeat_last_meal',
                icon: Icons.replay_rounded,
                title: '一键再吃',
                subtitle: '按当前餐次复用最近记录或常用搭配',
                onTap: onRepeatLastMeal,
              ),
              _FoodToolTile(
                keyValue: 'food_tool_today_logs',
                icon: Icons.receipt_long_rounded,
                title: '查看今日记录',
                subtitle: '核对今天已经记录的食物',
                onTap: onShowTodayLogs,
              ),
              const _FoodToolTile(
                keyValue: 'food_tool_image_recognition',
                icon: Icons.image_search_rounded,
                title: '图片识别',
                subtitle: '待接入食物图片解析',
                badge: '待接入',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FoodToolSection(
            icon: Icons.flag_rounded,
            title: '今日汇总',
            children: [
              _FoodToolInfoCard(
                icon: Icons.local_fire_department_rounded,
                title: '已摄入热量',
                value: '$todayCalories kcal',
                subtitle: '当前餐次：$activeMeal',
              ),
              _FoodToolInfoCard(
                icon: Icons.pie_chart_rounded,
                title: '营养汇总',
                value:
                    '蛋白 ${protein.round()}g · 碳水 ${carbs.round()}g · 脂肪 ${fat.round()}g',
                subtitle: '根据食物分类估算，请以包装或称量数据为准',
              ),
              const _FoodToolInfoCard(
                icon: Icons.schedule_rounded,
                title: '餐次规则',
                value: '按本机时间自动判断',
                subtitle: '05:00 早餐，11:00 午餐，16:00 晚餐，21:00 夜宵',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FoodToolSection(
            icon: Icons.tune_rounded,
            title: '管理',
            children: [
              _FoodToolTile(
                keyValue: 'food_tool_clear_selected',
                icon: Icons.cleaning_services_rounded,
                title: '清空当前已选',
                subtitle: selectedCount == 0
                    ? '当前没有已选食物'
                    : '清空 $selectedCount 项待记录食物',
                onTap: onClearSelected,
                badge: selectedCount == 0 ? '无已选' : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodToolSection extends StatelessWidget {
  const _FoodToolSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModuleSectionTitle(icon: icon, title: title),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _FoodToolTile extends StatelessWidget {
  const _FoodToolTile({
    required this.keyValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.badge,
  });

  final String keyValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? AppColors.primary : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: enabled ? 0.78 : 0.54),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey(keyValue),
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: enabled ? AppColors.ink : AppColors.muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    _FoodToolBadge(label: badge!),
                  ] else
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodToolInfoCard extends StatelessWidget {
  const _FoodToolInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.70),
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
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

class _FoodToolBadge extends StatelessWidget {
  const _FoodToolBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _FoodTodayLogsSheet extends StatelessWidget {
  const _FoodTodayLogsSheet({required this.logs});

  final List<FoodLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    final total = logs.fold(0, (value, entry) => value + entry.calories);

    return InfoSheetFrame(
      title: '今日记录',
      child: logs.isEmpty
          ? const _FoodToolInfoCard(
              icon: Icons.receipt_long_rounded,
              title: '还没有饮食记录',
              value: '先记录最近一餐',
              subtitle: '记录后这里会显示食物、餐次和热量',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FoodToolInfoCard(
                  icon: Icons.local_fire_department_rounded,
                  title: '今日合计',
                  value: '$total kcal',
                  subtitle: '共 ${logs.length} 条饮食记录',
                ),
                const SizedBox(height: 8),
                ...logs.reversed.map(
                  (entry) => _FoodTodayLogTile(entry: entry),
                ),
              ],
            ),
    );
  }
}

class _FoodTodayLogTile extends StatelessWidget {
  const _FoodTodayLogTile({required this.entry});

  final FoodLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.74),
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Text(entry.food.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${entry.meal} · ${entry.food.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${entry.calories} kcal',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
