part of 'workout.dart';

class _WorkoutPlanView extends StatelessWidget {
  const _WorkoutPlanView({
    required this.plans,
    required this.actions,
    required this.onOpenPlan,
  });

  final List<WorkoutPlan> plans;
  final List<WorkoutAction> actions;
  final ValueChanged<WorkoutPlan> onOpenPlan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          18, 18, 18, moduleSwitchBarReservedHeight + 24),
      children: [
        _WorkoutTemplateRail(
          plans: plans,
          onOpenPlan: onOpenPlan,
        ),
        const SizedBox(height: 12),
        ...plans.map(
          (plan) => _WorkoutPlanCard(
            plan: plan,
            actions: actions,
            onTap: () => onOpenPlan(plan),
          ),
        ),
      ],
    );
  }
}

class _WorkoutPlanCard extends StatelessWidget {
  const _WorkoutPlanCard({
    required this.plan,
    required this.actions,
    required this.onTap,
  });

  final WorkoutPlan plan;
  final List<WorkoutAction> actions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    final totalGroups = plan.totalGroupsFrom(actions);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        key: ValueKey('workout_plan_${plan.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assignment_rounded, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${plan.target} · ${plan.actionNames.length} 个动作',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$totalGroups 组',
                style: const TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutActivePlanBanner extends StatelessWidget {
  const _WorkoutActivePlanBanner({
    required this.plan,
    required this.session,
  });

  final WorkoutPlan? plan;
  final ActiveWorkoutSession session;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    final actionCount =
        plan?.actionNames.length ?? session.actionProgress.length;

    return Container(
      key: const ValueKey('workout_active_plan_banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前计划',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.planName,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$actionCount 个动作',
            style: const TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutPlanDetailSheet extends StatelessWidget {
  const _WorkoutPlanDetailSheet({
    required this.plan,
    required this.actions,
    required this.onEdit,
    required this.onStart,
  });

  final WorkoutPlan plan;
  final List<WorkoutAction> actions;
  final VoidCallback onEdit;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    final hasActions = actions.isNotEmpty;
    final totalGroups = plan.totalGroupsFrom(actions);

    return SafeArea(
      child: Container(
        key: const ValueKey('workout_plan_detail_sheet'),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(8),
            bottom: Radius.circular(8),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_rounded, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _WorkoutPlanInfoPill(label: '${plan.actionNames.length} 个动作'),
                _WorkoutPlanInfoPill(label: '$totalGroups 组'),
                _WorkoutPlanInfoPill(label: plan.target),
              ],
            ),
            const SizedBox(height: 16),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center_rounded,
                        color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.name,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action.detail,
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
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text(
                  '编辑计划',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: hasActions ? onStart : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  '开始训练',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutPlanInfoPill extends StatelessWidget {
  const _WorkoutPlanInfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorkoutPlanEditSheet extends StatefulWidget {
  const _WorkoutPlanEditSheet({
    required this.plan,
    required this.allActions,
    required this.onChanged,
  });

  final WorkoutPlan plan;
  final List<WorkoutAction> allActions;
  final ValueChanged<WorkoutPlan> onChanged;

  @override
  State<_WorkoutPlanEditSheet> createState() => _WorkoutPlanEditSheetState();
}

class _WorkoutPlanEditSheetState extends State<_WorkoutPlanEditSheet> {
  late WorkoutPlan _plan = widget.plan;

  @override
  Widget build(BuildContext context) {
    final selectedActions = widget.allActions
        .where((action) => _plan.actionNames.contains(action.name))
        .toList();
    final availableActions = widget.allActions
        .where((action) => !_plan.actionNames.contains(action.name))
        .toList();

    return SafeArea(
      child: Container(
        key: const ValueKey('workout_plan_edit_sheet'),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _plan.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '已选动作',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  key: const ValueKey('workout_plan_selected_actions'),
                  children: selectedActions
                      .map(
                        (action) => _WorkoutPlanEditRow(
                          action: action,
                          icon: Icons.remove_circle_outline_rounded,
                          color: AppColors.financeRed,
                          keyValue: 'workout_plan_remove_${action.name}',
                          onTap: () => _removeAction(action),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '可添加动作',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: availableActions
                      .map(
                        (action) => _WorkoutPlanEditRow(
                          action: action,
                          icon: Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                          keyValue: 'workout_plan_add_${action.name}',
                          onTap: () => _addAction(action),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeAction(WorkoutAction action) {
    _save(
      _plan.copyWith(
        actionNames: _plan.actionNames
            .where((actionName) => actionName != action.name)
            .toList(),
      ),
    );
  }

  void _addAction(WorkoutAction action) {
    _save(_plan.copyWith(actionNames: [..._plan.actionNames, action.name]));
  }

  void _save(WorkoutPlan plan) {
    setState(() => _plan = plan);
    widget.onChanged(plan);
  }
}

class _WorkoutPlanEditRow extends StatelessWidget {
  const _WorkoutPlanEditRow({
    required this.action,
    required this.icon,
    required this.color,
    required this.keyValue,
    required this.onTap,
  });

  final WorkoutAction action;
  final IconData icon;
  final Color color;
  final String keyValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey(keyValue),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                action.reps,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutTemplateRail extends StatelessWidget {
  const _WorkoutTemplateRail({
    required this.plans,
    required this.onOpenPlan,
  });

  final List<WorkoutPlan> plans;
  final ValueChanged<WorkoutPlan> onOpenPlan;

  @override
  Widget build(BuildContext context) {
    const templates = [
      (
        'plan-chest-back',
        '胸背日',
        Icons.accessibility_new_rounded,
        AppColors.primary,
        '5 动作 · 19 组'
      ),
      (
        'plan-core-recovery',
        '核心日',
        Icons.self_improvement_rounded,
        AppColors.success,
        '4 动作 · 12 组'
      ),
      (
        'plan-core-recovery',
        '恢复日',
        Icons.spa_rounded,
        Color(0xFFFF9559),
        '拉伸 + 轻有氧'
      ),
      (
        'plan-quick-ten',
        '快练 10 分钟',
        Icons.flash_on_rounded,
        Color(0xFF43C6C8),
        '碎片时间可做'
      ),
    ];

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
            '训练模板',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...templates.map(
            (item) {
              final plan = _planById(item.$1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  key: ValueKey('workout_template_${item.$1}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: plan == null ? null : () => onOpenPlan(plan),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: item.$4.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.$3, color: item.$4, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.$5,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  WorkoutPlan? _planById(String id) {
    for (final plan in plans) {
      if (plan.id == id) {
        return plan;
      }
    }
    return null;
  }
}
