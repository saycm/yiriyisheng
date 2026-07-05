// 中文注释：锻炼模块源码，负责动作库、训练计划、训练记录和更多菜单。

part of 'workout.dart';

enum _WorkoutPlanIntensity { light, medium, heavy }

extension _WorkoutPlanIntensityX on _WorkoutPlanIntensity {
  String get label {
    switch (this) {
      case _WorkoutPlanIntensity.light:
        return '轻度';
      case _WorkoutPlanIntensity.medium:
        return '中度';
      case _WorkoutPlanIntensity.heavy:
        return '重度';
    }
  }

  String get hint {
    switch (this) {
      case _WorkoutPlanIntensity.light:
        return '恢复或状态一般时';
      case _WorkoutPlanIntensity.medium:
        return '默认推荐训练量';
      case _WorkoutPlanIntensity.heavy:
        return '状态好时完整训练';
    }
  }
}

const _defaultPlanIntensityActions =
    <String, Map<_WorkoutPlanIntensity, List<String>>>{
  'plan-chest-back': {
    _WorkoutPlanIntensity.light: ['坐姿绳索划船', '弹力带拉开', '俯卧 Y-T-W'],
    _WorkoutPlanIntensity.medium: ['器械推胸', '宽握高位下拉', '坐姿绳索划船', '弹力带拉开'],
  },
  'plan-leg-stability': {
    _WorkoutPlanIntensity.light: ['臀桥', '弹力带侧走', '站姿提踵'],
    _WorkoutPlanIntensity.medium: ['杠铃深蹲', '罗马尼亚硬拉', '臀桥', '弹力带侧走'],
  },
  'plan-core-recovery': {
    _WorkoutPlanIntensity.light: ['死虫', '鸟狗', '儿童式放松'],
    _WorkoutPlanIntensity.medium: ['死虫', '鸟狗', 'Pallof 抗旋转推', '胸椎旋转'],
  },
  'plan-quick-ten': {
    _WorkoutPlanIntensity.light: ['上斜俯卧撑', '平板触肩', '胸椎旋转'],
    _WorkoutPlanIntensity.medium: ['上斜俯卧撑', '箱式深蹲', '平板触肩', '低冲击开合步', '胸椎旋转'],
  },
  'plan-beginner-full-body': {
    _WorkoutPlanIntensity.light: ['高脚杯深蹲', '哑铃地板卧推', '鸟狗'],
    _WorkoutPlanIntensity.medium: ['高脚杯深蹲', '哑铃地板卧推', '反向划船', '鸟狗'],
  },
  'plan-desk-shoulder-reset': {
    _WorkoutPlanIntensity.light: ['下巴回收', '墙滑', '胸椎旋转'],
    _WorkoutPlanIntensity.medium: ['墙滑', '下巴回收', '弹力带外展拉开', '胸椎旋转'],
  },
  'plan-low-impact-conditioning': {
    _WorkoutPlanIntensity.light: ['坡度快走', '低冲击开合步', '儿童式放松'],
    _WorkoutPlanIntensity.medium: ['坡度快走', '农夫行走', '低冲击开合步', '儿童式放松'],
  },
};

class _WorkoutPlanVariant {
  const _WorkoutPlanVariant({
    required this.plan,
    required this.intensity,
    required this.actions,
  });

  final WorkoutPlan plan;
  final _WorkoutPlanIntensity intensity;
  final List<WorkoutAction> actions;

  int get estimatedMinutes {
    final ratio = switch (intensity) {
      _WorkoutPlanIntensity.light => 0.45,
      _WorkoutPlanIntensity.medium => 0.75,
      _WorkoutPlanIntensity.heavy => 1.0,
    };
    return math.max(8, (plan.estimatedMinutes * ratio).round());
  }

  int get totalGroups =>
      actions.fold(0, (total, action) => total + action.groups);

  String get sessionName => _workoutSessionName(plan.name, intensity);
}

String _workoutSessionName(
  String planName,
  _WorkoutPlanIntensity intensity,
) {
  for (final item in _WorkoutPlanIntensity.values) {
    if (planName.endsWith(' · ${item.label}')) {
      return planName;
    }
  }
  return '$planName · ${intensity.label}';
}

_WorkoutPlanIntensity _workoutIntensityFromSessionName(String planName) {
  for (final intensity in _WorkoutPlanIntensity.values) {
    if (planName.endsWith(' · ${intensity.label}')) {
      return intensity;
    }
  }
  return _WorkoutPlanIntensity.medium;
}

_WorkoutPlanVariant _workoutPlanVariant(
  WorkoutPlan plan,
  List<WorkoutAction> actions,
  _WorkoutPlanIntensity intensity,
) {
  return _WorkoutPlanVariant(
    plan: plan,
    intensity: intensity,
    actions: _workoutPlanActionsForIntensity(plan, actions, intensity),
  );
}

List<WorkoutAction> _workoutPlanActionsForIntensity(
  WorkoutPlan plan,
  List<WorkoutAction> actions,
  _WorkoutPlanIntensity intensity,
) {
  final plannedActions = actions
      .where((action) => plan.actionNames.contains(action.name))
      .toList();
  if (plannedActions.isEmpty) {
    return const [];
  }
  final selectedNames = _defaultPlanIntensityActions[plan.id]?[intensity] ??
      _fallbackIntensityActionNames(plan.actionNames, intensity);
  final selected = <WorkoutAction>[];
  for (final name in selectedNames) {
    if (!plan.actionNames.contains(name)) {
      continue;
    }
    for (final action in actions) {
      if (action.name == name && !selected.contains(action)) {
        selected.add(action);
        break;
      }
    }
  }
  if (selected.isEmpty) {
    return plannedActions;
  }
  return selected;
}

List<String> _fallbackIntensityActionNames(
  List<String> actionNames,
  _WorkoutPlanIntensity intensity,
) {
  final targetCount = switch (intensity) {
    _WorkoutPlanIntensity.light => math.min(3, actionNames.length),
    _WorkoutPlanIntensity.medium => math.min(4, actionNames.length),
    _WorkoutPlanIntensity.heavy => actionNames.length,
  };
  return actionNames.take(targetCount).toList();
}

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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        _WorkoutTemplateRail(
          plans: plans,
          actions: actions,
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
    final recommended = _workoutPlanVariant(
      plan,
      actions,
      _WorkoutPlanIntensity.medium,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        key: ValueKey('workout_plan_${plan.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assignment_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.name,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _WorkoutPlanLoadTag(label: recommended.intensity.label),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.target,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _WorkoutPlanMiniMeta(
                          label: '${recommended.estimatedMinutes} 分钟',
                        ),
                        _WorkoutPlanMiniMeta(
                          label: '${recommended.actions.length} 动作',
                        ),
                        _WorkoutPlanMiniMeta(
                          label: '${recommended.totalGroups} 组',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutPlanLoadTag extends StatelessWidget {
  const _WorkoutPlanLoadTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorkoutPlanMiniMeta extends StatelessWidget {
  const _WorkoutPlanMiniMeta({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
    final actionCount = session.actionProgress.length;

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

class _WorkoutPlanIntensitySelector extends StatelessWidget {
  const _WorkoutPlanIntensitySelector({
    required this.selected,
    required this.onChanged,
  });

  final _WorkoutPlanIntensity selected;
  final ValueChanged<_WorkoutPlanIntensity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _WorkoutPlanIntensity.values.map((intensity) {
        final active = intensity == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              key: ValueKey('workout_intensity_${intensity.name}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(intensity),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.primarySoft : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.line,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      intensity.label,
                      style: TextStyle(
                        color: active ? AppColors.primary : AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      intensity.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WorkoutPlanDetailSheet extends StatefulWidget {
  const _WorkoutPlanDetailSheet({
    required this.plan,
    required this.actions,
    required this.onEdit,
    required this.onStart,
  });

  final WorkoutPlan plan;
  final List<WorkoutAction> actions;
  final VoidCallback onEdit;
  final ValueChanged<_WorkoutPlanIntensity> onStart;

  @override
  State<_WorkoutPlanDetailSheet> createState() =>
      _WorkoutPlanDetailSheetState();
}

class _WorkoutPlanDetailSheetState extends State<_WorkoutPlanDetailSheet> {
  _WorkoutPlanIntensity _intensity = _WorkoutPlanIntensity.medium;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    final variant = _workoutPlanVariant(
      widget.plan,
      widget.actions,
      _intensity,
    );
    final hasActions = variant.actions.isNotEmpty;

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
        child: SingleChildScrollView(
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
                      widget.plan.name,
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
              _WorkoutPlanIntensitySelector(
                selected: _intensity,
                onChanged: (value) => setState(() => _intensity = value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _WorkoutPlanInfoPill(label: '${variant.actions.length} 个动作'),
                  _WorkoutPlanInfoPill(label: '${variant.totalGroups} 组'),
                  _WorkoutPlanInfoPill(label: '${variant.estimatedMinutes} 分钟'),
                  _WorkoutPlanInfoPill(label: widget.plan.target),
                ],
              ),
              const SizedBox(height: 16),
              ...variant.actions.map(
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
                  onPressed: widget.onEdit,
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
                  onPressed:
                      hasActions ? () => widget.onStart(_intensity) : null,
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
    required this.actions,
    required this.onOpenPlan,
  });

  final List<WorkoutPlan> plans;
  final List<WorkoutAction> actions;
  final ValueChanged<WorkoutPlan> onOpenPlan;

  @override
  Widget build(BuildContext context) {
    const templates = [
      (
        'plan-chest-back',
        '胸背日',
        Icons.accessibility_new_rounded,
        AppColors.primary,
        ''
      ),
      (
        'plan-core-recovery',
        '核心日',
        Icons.self_improvement_rounded,
        AppColors.success,
        ''
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
              final summary =
                  plan == null ? item.$5 : _templateSummary(plan, item.$5);
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
                                summary,
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

  String _templateSummary(WorkoutPlan plan, String fallback) {
    if (fallback.isNotEmpty) {
      return fallback;
    }
    final variant = _workoutPlanVariant(
      plan,
      actions,
      _WorkoutPlanIntensity.medium,
    );
    if (variant.actions.isEmpty) {
      return fallback;
    }
    return '${variant.intensity.label} · ${variant.actions.length} 动作 · ${variant.totalGroups} 组';
  }
}
