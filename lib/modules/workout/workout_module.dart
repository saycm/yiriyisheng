// 中文注释：锻炼模块源码，负责动作库、训练计划、训练记录和更多菜单。

part of 'workout.dart';

class WorkoutModulePage extends StatefulWidget {
  const WorkoutModulePage({
    super.key,
    required this.moduleNav,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.finishedGroupsByAction,
    required this.onUpdateActionGroups,
    required this.workoutPlans,
    required this.onUpdateWorkoutPlan,
    required this.activeWorkoutSession,
    required this.workoutHistory,
    required this.onStartWorkoutSession,
    required this.onUpdateWorkoutSession,
    required this.onFinishWorkoutSession,
    required this.foodCalories,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final Widget moduleNav;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final Map<String, int> finishedGroupsByAction;
  final void Function(String actionName, int finishedGroups)
      onUpdateActionGroups;
  final List<WorkoutPlan> workoutPlans;
  final ValueChanged<WorkoutPlan> onUpdateWorkoutPlan;
  final ActiveWorkoutSession? activeWorkoutSession;
  final List<WorkoutHistoryEntry> workoutHistory;
  final ValueChanged<ActiveWorkoutSession> onStartWorkoutSession;
  final ValueChanged<ActiveWorkoutSession> onUpdateWorkoutSession;
  final ValueChanged<WorkoutHistoryEntry> onFinishWorkoutSession;
  final int foodCalories;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<WorkoutModulePage> createState() => _WorkoutModulePageState();
}

class _WorkoutModulePageState extends State<WorkoutModulePage> {
  static const _actions = defaultWorkoutActions;
  static const _bodyParts = defaultWorkoutBodyParts;

  int _selectedTopTab = 0;
  int _selectedBottomTab = 0;
  WorkoutAction? _activeAction;
  int _handledQuickActionToken = 0;
  String _activeBodyPart = '全部';
  String _lastFeedback = '刚好';
  bool _showOnlyUnfinished = false;
  bool _showActionLibrary = false;
  int _defaultRestSeconds = 120;
  int _restSecondsLeft = 0;
  Timer? _restTimer;

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

  WorkoutPlan? get _activePlan {
    final session = widget.activeWorkoutSession;
    if (session == null) return null;
    for (final plan in widget.workoutPlans) {
      if (plan.id == session.planId) return plan;
    }
    return null;
  }

  WorkoutPlan? get _recommendedPlan {
    for (final plan in widget.workoutPlans) {
      if (plan.id == 'plan-quick-ten') {
        return plan;
      }
    }
    return widget.workoutPlans.isEmpty ? null : widget.workoutPlans.first;
  }

  WorkoutAction get _nextActionForCurrentScope {
    final session = widget.activeWorkoutSession;
    if (session == null) {
      return _nextAction;
    }
    final scopedActions = _actions
        .where((action) => session.actionProgress.containsKey(action.name))
        .toList();
    if (scopedActions.isEmpty) {
      return _nextAction;
    }
    return scopedActions.firstWhere(
      (action) => _finishedGroupsFor(action) < action.groups,
      orElse: () => scopedActions.last,
    );
  }

  List<WorkoutAction> get _currentScopeActions {
    final session = widget.activeWorkoutSession;
    if (session == null) {
      return _actions;
    }
    // 有训练会话时，菜单统计和未完成过滤只看当前计划内的动作。
    return _actions
        .where((action) => session.actionProgress.containsKey(action.name))
        .toList();
  }

  int get _currentScopeTotalGroups => _currentScopeActions.fold(
        0,
        (total, action) => total + action.groups,
      );

  int get _currentScopeFinishedGroups => _currentScopeActions.fold(
        0,
        (total, action) => total + _finishedGroupsFor(action),
      );

  bool get _activePlanCompleted {
    final session = widget.activeWorkoutSession;
    if (session == null || session.actionProgress.isEmpty) {
      return false;
    }
    final plannedActions = _actions
        .where((action) => session.actionProgress.containsKey(action.name))
        .toList();
    if (plannedActions.isEmpty) {
      return false;
    }
    return plannedActions
        .every((action) => session.groupsFor(action.name) >= action.groups);
  }

  int _finishedGroupsFor(WorkoutAction action) {
    final session = widget.activeWorkoutSession;
    if (session != null && session.actionProgress.containsKey(action.name)) {
      return session.groupsFor(action.name);
    }
    return widget.finishedGroupsByAction[action.name] ?? 0;
  }

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

  @override
  void dispose() {
    _stopRestTimer();
    super.dispose();
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
      setState(() => _activeAction = _nextActionForCurrentScope);
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
            _WorkoutHeader(
              onOpenModules: widget.onOpenModules,
              onOpenMore: _openMoreSheet,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: widget.moduleNav,
            ),
            _WorkoutTopTabs(
              selected: _selectedTopTab,
              onChanged: (index) => setState(() => _selectedTopTab = index),
            ),
            Expanded(child: _buildWorkoutContent()),
            ModuleBottomNavSlot(
              child: WorkoutBottomNav(
                selectedIndex: _selectedBottomTab,
                onChanged: _handleBottomNav,
                keyPrefix: 'workout_bottom_nav',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutContent() {
    if (_selectedTopTab == 1) {
      return _WorkoutPlanView(
        plans: widget.workoutPlans,
        actions: _actions,
        onOpenPlan: _openPlanDetail,
      );
    }
    if (_selectedTopTab == 2) {
      return _WorkoutDataView(
        history: widget.workoutHistory,
        onOpenMetric: _openMetricDetail,
      );
    }
    if (_selectedTopTab == 3) {
      return _WorkoutHistoryView(
        history: widget.workoutHistory,
        onOpenHistory: _openHistoryDetail,
      );
    }
    final session = widget.activeWorkoutSession;
    final sourceActions = _currentScopeActions;
    final bodyPartActions = _activeBodyPart == '全部'
        ? sourceActions
        : sourceActions
            .where(
                (action) => _bodyPartLabel(action.bodyPart) == _activeBodyPart)
            .toList();
    final visibleActions = _showOnlyUnfinished
        ? bodyPartActions
            .where((action) => _finishedGroupsFor(action) < action.groups)
            .toList()
        : bodyPartActions;
    final actionCountLabel = _showOnlyUnfinished
        ? '未完成 ${visibleActions.length} / 全部 ${bodyPartActions.length}'
        : '${visibleActions.length} 个动作';
    final activePlan = _activePlan;
    final recommendedPlan = _recommendedPlan;
    final recommendedVariant = recommendedPlan == null
        ? null
        : _workoutPlanVariant(
            recommendedPlan,
            _actions,
            _WorkoutPlanIntensity.medium,
          );
    final showActionLibrary = session != null || _showActionLibrary;

    return ListView(
      key: const ValueKey('workout_main_list'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        if (session == null) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  '动作库',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showActionLibrary) ...[
                    Text(
                      actionCountLabel,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton.icon(
                    key: const ValueKey('workout_toggle_action_library'),
                    onPressed: () => setState(
                        () => _showActionLibrary = !_showActionLibrary),
                    icon: Icon(
                      _showActionLibrary
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                    ),
                    label: Text(_showActionLibrary ? '收起动作库' : '查看动作库'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (session != null) ...[
          _WorkoutActivePlanBanner(plan: activePlan, session: session),
          const SizedBox(height: 14),
          if (_activePlanCompleted) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _finishActivePlan,
                  child: const Text('完成训练'),
                ),
              ),
            ),
          ],
        ] else ...[
          _WorkoutSummaryCard(
            finishedActions: _finishedActionCount,
            totalActions: _actions.length,
            finishedGroups: _finishedGroupsTotal,
            totalGroups: _totalGroups,
            nextActionName: _nextActionForCurrentScope.name,
            onStart: () =>
                setState(() => _activeAction = _nextActionForCurrentScope),
          ),
          const SizedBox(height: 12),
          if (recommendedVariant != null) ...[
            _WorkoutTodayRecommendationCard(
              variant: recommendedVariant,
              onStart: () => _startPlanTraining(
                recommendedVariant.plan,
                intensity: recommendedVariant.intensity,
              ),
              onViewPlan: () => _openPlanDetail(recommendedVariant.plan),
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (session != null)
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
                actionCountLabel,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        if (showActionLibrary) ...[
          const SizedBox(height: 10),
          _WorkoutBodyPartFilter(
            parts: _bodyParts,
            selected: _activeBodyPart,
            onChanged: (part) => setState(() => _activeBodyPart = part),
          ),
          const SizedBox(height: 14),
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
        ],
        const SizedBox(height: 2),
        _WorkoutTodayStatsCard(
          finishedGroups: _finishedGroupsTotal,
          totalGroups: _totalGroups,
          feedback: _lastFeedback,
        ),
        if (session == null) ...[
          const SizedBox(height: 12),
          ModuleLinkedSummaryCard(
            title: '锻炼联动',
            subtitle: '训练组数会同步到健康和计划，饮食摄入辅助安排强度。',
            icon: Icons.fitness_center_rounded,
            values: [
              ('饮食', '${widget.foodCalories} kcal'),
              ('已练', '$_finishedGroupsTotal 组'),
            ],
          ),
          const SizedBox(height: 12),
          _WorkoutFoodLinkCard(
            foodCalories: widget.foodCalories,
            onOpenFood: () => widget.onSwitchModule(LifeModule.food),
          ),
        ],
      ],
    );
  }

  List<WorkoutAction> _actionsForPlan(WorkoutPlan plan) {
    return _actions
        .where((action) => plan.actionNames.contains(action.name))
        .toList();
  }

  WorkoutAction? _actionByName(String actionName) {
    for (final action in _actions) {
      if (action.name == actionName) {
        return action;
      }
    }
    return null;
  }

  Future<void> _openPlanDetail(WorkoutPlan plan) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutPlanDetailSheet(
          plan: plan,
          actions: _actionsForPlan(plan),
          onEdit: () {
            Navigator.of(context).pop();
            _openPlanEdit(plan);
          },
          onStart: (intensity) {
            Navigator.of(context).pop();
            _startPlanTraining(plan, intensity: intensity);
          },
        );
      },
    );
  }

  Future<void> _openMetricDetail(WorkoutMetricDetail detail) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutMetricDetailSheet(detail: detail);
      },
    );
  }

  Future<void> _openPlanEdit(WorkoutPlan plan) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutPlanEditSheet(
          plan: _latestPlan(plan),
          allActions: _actions,
          onChanged: widget.onUpdateWorkoutPlan,
        );
      },
    );
  }

  // 汇总当前训练状态，生成右上角“三点”菜单需要的启用/禁用状态。
  Future<void> _openMoreSheet() {
    final session = widget.activeWorkoutSession;
    final activePlan = _activePlan;
    final canFinishTraining = session != null &&
        session.actionProgress.values.any((groups) => groups > 0);
    final canResetProgress = widget.finishedGroupsByAction.values
            .any((groups) => groups > 0) ||
        (session?.actionProgress.values.any((groups) => groups > 0) ?? false);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutMoreSheet(
          hasActiveSession: session != null,
          canFinishTraining: canFinishTraining,
          canEditActivePlan: activePlan != null,
          canResetProgress: canResetProgress,
          hasHistory: widget.workoutHistory.isNotEmpty,
          showOnlyUnfinished: _showOnlyUnfinished,
          defaultRestSeconds: _defaultRestSeconds,
          finishedGroups: _currentScopeFinishedGroups,
          totalGroups: _currentScopeTotalGroups,
          historyCount: widget.workoutHistory.length,
          activePlanName: activePlan?.name ?? session?.planName,
          onContinueTraining: _continueOrStartTraining,
          onFinishTraining: _finishActivePlan,
          onShowOnlyUnfinishedChanged: _setShowOnlyUnfinished,
          onRestSecondsChanged: _setDefaultRestSeconds,
          onEditActivePlan: _editActivePlan,
          onCreatePlan: _createWorkoutPlan,
          onCopyActivePlan: _copyActivePlan,
          onResetProgress: _confirmResetTodayProgress,
          onExportHistory: _exportWorkoutHistory,
        );
      },
    );
  }

  // 无论当前在哪个 tab，都回到训练页并打开下一项可执行动作。
  void _continueOrStartTraining() {
    setState(() {
      _selectedTopTab = 0;
      _activeAction = _nextActionForCurrentScope;
    });
  }

  void _setShowOnlyUnfinished(bool value) {
    setState(() => _showOnlyUnfinished = value);
  }

  void _setDefaultRestSeconds(int seconds) {
    setState(() => _defaultRestSeconds = seconds);
  }

  void _startRestTimer() {
    _stopRestTimer();
    if (_restSecondsLeft <= 0) {
      return;
    }
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _stopRestTimer();
        return;
      }
      setState(() {
        _restSecondsLeft = math.max(0, _restSecondsLeft - 1);
        if (_restSecondsLeft == 0) {
          _stopRestTimer();
        }
      });
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
  }

  void _editActivePlan() {
    final plan = _activePlan;
    if (plan == null) {
      return;
    }
    _openPlanEdit(plan);
  }

  // 新建计划先创建空壳，再复用现有编辑 Sheet 选择动作。
  void _createWorkoutPlan() {
    final now = DateTime.now();
    final plan = WorkoutPlan(
      name: '自定义训练',
      target: '按当天状态自由组合',
      bodyParts: const [],
      actionNames: const [],
      estimatedMinutes: 20,
      createdAt: now,
      updatedAt: now,
    );
    widget.onUpdateWorkoutPlan(plan);
    _openPlanEdit(plan);
  }

  // 复制计划必须生成新 id，避免覆盖正在训练的原计划。
  void _copyActivePlan() {
    final plan = _activePlan;
    if (plan == null) {
      return;
    }
    final now = DateTime.now();
    final copy = WorkoutPlan(
      name: '${plan.name} 副本',
      target: plan.target,
      bodyParts: plan.bodyParts,
      actionNames: plan.actionNames,
      estimatedMinutes: plan.estimatedMinutes,
      createdAt: now,
      updatedAt: now,
    );
    widget.onUpdateWorkoutPlan(copy);
    _showWorkoutSnack('已复制训练计划');
  }

  // 重置今日进度是破坏性操作，先让用户二次确认。
  Future<void> _confirmResetTodayProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置今日进度'),
          content: const Text('会清空今天已记录的动作组数，训练历史不会删除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('重置'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      _resetTodayProgress();
    }
  }

  void _resetTodayProgress() {
    final session = widget.activeWorkoutSession;
    // 今日进度同时存在全局动作组数和当前训练会话里，重置时要两处保持一致。
    for (final action in _actions) {
      widget.onUpdateActionGroups(action.name, 0);
    }
    if (session != null) {
      widget.onUpdateWorkoutSession(
        session.copyWith(
          actionProgress: {
            for (final actionName in session.actionProgress.keys) actionName: 0,
          },
        ),
      );
    }
    setState(() {
      _activeAction = null;
      _restSecondsLeft = 0;
    });
    _stopRestTimer();
    _showWorkoutSnack('今日进度已重置');
  }

  // 第一版导出走剪贴板，避免提前引入文件权限和分享插件。
  Future<void> _exportWorkoutHistory() async {
    await Clipboard.setData(ClipboardData(text: _workoutHistoryExportText()));
    _showWorkoutSnack('训练历史已复制');
  }

  String _workoutHistoryExportText() {
    final buffer = StringBuffer('训练历史\n');
    for (final entry in widget.workoutHistory) {
      // 导出内容先做成可读文本，后续如果需要文件分享可以复用这份摘要。
      buffer
        ..writeln('\n${entry.planName}')
        ..writeln('开始：${_formatWorkoutDateTime(entry.startedAt)}')
        ..writeln('完成：${_formatWorkoutDateTime(entry.finishedAt)}')
        ..writeln('时长：${entry.durationMinutes} 分钟')
        ..writeln('总组数：${entry.totalGroups} 组')
        ..writeln('预估消耗：${entry.estimatedCalories} kcal')
        ..writeln('反馈：${entry.feedback}');
      for (final result in entry.actionResults) {
        buffer.writeln(
          '- ${result.actionName}：${result.finishedGroups}/${result.targetGroups} 组 · ${result.reps}',
        );
      }
    }
    return buffer.toString().trimRight();
  }

  String _formatWorkoutDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  void _showWorkoutSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  WorkoutPlan _latestPlan(WorkoutPlan plan) {
    return widget.workoutPlans.firstWhere(
      (item) => item.id == plan.id,
      orElse: () => plan,
    );
  }

  Future<void> _openHistoryDetail(WorkoutHistoryEntry entry) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutHistoryDetailSheet(
          entry: entry,
          onRestart: () {
            Navigator.of(context).pop();
            _restartPlanFromHistory(entry);
          },
        );
      },
    );
  }

  void _restartPlanFromHistory(WorkoutHistoryEntry entry) {
    final plan = widget.workoutPlans.firstWhere(
      (plan) => plan.id == entry.planId,
      orElse: () => WorkoutPlan(
        id: entry.planId,
        name: entry.planName,
        target: '再次训练',
        bodyParts: entry.actionResults
            .map((result) => _bodyPartLabel(result.bodyPart))
            .toSet()
            .toList(),
        actionNames:
            entry.actionResults.map((result) => result.actionName).toList(),
        estimatedMinutes: entry.durationMinutes,
      ),
    );
    _startPlanTraining(
      plan,
      intensity: _workoutIntensityFromSessionName(entry.planName),
    );
  }

  void _startPlanTraining(
    WorkoutPlan plan, {
    _WorkoutPlanIntensity intensity = _WorkoutPlanIntensity.medium,
  }) {
    final variant = _workoutPlanVariant(plan, _actions, intensity);
    final planActions = variant.actions;
    if (planActions.isEmpty) return;
    final progress = {for (final action in planActions) action.name: 0};
    final session = ActiveWorkoutSession(
      planId: plan.id,
      planName: variant.sessionName,
      startedAt: DateTime.now(),
      actionProgress: progress,
    );
    widget.onStartWorkoutSession(session);
    setState(() {
      _selectedTopTab = 0;
      _activeBodyPart = '全部';
      _activeAction = null;
    });
  }

  void _finishNextGroup() {
    final action = _activeAction;
    if (action == null) {
      return;
    }
    final currentGroups = _finishedGroupsFor(action);
    final nextCount = math.min(action.groups, currentGroups + 1);
    final session = widget.activeWorkoutSession;
    if (session != null && session.actionProgress.containsKey(action.name)) {
      final nextProgress = Map<String, int>.of(session.actionProgress);
      nextProgress[action.name] = nextCount;
      widget.onUpdateWorkoutSession(
        session.copyWith(
          actionProgress: nextProgress,
          feedback: _lastFeedback,
        ),
      );
    }
    widget.onUpdateActionGroups(action.name, nextCount);
    setState(() => _restSecondsLeft =
        nextCount >= action.groups ? 0 : _defaultRestSeconds);
    if (_restSecondsLeft == 0) {
      _stopRestTimer();
    } else {
      _startRestTimer();
    }
  }

  void _finishActivePlan() {
    final session = widget.activeWorkoutSession;
    if (session == null) {
      return;
    }
    final now = DateTime.now();
    final actionResults = <WorkoutActionResult>[];
    for (final actionName in session.actionProgress.keys) {
      final action = _actionByName(actionName);
      if (action == null) {
        continue;
      }
      actionResults.add(
        WorkoutActionResult(
          actionName: action.name,
          bodyPart: action.bodyPart,
          targetGroups: action.groups,
          finishedGroups: session.groupsFor(action.name),
          reps: action.reps,
          weight: action.weight,
        ),
      );
    }
    final totalGroups = actionResults.fold<int>(
      0,
      (total, result) => total + result.finishedGroups,
    );
    final entry = WorkoutHistoryEntry(
      planId: session.planId,
      planName: session.planName,
      startedAt: session.startedAt,
      finishedAt: now,
      durationMinutes: math.max(1, now.difference(session.startedAt).inMinutes),
      totalGroups: totalGroups,
      estimatedCalories: 80 + totalGroups * 18,
      actionResults: actionResults,
      feedback: _lastFeedback,
    );
    widget.onFinishWorkoutSession(entry);
    setState(() {
      _selectedTopTab = 3;
      _activeAction = null;
      _restSecondsLeft = 0;
    });
    _stopRestTimer();
  }

  void _handleBottomNav(int index) {
    setState(() => _selectedBottomTab = index);
  }
}
