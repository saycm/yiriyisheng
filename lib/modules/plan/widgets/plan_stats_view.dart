// 中文注释：计划模块页面组件，负责今日总览、待办箱、周计划和统计视图。

part of '../plan.dart';

class _PlanStatsView extends StatelessWidget {
  const _PlanStatsView({
    required this.todos,
    required this.events,
    required this.foodCalories,
    required this.workoutGroups,
  });

  final List<TodoItem> todos;
  final List<LifeEvent> events;
  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart =
        today.subtract(Duration(days: today.weekday - DateTime.monday));
    final weekEnd = weekStart.add(const Duration(days: 7));
    bool isInWeek(DateTime? date) =>
        date != null && !date.isBefore(weekStart) && date.isBefore(weekEnd);
    final actionable = todos.where((todo) {
      if (todo.status == TodoStatus.archived) {
        return false;
      }
      return isInWeek(todo.dueDate) || isInWeek(todo.completedAt);
    }).toList();
    final total = actionable.length;
    final done = actionable.where((todo) => todo.done).length;
    final activeTodos = actionable.where((todo) => todo.isActive).toList();
    final allActiveTodos = todos.where((todo) => todo.isActive).toList();
    final overdueCount = allActiveTodos.where((todo) {
      final dueDate = todo.dueDate;
      return dueDate != null && dueDate.isBefore(today);
    }).length;
    final undatedCount =
        allActiveTodos.where((todo) => todo.dueDate == null).length;
    final percent = total == 0 ? 0 : (done * 100 / total).round();
    final postponed = actionable
        .where(
          (todo) =>
              todo.status == TodoStatus.postponed || todo.postponedCount > 0,
        )
        .toList();
    final delayedByCategory = <String, int>{};
    for (final todo in postponed) {
      delayedByCategory[todo.category] =
          (delayedByCategory[todo.category] ?? 0) + 1;
    }
    final topDelayed = delayedByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final linkedInsight = foodCalories == 0 && workoutGroups == 0
        ? '记录饮食和锻炼后，计划会自动把摄入、训练和待办放在一起复盘。'
        : '饮食 $foodCalories kcal，锻炼 $workoutGroups 组，下周计划可以按本周真实状态微调。';
    final nextWeekAdvice = _buildNextWeekAdvice(
      activeCount: activeTodos.length,
      postponedCount: postponed.length,
      overdueCount: overdueCount,
      undatedCount: undatedCount,
      foodCalories: foodCalories,
      workoutGroups: workoutGroups,
    );
    final moments = <(String, String)>[
      ('饮食', '本周已记录 $foodCalories kcal'),
      ('锻炼', '本周已完成 $workoutGroups 组'),
      ('计划', '$total 项任务已完成 $done 项，完成率 $percent%'),
      ('延后', '${postponed.length} 项任务被延后过'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        88,
      ),
      children: [
        _WeeklyProgressCard(
          percent: percent,
          done: done,
          total: total,
        ),
        const SizedBox(height: 16),
        _PlanLinkedReviewCard(
          foodCalories: foodCalories,
          workoutGroups: workoutGroups,
        ),
        const SizedBox(height: 16),
        _PlanReviewMetricsCard(
          completedRate: percent,
          postponedCount: postponed.length,
          activeCount: activeTodos.length,
          overdueCount: overdueCount,
          undatedCount: undatedCount,
          delayedCategories: topDelayed.take(3).toList(),
        ),
        const SizedBox(height: 16),
        _NextWeekAdviceCard(advices: nextWeekAdvice),
        const SizedBox(height: 16),
        _LifeEventFeedCard(events: events.take(4).toList()),
        const SizedBox(height: 16),
        const _ReviewSectionTitle(
          icon: Icons.auto_awesome_rounded,
          title: '被看见的瞬间',
        ),
        const SizedBox(height: 10),
        _MomentListCard(moments: moments),
        const SizedBox(height: 18),
        const _ReviewSectionTitle(
          icon: Icons.grid_view_rounded,
          title: '你这周的几个模式',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: _InsightCard(
                title: '拖延信号',
                body: '已延后的任务会继续留在周计划里，复盘时优先看是不是分类过载或日期安排太密。',
                icon: Icons.event_repeat_rounded,
                accent: Color(0xFF7F7AF7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InsightCard(
                title: '状态同步',
                body: linkedInsight,
                icon: Icons.hub_rounded,
                accent: Color(0xFF7D9CFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _ReviewSectionTitle(
          icon: Icons.layers_rounded,
          title: '这周真实数据',
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.58,
          children: [
            _NumberCard(
              icon: Icons.inbox_rounded,
              value: '$undatedCount 项',
              label: '待整理',
              color: const Color(0xFF7D9CFF),
            ),
            _NumberCard(
              icon: Icons.warning_amber_rounded,
              value: '$overdueCount 项',
              label: '逾期待排',
              color: AppColors.financeRed,
            ),
            _NumberCard(
              icon: Icons.local_fire_department_rounded,
              value: '$foodCalories kcal',
              label: '饮食摄入',
              color: const Color(0xFFB88955),
            ),
            _NumberCard(
              icon: Icons.fact_check_rounded,
              value: '$done 项',
              label: '完成任务',
              color: AppColors.primary,
            ),
            _NumberCard(
              icon: Icons.event_repeat_rounded,
              value: '${postponed.length} 项',
              label: '延后任务',
              color: AppColors.financeRed,
            ),
            _NumberCard(
              icon: Icons.fitness_center_rounded,
              value: '$workoutGroups 组',
              label: '锻炼完成',
              color: AppColors.success,
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanLinkedReviewCard extends StatelessWidget {
  const _PlanLinkedReviewCard({
    required this.foodCalories,
    required this.workoutGroups,
  });

  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    return ModuleLinkedSummaryCard(
      title: '计划联动',
      subtitle: '把饮食、锻炼和待办合成同一个本周复盘入口。',
      icon: Icons.hub_rounded,
      values: [
        ('饮食', '$foodCalories kcal'),
        ('锻炼', '$workoutGroups 组'),
      ],
    );
  }
}

class _PlanReviewMetricsCard extends StatelessWidget {
  const _PlanReviewMetricsCard({
    required this.completedRate,
    required this.postponedCount,
    required this.activeCount,
    required this.overdueCount,
    required this.undatedCount,
    required this.delayedCategories,
  });

  final int completedRate;
  final int postponedCount;
  final int activeCount;
  final int overdueCount;
  final int undatedCount;
  final List<MapEntry<String, int>> delayedCategories;

  @override
  Widget build(BuildContext context) {
    final delayedText = delayedCategories.isEmpty
        ? '暂时没有明显拖延分类'
        : delayedCategories
            .map((entry) => '${entry.key} ${entry.value} 次')
            .join(' · ');
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.query_stats_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                '复盘指标',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PlanMetricPill(
                  label: '完成率',
                  value: '$completedRate%',
                  icon: Icons.fact_check_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlanMetricPill(
                  label: '未完成',
                  value: '$activeCount 项',
                  icon: Icons.event_repeat_rounded,
                  color: AppColors.financeRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PlanMetricPill(
                  label: '延后任务',
                  value: '$postponedCount 项',
                  icon: Icons.low_priority_rounded,
                  color: const Color(0xFFFF9559),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlanMetricPill(
                  label: '待整理',
                  value: '$undatedCount 项',
                  icon: Icons.inbox_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '常被延后的分类：$delayedText；逾期待排 $overdueCount 项。',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextWeekAdviceCard extends StatelessWidget {
  const _NextWeekAdviceCard({required this.advices});

  final List<String> advices;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                '下周建议',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final advice in advices)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      advice,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
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

class _PlanMetricPill extends StatelessWidget {
  const _PlanMetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _LifeEventFeedCard extends StatelessWidget {
  const _LifeEventFeedCard({required this.events});

  final List<LifeEvent> events;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '最近联动记录',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Text(
              '完成待办、记录饮食或开始训练后，会在这里形成时间线。',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...List.generate(events.length, (index) {
              final event = events[index];
              return _LifeEventRow(
                event: event,
                showDivider: index != events.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _LifeEventRow extends StatelessWidget {
  const _LifeEventRow({
    required this.event,
    required this.showDivider,
  });

  final LifeEvent event;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(event.icon, color: event.color, size: 19),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.detail,
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
        if (showDivider) const Divider(height: 1, color: Color(0xFFE9ECF4)),
      ],
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({
    required this.percent,
    required this.done,
    required this.total,
  });

  final int percent;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.primarySoft,
                  color: AppColors.primary,
                ),
                Center(
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '本周复盘',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '已完成 $done 项，还有 ${total - done} 项待处理',
                  style: const TextStyle(
                    color: AppColors.muted,
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

class _ReviewSectionTitle extends StatelessWidget {
  const _ReviewSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MomentListCard extends StatelessWidget {
  const _MomentListCard({required this.moments});

  final List<(String, String)> moments;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(moments.length, (index) {
          final moment = moments[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Text(moment.$1, style: const TextStyle(fontSize: 21)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        moment.$2,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index != moments.length - 1)
                const Divider(height: 1, color: Color(0xFFE9ECF4)),
            ],
          );
        }),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 172),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                height: 1.45,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(icon, color: accent, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
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
    );
  }
}

List<String> _buildNextWeekAdvice({
  required int activeCount,
  required int postponedCount,
  required int overdueCount,
  required int undatedCount,
  required int foodCalories,
  required int workoutGroups,
}) {
  final advices = <String>[];
  if (undatedCount > 0) {
    advices.add('先把 $undatedCount 项待整理任务排进具体日期，待办箱不要长期堆着。');
  }
  if (overdueCount > 0) {
    advices.add('下周开始前先处理 $overdueCount 项逾期任务，能做就重排，低价值就归档。');
  }
  if (postponedCount > 0) {
    advices.add('有 $postponedCount 项任务被延后过，建议把低优先级事项集中放到周末或下周。');
  }
  if (activeCount >= 6) {
    advices.add('未完成任务偏多，下周每天最多安排 3 件核心事项，其他放入稍后处理。');
  }
  if (foodCalories == 0 || workoutGroups == 0) {
    advices.add('计划复盘已经接入饮食和锻炼，补记录后能更准确判断当天状态。');
  }
  if (advices.isEmpty) {
    advices.add('下周保持现在的节奏，继续用待办箱收集，用周计划分配每天负载。');
  }
  return advices.take(3).toList(growable: false);
}
