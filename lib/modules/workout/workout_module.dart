part of '../../main.dart';

class WorkoutAction {
  const WorkoutAction({
    required this.name,
    required this.detail,
    required this.icon,
    required this.groups,
    required this.status,
    required this.bodyPart,
    required this.reps,
    this.weight,
    this.note = '',
  });

  final String name;
  final String detail;
  final IconData icon;
  final int groups;
  final String status;
  final String bodyPart;
  final String reps;
  final String? weight;
  final String note;
}

class WorkoutModulePage extends StatefulWidget {
  const WorkoutModulePage({
    super.key,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.finishedGroupsByAction,
    required this.onUpdateActionGroups,
    required this.foodCalories,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final Map<String, int> finishedGroupsByAction;
  final void Function(String actionName, int finishedGroups)
      onUpdateActionGroups;
  final int foodCalories;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<WorkoutModulePage> createState() => _WorkoutModulePageState();
}

class _WorkoutModulePageState extends State<WorkoutModulePage> {
  static const _actions = [
    WorkoutAction(
      name: '蝴蝶机夹胸',
      detail: '4组 × 8次 × 30kg',
      icon: Icons.accessibility_new_rounded,
      groups: 4,
      status: '未开始',
      bodyPart: '胸背',
      reps: '8次',
      weight: '30kg',
      note: '肩胛稳定，顶峰收缩 1 秒。',
    ),
    WorkoutAction(
      name: '宽握高位下拉',
      detail: '4组 × 12次 × 30kg',
      icon: Icons.fitness_center_rounded,
      groups: 4,
      status: '未开始',
      bodyPart: '胸背',
      reps: '12次',
      weight: '30kg',
      note: '下拉到锁骨，避免耸肩。',
    ),
    WorkoutAction(
      name: '器械推胸',
      detail: '4组 × 12次 × 20kg',
      icon: Icons.sports_gymnastics_rounded,
      groups: 4,
      status: '未开始',
      bodyPart: '胸背',
      reps: '12次',
      weight: '20kg',
      note: '推起呼气，回落控制。',
    ),
    WorkoutAction(
      name: '坐姿绳索划船',
      detail: '4组 × 12次 × 30kg',
      icon: Icons.rowing_rounded,
      groups: 4,
      status: '未开始',
      bodyPart: '胸背',
      reps: '12次',
      weight: '30kg',
      note: '先收肩胛再拉手柄。',
    ),
    WorkoutAction(
      name: '平板支撑',
      detail: '3组 × 60s',
      icon: Icons.self_improvement_rounded,
      groups: 3,
      status: '未开始',
      bodyPart: '核心',
      reps: '60s',
      note: '保持骨盆中立，不塌腰。',
    ),
  ];
  static const _bodyParts = ['全部', '胸背部', '肩颈', '核心', '腿臀', '有氧', '拉伸'];

  int _selectedTopTab = 0;
  int _selectedBottomTab = 1;
  WorkoutAction? _activeAction;
  int _handledQuickActionToken = 0;
  String _activeBodyPart = '全部';
  String _lastFeedback = '刚好';
  int _restSecondsLeft = 0;

  int get _totalGroups =>
      _actions.fold(0, (total, action) => total + action.groups);

  int get _finishedGroupsTotal => _actions.fold(
        0,
        (total, action) => total + _finishedGroupsFor(action),
      );

  int get _finishedActionCount => _actions
      .where((action) => _finishedGroupsFor(action) >= action.groups)
      .length;

  WorkoutAction get _nextAction => _actions.firstWhere(
        (action) => _finishedGroupsFor(action) < action.groups,
        orElse: () => _actions.last,
      );

  int _finishedGroupsFor(WorkoutAction action) =>
      widget.finishedGroupsByAction[action.name] ?? 0;

  String _bodyPartLabel(String bodyPart) => bodyPart == '胸背' ? '胸背部' : bodyPart;

  @override
  void initState() {
    super.initState();
    _maybeHandleQuickAction();
  }

  @override
  void didUpdateWidget(covariant WorkoutModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  void _maybeHandleQuickAction() {
    if (widget.quickAction != WidgetQuickAction.startWorkout ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 小组件“练一组”进入下一个待完成动作，仍由用户确认开始，避免误触直接改训练数据。
      setState(() => _activeAction = _nextAction);
      widget.onQuickActionHandled();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeAction != null) {
      return _WorkoutActionDetailPage(
        action: _activeAction!,
        finishedGroups: _finishedGroupsFor(_activeAction!),
        restSecondsLeft: _restSecondsLeft,
        feedback: _lastFeedback,
        onBack: () => setState(() => _activeAction = null),
        onStartGroup: _finishNextGroup,
        onFeedbackChanged: (feedback) =>
            setState(() => _lastFeedback = feedback),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _WorkoutHeader(onOpenModules: widget.onOpenModules),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WorkoutBottomNav(
                selectedIndex: _selectedBottomTab,
                onChanged: _handleBottomNav,
                keyPrefix: 'workout_bottom_nav',
              ),
            ),
            _WorkoutTopTabs(
              selected: _selectedTopTab,
              onChanged: (index) => setState(() => _selectedTopTab = index),
            ),
            Expanded(child: _buildWorkoutContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutContent() {
    if (_selectedTopTab == 1) {
      return const _WorkoutPlanView();
    }
    if (_selectedTopTab == 2) {
      return _WorkoutDataView(
        totalGroups: _totalGroups,
        finishedGroups: _finishedGroupsTotal,
      );
    }
    if (_selectedTopTab == 3) {
      return const _WorkoutHistoryView();
    }
    final visibleActions = _activeBodyPart == '全部'
        ? _actions
        : _actions
            .where(
                (action) => _bodyPartLabel(action.bodyPart) == _activeBodyPart)
            .toList();

    return ListView(
      key: const ValueKey('workout_main_list'),
      padding: const EdgeInsets.fromLTRB(
          18, 18, 18, _moduleSwitchBarReservedHeight + 24),
      children: [
        _WorkoutSummaryCard(
          finishedActions: _finishedActionCount,
          totalActions: _actions.length,
          finishedGroups: _finishedGroupsTotal,
          totalGroups: _totalGroups,
          nextActionName: _nextAction.name,
          onStart: () => setState(() => _activeAction = _nextAction),
        ),
        const SizedBox(height: 12),
        _ModuleLinkedSummaryCard(
          title: '锻炼联动',
          subtitle: '训练组数会同步到健康和计划，饮食摄入辅助安排强度。',
          icon: Icons.fitness_center_rounded,
          values: [
            ('饮食', '${widget.foodCalories} kcal'),
            ('已练', '$_finishedGroupsTotal 组'),
          ],
        ),
        const SizedBox(height: 12),
        _WorkoutBodyPartFilter(
          parts: _bodyParts,
          selected: _activeBodyPart,
          onChanged: (part) => setState(() => _activeBodyPart = part),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                '当前动作',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${visibleActions.length} 个动作',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visibleActions.isEmpty)
          const _WorkoutEmptyPartCard()
        else
          ...visibleActions.map(
            (action) => _WorkoutActionCard(
              action: action,
              finishedGroups: _finishedGroupsFor(action),
              onTap: () => setState(() {
                _activeAction = action;
              }),
            ),
          ),
        const SizedBox(height: 2),
        _WorkoutTodayStatsCard(
          finishedGroups: _finishedGroupsTotal,
          totalGroups: _totalGroups,
          feedback: _lastFeedback,
        ),
        const SizedBox(height: 12),
        _WorkoutFoodLinkCard(
          foodCalories: widget.foodCalories,
          onOpenFood: () => widget.onSwitchModule(LifeModule.food),
        ),
      ],
    );
  }

  void _finishNextGroup() {
    final action = _activeAction;
    if (action == null) {
      return;
    }
    final nextCount = math.min(action.groups, _finishedGroupsFor(action) + 1);
    widget.onUpdateActionGroups(action.name, nextCount);
    setState(() => _restSecondsLeft = nextCount >= action.groups ? 0 : 120);
  }

  void _handleBottomNav(int index) {
    if (index == 0) {
      widget.onSwitchModule(LifeModule.health);
      return;
    }
    if (index == 2) {
      widget.onSwitchModule(LifeModule.food);
      return;
    }
    setState(() => _selectedBottomTab = index);
  }
}

class _WorkoutHeader extends StatelessWidget {
  const _WorkoutHeader({required this.onOpenModules});

  final VoidCallback onOpenModules;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Row(
        children: [
          _IconBubble(
            icon: Icons.view_sidebar_rounded,
            color: const Color(0xFF91A3FF),
            onTap: onOpenModules,
          ),
          const Expanded(
            child: Center(
              child: Text(
                '锻炼',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _IconBubble(
            icon: Icons.more_horiz_rounded,
            color: AppColors.primary,
            onTap: () {},
          ),
        ],
      ),
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
    return const _EmptyCard(
      title: '这个部位今天没有动作',
      subtitle: '可以先切回全部动作，后续再把训练模板接入自定义计划。',
    );
  }
}

class _WorkoutPlanView extends StatelessWidget {
  const _WorkoutPlanView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          18, 18, 18, _moduleSwitchBarReservedHeight + 24),
      children: const [
        _WorkoutTemplateRail(),
        SizedBox(height: 12),
        _WorkoutPlanCard(
          title: '胸背强化',
          subtitle: '周一 / 周四 · 5 个动作',
          progress: '0/19 组',
          color: AppColors.primary,
        ),
        _WorkoutPlanCard(
          title: '腿部稳定',
          subtitle: '周二 · 4 个动作',
          progress: '0/16 组',
          color: AppColors.success,
        ),
        _WorkoutPlanCard(
          title: '核心恢复',
          subtitle: '周六 · 3 个动作',
          progress: '0/9 组',
          color: Color(0xFFFF9559),
        ),
      ],
    );
  }
}

class _WorkoutPlanCard extends StatelessWidget {
  const _WorkoutPlanCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
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
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
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
            progress,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutTemplateRail extends StatelessWidget {
  const _WorkoutTemplateRail();

  @override
  Widget build(BuildContext context) {
    const templates = [
      (
        '胸背日',
        Icons.accessibility_new_rounded,
        AppColors.primary,
        '5 动作 · 19 组'
      ),
      ('核心日', Icons.self_improvement_rounded, AppColors.success, '4 动作 · 12 组'),
      ('恢复日', Icons.spa_rounded, Color(0xFFFF9559), '拉伸 + 轻有氧'),
      ('快练 10 分钟', Icons.flash_on_rounded, Color(0xFF43C6C8), '碎片时间可做'),
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
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.$3.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.$2, color: item.$3, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$4,
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
        ],
      ),
    );
  }
}

class _WorkoutDataView extends StatelessWidget {
  const _WorkoutDataView({
    required this.totalGroups,
    required this.finishedGroups,
  });

  final int totalGroups;
  final int finishedGroups;

  @override
  Widget build(BuildContext context) {
    final minutes = finishedGroups * 2;
    final calories = 520 + finishedGroups * 18;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          18, 18, 18, _moduleSwitchBarReservedHeight + 24),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _WorkoutDataCard(
              icon: Icons.fitness_center_rounded,
              value: '$finishedGroups/$totalGroups',
              label: '已完成组数',
              color: AppColors.primary,
            ),
            _WorkoutDataCard(
              icon: Icons.timer_rounded,
              value: '$minutes min',
              label: '训练时长',
              color: const Color(0xFF43C6C8),
            ),
            _WorkoutDataCard(
              icon: Icons.local_fire_department_rounded,
              value: '$calories',
              label: '预估消耗 kcal',
              color: const Color(0xFFFF9559),
            ),
            const _WorkoutDataCard(
              icon: Icons.trending_up_rounded,
              value: '30kg',
              label: '今日最高重量',
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 170,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: _TinyBarsPainter(
              values: const [8, 10, 7, 12, 6, 14, 9, 13, 10, 11, 15, 12],
              color: AppColors.primary,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _WorkoutDataCard extends StatelessWidget {
  const _WorkoutDataCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 22,
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
    );
  }
}

class _WorkoutHistoryView extends StatelessWidget {
  const _WorkoutHistoryView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          18, 18, 18, _moduleSwitchBarReservedHeight + 24),
      children: const [
        _WorkoutCalendarCard(),
        SizedBox(height: 12),
        _WorkoutActionTrendCard(),
        SizedBox(height: 12),
        _WorkoutProgressTrendCard(),
        SizedBox(height: 12),
        _WorkoutHistoryTile(
          title: '胸背',
          subtitle: '5 个动作 · 19 组 · 18:05',
          status: '今天',
          color: AppColors.primary,
        ),
        _WorkoutHistoryTile(
          title: '肩颈恢复',
          subtitle: '3 个动作 · 9 组 · 24 min',
          status: '周三',
          color: AppColors.success,
        ),
        _WorkoutHistoryTile(
          title: '核心训练',
          subtitle: '4 个动作 · 12 组 · 31 min',
          status: '周一',
          color: Color(0xFFFF9559),
        ),
      ],
    );
  }
}

class _WorkoutCalendarCard extends StatelessWidget {
  const _WorkoutCalendarCard();

  @override
  Widget build(BuildContext context) {
    final days = [
      ('一', '12', true, AppColors.success),
      ('二', '13', false, AppColors.muted),
      ('三', '14', true, AppColors.primary),
      ('四', '15', false, AppColors.muted),
      ('五', '16', true, const Color(0xFFFF9559)),
      ('六', '17', true, AppColors.primary),
      ('日', '18', false, AppColors.muted),
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
            '训练日历',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            key: const ValueKey('workout_calendar_strip'),
            children: days
                .map(
                  (day) => Expanded(
                    child: _WorkoutCalendarDay(
                      week: day.$1,
                      date: day.$2,
                      trained: day.$3,
                      color: day.$4,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCalendarDay extends StatelessWidget {
  const _WorkoutCalendarDay({
    required this.week,
    required this.date,
    required this.trained,
    required this.color,
  });

  final String week;
  final String date;
  final bool trained;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          week,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                trained ? color.withValues(alpha: 0.14) : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: trained ? color.withValues(alpha: 0.35) : AppColors.line,
            ),
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                color: trained ? color : AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutActionTrendCard extends StatelessWidget {
  const _WorkoutActionTrendCard();

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
        children: const [
          Text(
            '动作历史曲线',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _WorkoutTrendRow(
            title: '蝴蝶机夹胸',
            subtitle: '最近 4 次',
            values: [24, 28, 30, 35],
            color: AppColors.primary,
          ),
          SizedBox(height: 10),
          _WorkoutTrendRow(
            title: '宽握高位下拉',
            subtitle: '最近 4 次',
            values: [26, 28, 30, 32],
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _WorkoutTrendRow extends StatelessWidget {
  const _WorkoutTrendRow({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.color,
  });

  final String title;
  final String subtitle;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce(math.max);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 116,
          height: 36,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values
                .map(
                  (value) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: FractionallySizedBox(
                        heightFactor: value / maxValue,
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _WorkoutProgressTrendCard extends StatelessWidget {
  const _WorkoutProgressTrendCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _WorkoutProgressTrendTile(
            title: '重量进步',
            value: '30kg → 35kg',
            subtitle: '蝴蝶机夹胸',
            icon: Icons.monitor_weight_rounded,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _WorkoutProgressTrendTile(
            title: '次数进步',
            value: '8次 → 12次',
            subtitle: '宽握高位下拉',
            icon: Icons.repeat_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _WorkoutProgressTrendTile extends StatelessWidget {
  const _WorkoutProgressTrendTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
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
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHistoryTile extends StatelessWidget {
  const _WorkoutHistoryTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, color: color),
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
                const SizedBox(height: 5),
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
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutActionCard extends StatelessWidget {
  const _WorkoutActionCard({
    required this.action,
    required this.finishedGroups,
    required this.onTap,
  });

  final WorkoutAction action;
  final int finishedGroups;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = finishedGroups >= action.groups;
    final started = finishedGroups > 0;
    final status = completed ? '已完成' : (started ? '进行中' : action.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      action.detail,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _WorkoutActionTag(
                            label: action.bodyPart == '胸背'
                                ? '胸背部'
                                : action.bodyPart),
                        _WorkoutActionTag(label: action.reps),
                        if (action.weight != null)
                          _WorkoutActionTag(label: action.weight!),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: completed ? AppColors.success : AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$finishedGroups/${action.groups} 组 ›',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutActionTag extends StatelessWidget {
  const _WorkoutActionTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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

class _WorkoutActionDetailPage extends StatelessWidget {
  const _WorkoutActionDetailPage({
    required this.action,
    required this.finishedGroups,
    required this.restSecondsLeft,
    required this.feedback,
    required this.onBack,
    required this.onStartGroup,
    required this.onFeedbackChanged,
  });

  final WorkoutAction action;
  final int finishedGroups;
  final int restSecondsLeft;
  final String feedback;
  final VoidCallback onBack;
  final VoidCallback onStartGroup;
  final ValueChanged<String> onFeedbackChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          key: const ValueKey('workout_action_detail_list'),
          padding: const EdgeInsets.fromLTRB(
              18, 10, 18, 112 + _moduleSwitchBarReservedHeight),
          children: [
            Row(
              children: [
                _IconBubble(
                  icon: Icons.arrow_back_ios_new_rounded,
                  color: AppColors.ink,
                  onTap: onBack,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      action.name,
                      style: const TextStyle(
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
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(action.icon,
                            color: AppColors.primary, size: 34),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.name,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              action.detail,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '未开始',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _WorkoutProgressBox(
                          label: '已完成',
                          value: '$finishedGroups/${action.groups}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WorkoutProgressBox(
                          label: '当前休息',
                          value: restSecondsLeft == 0
                              ? '未开始'
                              : _formatRest(restSecondsLeft),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(action.groups, (index) {
                      final done = index < finishedGroups;
                      return Expanded(
                        child: Container(
                          height: 12,
                          margin: EdgeInsets.only(
                            right: index == action.groups - 1 ? 0 : 7,
                          ),
                          decoration: BoxDecoration(
                            color: done
                                ? AppColors.primary
                                : const Color(0xFFDCE2EE),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '准备开始',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restSecondsLeft == 0
                        ? '开始后按组记录，完成一组会自动开启 2 分钟休息提醒。'
                        : '正在休息 ${_formatRest(restSecondsLeft)}，下一组准备好后继续。',
                    style: TextStyle(
                      color: restSecondsLeft == 0
                          ? AppColors.ink
                          : AppColors.primary,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: onStartGroup,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        '开始动作',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _WorkoutActionMetaCard(action: action),
            const SizedBox(height: 18),
            _WorkoutFeedbackCard(
              selected: feedback,
              onChanged: onFeedbackChanged,
            ),
            const SizedBox(height: 18),
            ...List.generate(action.groups, (index) {
              final done = index < finishedGroups;
              return _WorkoutSetCard(
                index: index + 1,
                done: done,
                detail: action.detail.replaceFirst('${action.groups}组 × ', ''),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatRest(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

class _WorkoutProgressBox extends StatelessWidget {
  const _WorkoutProgressBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutActionMetaCard extends StatelessWidget {
  const _WorkoutActionMetaCard({required this.action});

  final WorkoutAction action;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('部位', action.bodyPart),
      ('目标组数', '${action.groups} 组'),
      ('次数', action.reps),
      ('重量', action.weight ?? '自重'),
    ];

    return Container(
      key: const ValueKey('workout_feedback_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '动作字段',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: values.map((item) {
              return _WorkoutProgressBox(label: item.$1, value: item.$2);
            }).toList(),
          ),
          if (action.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              action.note,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkoutFeedbackCard extends StatelessWidget {
  const _WorkoutFeedbackCard({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = ['轻松', '刚好', '太累'];

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
          const Text(
            '训练反馈',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((option) {
              final active = selected == option;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option == options.last ? 0 : 8,
                  ),
                  child: ChoiceChip(
                    key: ValueKey('workout_feedback_$option'),
                    selected: active,
                    onSelected: (_) => onChanged(option),
                    label: Center(child: Text(option)),
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: active ? AppColors.primary : AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WorkoutSetCard extends StatelessWidget {
  const _WorkoutSetCard({
    required this.index,
    required this.done,
    required this.detail,
  });

  final int index;
  final bool done;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: done ? AppColors.primary : AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: done ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第 $index 组',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            done ? Icons.check_circle_rounded : Icons.expand_more_rounded,
            color: done ? AppColors.success : AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class _WorkoutBottomNav extends StatelessWidget {
  const _WorkoutBottomNav({
    required this.selectedIndex,
    required this.onChanged,
    required this.keyPrefix,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return _CapsuleNav(
      selectedIndex: selectedIndex,
      items: const [
        (Icons.monitor_heart_rounded, '总览'),
        (Icons.fitness_center_rounded, '锻炼'),
        (Icons.restaurant_rounded, '饮食'),
      ],
      onChanged: onChanged,
      softCompact: true,
      keyPrefix: keyPrefix,
    );
  }
}
