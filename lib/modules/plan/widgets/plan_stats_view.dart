part of '../../../main.dart';

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
    final actionable =
        todos.where((todo) => todo.status != TodoStatus.archived).toList();
    final total = actionable.length;
    final done = todos.where((todo) => todo.done).length;
    final percent = total == 0 ? 0 : (done * 100 / total).round();
    final postponed = todos
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
        : '饮食 $foodCalories kcal，锻炼 $workoutGroups 组，今天的计划可以按真实状态微调。';
    final moments = <(String, String)>[
      ('🍽️', '饮食模块今日已记录 $foodCalories kcal'),
      ('🏋️', '锻炼模块今日已完成 $workoutGroups 组'),
      ('📘', '$total 项任务已完成 $done 项，完成率 $percent%'),
      ('⏳', '${postponed.length} 项任务被延后过'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        _moduleSwitchBarReservedHeight + 88,
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
          delayedCategories: topDelayed.take(3).toList(),
        ),
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
          title: '这段时间的几个数字',
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
            const _NumberCard(
              icon: Icons.directions_walk_rounded,
              value: '20,885步',
              label: '总步数',
              color: Color(0xFF7D9CFF),
            ),
            const _NumberCard(
              icon: Icons.payments_rounded,
              value: '499.96元',
              label: '最大单笔',
              color: Color(0xFFE85C59),
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
    return _ModuleLinkedSummaryCard(
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
    required this.delayedCategories,
  });

  final int completedRate;
  final int postponedCount;
  final List<MapEntry<String, int>> delayedCategories;

  @override
  Widget build(BuildContext context) {
    final delayedText = delayedCategories.isEmpty
        ? '暂时没有明显拖延分类'
        : delayedCategories
            .map((entry) => '${entry.key} ${entry.value} 次')
            .join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
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
                  label: '拖延任务',
                  value: '$postponedCount 项',
                  icon: Icons.event_repeat_rounded,
                  color: AppColors.financeRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '常被延后的分类：$delayedText',
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

class _ModuleLinkedSummaryCard extends StatelessWidget {
  const _ModuleLinkedSummaryCard({
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
                  _LinkedValue(label: entry.$1, value: entry.$2),
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
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '联动记录',
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
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
                  '本周回顾',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
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
    return Container(
      constraints: const BoxConstraints(minHeight: 172),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
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
