// 中文注释：饮食模块源码，负责食物类目、餐次记录和营养汇总。

part of 'food.dart';

class _FoodMealSelector extends StatelessWidget {
  const _FoodMealSelector({
    required this.meals,
    required this.activeMeal,
    required this.caloriesByMeal,
    required this.onChanged,
  });

  final List<String> meals;
  final String activeMeal;
  final Map<String, int> caloriesByMeal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: meals.map((meal) {
          final selected = activeMeal == meal;
          final calories = caloriesByMeal[meal] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              key: ValueKey('food_meal_$meal'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(meal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 78,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.line,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      calories == 0 ? '待记录' : '$calories kcal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.86)
                            : AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FoodCalorieProgressCard extends StatelessWidget {
  const _FoodCalorieProgressCard({
    required this.consumed,
    required this.suggested,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int consumed;
  final int suggested;
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final progress = suggested <= 0 ? 0.0 : (consumed / suggested).clamp(0, 1);

    return KeyedSubtree(
      key: const ValueKey('food_calorie_progress_card'),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.82),
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '今日热量',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$consumed / $suggested kcal',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                minHeight: 8,
                backgroundColor: AppColors.background,
                color: consumed > suggested
                    ? AppColors.financeRed
                    : AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _FoodMacroPill(
                    label: '蛋白质',
                    value: '${protein.round()}g',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FoodMacroPill(
                    label: '碳水',
                    value: '${carbs.round()}g',
                    color: const Color(0xFFFFA14A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FoodMacroPill(
                    label: '脂肪',
                    value: '${fat.round()}g',
                    color: const Color(0xFFFF7A83),
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

class _FoodMacroPill extends StatelessWidget {
  const _FoodMacroPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodQuickSections extends StatelessWidget {
  const _FoodQuickSections({
    required this.logs,
    required this.templates,
    required this.reminders,
    required this.trend,
    required this.onRepeatLastMeal,
    required this.onUseTemplate,
  });

  final List<FoodLogEntry> logs;
  final List<_FoodMealTemplate> templates;
  final List<String> reminders;
  final List<_FoodTrendDay> trend;
  final VoidCallback onRepeatLastMeal;
  final ValueChanged<_FoodMealTemplate> onUseTemplate;

  @override
  Widget build(BuildContext context) {
    final frequent = _frequentFoods();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FoodSectionHeader(
          title: '快捷记录',
          actionLabel: logs.isEmpty ? '常吃组合' : '一键再吃',
          onAction: onRepeatLastMeal,
        ),
        const SizedBox(height: 10),
        if (frequent.isEmpty)
          const _FoodInfoBlock(
            icon: Icons.history_rounded,
            title: '常吃食物',
            subtitle: '记录后会自动按出现次数排序。',
          )
        else
          _FoodFrequentBlock(items: frequent),
        const SizedBox(height: 12),
        _FoodTemplateBlock(
          templates: templates,
          onUseTemplate: onUseTemplate,
        ),
        const SizedBox(height: 12),
        _FoodReminderBlock(reminders: reminders),
        const SizedBox(height: 12),
        _FoodTrendBlock(values: trend),
      ],
    );
  }

  List<({String name, int count, int calories})> _frequentFoods() {
    final counts = <String, ({int count, int calories})>{};
    for (final entry in logs) {
      final current = counts[entry.food.name] ?? (count: 0, calories: 0);
      counts[entry.food.name] = (
        count: current.count + 1,
        calories: current.calories + entry.calories,
      );
    }
    final result = counts.entries
        .map(
          (entry) => (
            name: entry.key,
            count: entry.value.count,
            calories: entry.value.calories,
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return result.take(3).toList();
  }
}

class _FoodTrendDay {
  const _FoodTrendDay({
    required this.label,
    required this.calories,
    required this.hasRecord,
    required this.isToday,
  });

  final String label;
  final int calories;
  final bool hasRecord;
  final bool isToday;
}

class _FoodSectionHeader extends StatelessWidget {
  const _FoodSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          key: const ValueKey('food_repeat_last_meal'),
          onPressed: onAction,
          icon: const Icon(Icons.replay_rounded, size: 18),
          label: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _FoodInfoBlock extends StatelessWidget {
  const _FoodInfoBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('food_frequent_block'),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
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
                    subtitle,
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

class _FoodFrequentBlock extends StatelessWidget {
  const _FoodFrequentBlock({required this.items});

  final List<({String name, int count, int calories})> items;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '常吃排行',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${item.count} 次 · ${item.calories} kcal',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _FoodTemplateBlock extends StatelessWidget {
  const _FoodTemplateBlock({
    required this.templates,
    required this.onUseTemplate,
  });

  final List<_FoodMealTemplate> templates;
  final ValueChanged<_FoodMealTemplate> onUseTemplate;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '餐次模板',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...templates.map(
            (template) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                key: ValueKey('food_template_${template.title}'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => onUseTemplate(template),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(template.icon, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.title,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${template.meal} · ${template.subtitle}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.add_circle_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodReminderBlock extends StatelessWidget {
  const _FoodReminderBlock({required this.reminders});

  final List<String> reminders;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text(
                '饮食提醒',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...reminders.map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminder,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

class _FoodTrendBlock extends StatelessWidget {
  const _FoodTrendBlock({required this.values});

  final List<_FoodTrendDay> values;

  @override
  Widget build(BuildContext context) {
    final recorded = values.where((day) => day.hasRecord).toList();
    final average = recorded.isEmpty
        ? 0
        : recorded.fold<int>(0, (sum, day) => sum + day.calories) /
            recorded.length;
    final maxCalories = recorded.fold<int>(
      0,
      (max, day) => day.calories > max ? day.calories : max,
    );
    final summary = recorded.isEmpty
        ? '暂无连续记录，先记录今天一餐'
        : '${recorded.length} 天有记录 · 最高 $maxCalories kcal';

    return KeyedSubtree(
      key: const ValueKey('food_trend_block'),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.82),
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 156,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '近 7 天摄入',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '均值 ${average.round()} kcal',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: values
                      .map(
                        (day) => Expanded(
                          child: _FoodTrendDayColumn(
                            day: day,
                            maxCalories: maxCalories,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary,
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
      ),
    );
  }
}

class _FoodTrendDayColumn extends StatelessWidget {
  const _FoodTrendDayColumn({
    required this.day,
    required this.maxCalories,
  });

  final _FoodTrendDay day;
  final int maxCalories;

  @override
  Widget build(BuildContext context) {
    final ratio =
        !day.hasRecord || maxCalories <= 0 ? 0.0 : day.calories / maxCalories;
    final barHeight = day.hasRecord ? 18.0 + ratio * 52.0 : 12.0;
    final barColor = day.hasRecord
        ? (day.isToday ? AppColors.primary : AppColors.success)
        : AppColors.muted.withValues(alpha: 0.18);
    final labelColor = day.isToday ? AppColors.primary : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 24,
                height: barHeight,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: day.hasRecord ? 0.62 : 1),
                  borderRadius: BorderRadius.circular(999),
                  border: day.isToday
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.34),
                        )
                      : null,
                  boxShadow: day.isToday
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            day.label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            day.hasRecord ? '${day.calories}' : '未',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: day.hasRecord ? AppColors.ink : AppColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
