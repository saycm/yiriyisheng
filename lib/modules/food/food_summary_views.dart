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
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: meals.map((meal) {
          final selected = activeMeal == meal;
          final calories = caloriesByMeal[meal] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              key: ValueKey('food_meal_$meal'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(meal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 88,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        fontSize: 14,
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
                        fontSize: 11,
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

    return Container(
      key: const ValueKey('food_calorie_progress_card'),
      padding: const EdgeInsets.all(16),
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
                  '今日热量',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$consumed / $suggested kcal',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.toDouble(),
              minHeight: 10,
              backgroundColor: AppColors.background,
              color: consumed > suggested
                  ? AppColors.financeRed
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
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
  final List<double> trend;
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
    return Container(
      key: const ValueKey('food_frequent_block'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
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
    );
  }
}

class _FoodFrequentBlock extends StatelessWidget {
  const _FoodFrequentBlock({required this.items});

  final List<({String name, int count, int calories})> items;

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

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final average = values.isEmpty
        ? 0
        : values.fold<double>(0, (sum, value) => sum + value) / values.length;

    return Container(
      key: const ValueKey('food_trend_block'),
      height: 142,
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
                  '7 天热量趋势',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '均值 ${average.round()}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CustomPaint(
              painter: TinyBarsPainter(
                values: values,
                color: AppColors.success,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}
