part of 'workout.dart';

class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({required this.onOpenModules});

  final VoidCallback onOpenModules;

  @override
  Widget build(BuildContext context) {
    return ModuleGlassHeader(
      module: LifeModule.workout,
      title: '锻炼',
      onOpenModules: onOpenModules,
      onOpenMore: () {},
    );
  }
}

class _WorkoutTopTabs extends StatelessWidget {
  const _WorkoutTopTabs({
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = ['训练', '计划', '数据', '历史'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final active = selected == index;
          return Expanded(
            child: InkWell(
              key: ValueKey('workout_top_tab_$index'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFFB8C0D9).withValues(alpha: 0.13),
                            blurRadius: 12,
                            offset: const Offset(0, 7),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? AppColors.ink : AppColors.muted,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WorkoutSummaryCard extends StatelessWidget {
  const _WorkoutSummaryCard({
    required this.finishedActions,
    required this.totalActions,
    required this.finishedGroups,
    required this.totalGroups,
    required this.nextActionName,
    required this.onStart,
  });

  final int finishedActions;
  final int totalActions;
  final int finishedGroups;
  final int totalGroups;
  final String nextActionName;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final minutes = finishedGroups * 2;

    return Container(
      key: const ValueKey('workout_summary_card'),
      padding: const EdgeInsets.all(14),
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
                  '胸背',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$finishedActions/$totalActions 个动作\n18:05',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            finishedGroups >= totalGroups ? '今日训练已完成' : '下一步：$nextActionName',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _WorkoutBadge(
                icon: Icons.check_circle_rounded,
                label: '$finishedGroups/$totalGroups 组',
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _WorkoutBadge(
                icon: Icons.timer_rounded,
                label: '$minutes min',
                color: const Color(0xFF43C6C8),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text(
                  '开始动作',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutBadge extends StatelessWidget {
  const _WorkoutBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutTodayStatsCard extends StatelessWidget {
  const _WorkoutTodayStatsCard({
    required this.finishedGroups,
    required this.totalGroups,
    required this.feedback,
  });

  final int finishedGroups;
  final int totalGroups;
  final String feedback;

  @override
  Widget build(BuildContext context) {
    final progress = totalGroups == 0
        ? 0.0
        : (finishedGroups / totalGroups).clamp(0, 1).toDouble();
    final sessions = finishedGroups == 0 ? 0 : 1;

    return Container(
      key: const ValueKey('workout_today_stats_card'),
      padding: const EdgeInsets.all(14),
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
                  '今日训练计划',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.background,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WorkoutMiniStat(
                  label: '本周次数',
                  value: '$sessions 次',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WorkoutMiniStat(
                  label: '本周总组数',
                  value: '$finishedGroups 组',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WorkoutMiniStat(
                  label: '反馈',
                  value: feedback,
                  color: const Color(0xFFFF9559),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutMiniStat extends StatelessWidget {
  const _WorkoutMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutFoodLinkCard extends StatelessWidget {
  const _WorkoutFoodLinkCard({
    required this.foodCalories,
    required this.onOpenFood,
  });

  final int foodCalories;
  final VoidCallback onOpenFood;

  @override
  Widget build(BuildContext context) {
    final message = foodCalories == 0 ? '训练后可以补一条加餐记录。' : '已记录摄入，可按训练强度补蛋白。';

    return Container(
      key: const ValueKey('workout_food_link_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu_rounded,
              color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('workout_open_food_link'),
            onPressed: onOpenFood,
            child: const Text(
              '记加餐',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutBodyPartFilter extends StatelessWidget {
  const _WorkoutBodyPartFilter({
    required this.parts,
    required this.selected,
    required this.onChanged,
  });

  final List<String> parts;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: parts.map((part) {
          final active = selected == part;
          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: InkWell(
              key: ValueKey('workout_body_part_$part'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(part),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.line,
                  ),
                ),
                child: Center(
                  child: Text(
                    part,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WorkoutEmptyPartCard extends StatelessWidget {
  const _WorkoutEmptyPartCard();

  @override
  Widget build(BuildContext context) {
    return const EmptyCard(
      title: '这个部位今天没有动作',
      subtitle: '可以先切回全部动作，或从训练模板选择一个计划。',
    );
  }
}
