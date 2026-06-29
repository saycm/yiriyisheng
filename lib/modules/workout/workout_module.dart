part of '../../main.dart';

class WorkoutAction {
  const WorkoutAction({
    required this.name,
    required this.detail,
    required this.imageAsset,
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
  final String imageAsset;
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
    required this.moduleNav,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.finishedGroupsByAction,
    required this.onUpdateActionGroups,
    required this.workoutPlans,
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
  static const _actions = [
    WorkoutAction(
      name: '蝴蝶机夹胸',
      detail: '4组 × 8次 × 30kg',
      imageAsset: 'assets/workout/actions/chest_butterfly_machine.png',
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
      imageAsset: 'assets/workout/actions/chest_wide_lat_pulldown.png',
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
      imageAsset: 'assets/workout/actions/chest_machine_press.png',
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
      imageAsset: 'assets/workout/actions/chest_seated_cable_row.png',
      icon: Icons.rowing_rounded,
      groups: 4,
      status: '未开始',
      bodyPart: '胸背',
      reps: '12次',
      weight: '30kg',
      note: '先收肩胛再拉手柄。',
    ),
    WorkoutAction(
        name: '上斜哑铃卧推',
        detail: '4组 × 10次 × 16kg',
        imageAsset: 'assets/workout/actions/chest_incline_dumbbell_press.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '胸背',
        reps: '10次',
        weight: '16kg',
        note: '肩胛微收，手腕保持中立。'),
    WorkoutAction(
        name: '单臂哑铃划船',
        detail: '4组 × 10次 × 18kg',
        imageAsset: 'assets/workout/actions/chest_one_arm_dumbbell_row.png',
        icon: Icons.rowing_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '胸背',
        reps: '10次',
        weight: '18kg',
        note: '手肘贴近身体，顶端停顿半秒。'),
    WorkoutAction(
        name: '俯身杠铃划船',
        detail: '4组 × 8次 × 35kg',
        imageAsset: 'assets/workout/actions/chest_barbell_bent_over_row.png',
        icon: Icons.fitness_center_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '胸背',
        reps: '8次',
        weight: '35kg',
        note: '髋部后坐，脊柱保持中立。'),
    WorkoutAction(
        name: '哑铃侧平举',
        detail: '3组 × 15次 × 6kg',
        imageAsset:
            'assets/workout/actions/shoulder_dumbbell_lateral_raise.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '15次',
        weight: '6kg',
        note: '手肘微屈，抬到与肩平。'),
    WorkoutAction(
        name: '哑铃前平举',
        detail: '3组 × 12次 × 6kg',
        imageAsset: 'assets/workout/actions/shoulder_dumbbell_front_raise.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '12次',
        weight: '6kg',
        note: '核心收紧，避免借力摆动。'),
    WorkoutAction(
        name: '站姿推举',
        detail: '3组 × 10次 × 20kg',
        imageAsset:
            'assets/workout/actions/shoulder_standing_overhead_press.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '10次',
        weight: '20kg',
        note: '收紧臀腹，推起时头部轻微前穿。'),
    WorkoutAction(
        name: '绳索面拉',
        detail: '3组 × 15次 × 15kg',
        imageAsset: 'assets/workout/actions/shoulder_cable_face_pull.png',
        icon: Icons.fitness_center_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '15次',
        weight: '15kg',
        note: '拉向眉心，外旋打开肩关节。'),
    WorkoutAction(
        name: '俯身反向飞鸟',
        detail: '3组 × 12次 × 5kg',
        imageAsset: 'assets/workout/actions/shoulder_reverse_fly.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '12次',
        weight: '5kg',
        note: '保持胸椎延展，动作幅度稳定。'),
    WorkoutAction(
        name: '哑铃耸肩',
        detail: '3组 × 15次 × 20kg',
        imageAsset: 'assets/workout/actions/shoulder_dumbbell_shrug.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '15次',
        weight: '20kg',
        note: '肩膀向上向后提，避免颈部前探。'),
    WorkoutAction(
        name: '弹力带外旋',
        detail: '3组 × 15次',
        imageAsset:
            'assets/workout/actions/shoulder_band_external_rotation.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '15次',
        note: '上臂贴肋骨，缓慢打开前臂。'),
    WorkoutAction(
      name: '平板支撑',
      detail: '3组 × 60s',
      imageAsset: 'assets/workout/actions/core_plank.png',
      icon: Icons.self_improvement_rounded,
      groups: 3,
      status: '未开始',
      bodyPart: '核心',
      reps: '60s',
      note: '保持骨盆中立，不塌腰。',
    ),
    WorkoutAction(
        name: '死虫',
        detail: '3组 × 12次',
        imageAsset: 'assets/workout/actions/core_dead_bug.png',
        icon: Icons.self_improvement_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '12次',
        note: '腰背贴地，手脚对侧交替伸展。'),
    WorkoutAction(
        name: '俄罗斯转体',
        detail: '3组 × 20次',
        imageAsset: 'assets/workout/actions/core_russian_twist.png',
        icon: Icons.rotate_right_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '20次',
        note: '躯干整体转动，避免只甩手。'),
    WorkoutAction(
        name: '仰卧举腿',
        detail: '3组 × 12次',
        imageAsset: 'assets/workout/actions/core_leg_raise.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '12次',
        note: '下放时控制速度，腰部不过度离地。'),
    WorkoutAction(
        name: '卷腹触膝',
        detail: '3组 × 15次',
        imageAsset: 'assets/workout/actions/core_crunch_knee_touch.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '15次',
        note: '呼气卷起，关注腹直肌发力。'),
    WorkoutAction(
        name: '登山跑',
        detail: '3组 × 30s',
        imageAsset: 'assets/workout/actions/core_mountain_climber.png',
        icon: Icons.directions_run_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '30s',
        note: '肩在手腕正上方，膝盖快速向胸前收。'),
    WorkoutAction(
        name: '侧桥',
        detail: '3组 × 45s',
        imageAsset: 'assets/workout/actions/core_side_plank.png',
        icon: Icons.self_improvement_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '45s',
        note: '耳肩髋踝保持一条直线。'),
    WorkoutAction(
        name: '杠铃深蹲',
        detail: '4组 × 8次 × 40kg',
        imageAsset: 'assets/workout/actions/legs_barbell_squat.png',
        icon: Icons.fitness_center_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '8次',
        weight: '40kg',
        note: '脚掌踩稳，膝盖方向跟脚尖一致。'),
    WorkoutAction(
        name: '保加利亚分腿蹲',
        detail: '4组 × 10次 × 12kg',
        imageAsset: 'assets/workout/actions/legs_bulgarian_split_squat.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '10次',
        weight: '12kg',
        note: '前脚发力起身，身体微微前倾。'),
    WorkoutAction(
        name: '罗马尼亚硬拉',
        detail: '4组 × 10次 × 35kg',
        imageAsset: 'assets/workout/actions/legs_romanian_deadlift.png',
        icon: Icons.fitness_center_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '10次',
        weight: '35kg',
        note: '髋部向后折叠，感受臀腿后侧拉伸。'),
    WorkoutAction(
        name: '臀桥',
        detail: '4组 × 12次 × 50kg',
        imageAsset: 'assets/workout/actions/legs_hip_thrust.png',
        icon: Icons.accessibility_new_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '12次',
        weight: '50kg',
        note: '顶峰停顿 1 秒，避免腰椎代偿。'),
    WorkoutAction(
        name: '腿举',
        detail: '4组 × 12次 × 120kg',
        imageAsset: 'assets/workout/actions/legs_leg_press.png',
        icon: Icons.directions_run_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '12次',
        weight: '120kg',
        note: '下放到大腿接近腹部，再平稳蹬起。'),
    WorkoutAction(
        name: '箱式登阶',
        detail: '4组 × 12次 × 10kg',
        imageAsset: 'assets/workout/actions/legs_box_step_up.png',
        icon: Icons.stairs_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '12次',
        weight: '10kg',
        note: '全脚掌踩稳箱面，起身时不蹬后腿。'),
    WorkoutAction(
        name: '坐姿腿屈伸',
        detail: '4组 × 15次 × 25kg',
        imageAsset: 'assets/workout/actions/legs_leg_extension.png',
        icon: Icons.chair_alt_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '15次',
        weight: '25kg',
        note: '顶峰绷紧股四头肌，回落不要砸重量。'),
    WorkoutAction(
        name: '跑步机慢跑',
        detail: '3组 × 6min',
        imageAsset: 'assets/workout/actions/cardio_treadmill_jog.png',
        icon: Icons.directions_run_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '6min',
        note: '保持均匀呼吸，步频稳定。'),
    WorkoutAction(
        name: '划船机冲刺',
        detail: '3组 × 500m',
        imageAsset: 'assets/workout/actions/cardio_rowing_sprint.png',
        icon: Icons.rowing_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '500m',
        note: '腿蹬、后仰、拉手顺序连贯。'),
    WorkoutAction(
        name: '动感单车',
        detail: '3组 × 8min',
        imageAsset: 'assets/workout/actions/cardio_spinning_bike.png',
        icon: Icons.pedal_bike_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '8min',
        note: '阻力保持中高强度，稳定踩踏。'),
    WorkoutAction(
        name: '椭圆机耐力',
        detail: '3组 × 10min',
        imageAsset: 'assets/workout/actions/cardio_elliptical_endurance.png',
        icon: Icons.directions_walk_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '10min',
        note: '肩颈放松，重心保持居中。'),
    WorkoutAction(
        name: '跳绳间歇',
        detail: '3组 × 90s',
        imageAsset: 'assets/workout/actions/cardio_jump_rope.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '90s',
        note: '手腕轻甩，脚尖轻快落地。'),
    WorkoutAction(
        name: '台阶机爬升',
        detail: '3组 × 5min',
        imageAsset: 'assets/workout/actions/cardio_stair_climber.png',
        icon: Icons.stairs_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '5min',
        note: '用臀腿发力，避免过度扶把。'),
    WorkoutAction(
        name: '波比跳',
        detail: '3组 × 12次',
        imageAsset: 'assets/workout/actions/cardio_burpee.png',
        icon: Icons.bolt_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '12次',
        note: '保持节奏，落地时屈膝缓冲。'),
    WorkoutAction(
        name: '站姿股四头肌拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_quad_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '膝盖并拢，骨盆轻轻后收。'),
    WorkoutAction(
        name: '坐姿腘绳肌拉伸',
        detail: '2组 × 30s',
        imageAsset: 'assets/workout/actions/stretch_hamstring_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s',
        note: '背部延展，髋部前倾找拉伸感。'),
    WorkoutAction(
        name: '跪姿髋屈肌拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_hip_flexor_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '后侧臀部收紧，骨盆保持正位。'),
    WorkoutAction(
        name: '胸大肌门框拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_doorway_chest_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '前臂贴门框，身体缓慢前移。'),
    WorkoutAction(
        name: '猫牛式伸展',
        detail: '2组 × 8次',
        imageAsset: 'assets/workout/actions/stretch_cat_cow.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '8次',
        note: '一呼一吸配合脊柱屈伸。'),
    WorkoutAction(
        name: '儿童式放松',
        detail: '2组 × 45s',
        imageAsset: 'assets/workout/actions/stretch_child_pose.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '45s',
        note: '坐向脚跟，肩背放松下沉。'),
    WorkoutAction(
        name: '肩颈侧屈拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_neck_side_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '肩膀向下放松，头部轻柔侧屈。'),
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

  WorkoutPlan? get _activePlan {
    final session = widget.activeWorkoutSession;
    if (session == null) return null;
    for (final plan in widget.workoutPlans) {
      if (plan.id == session.planId) return plan;
    }
    return null;
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
        child: Stack(
          children: [
            Column(
              children: [
                _WorkoutHeader(onOpenModules: widget.onOpenModules),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: widget.moduleNav,
                ),
                _WorkoutTopTabs(
                  selected: _selectedTopTab,
                  onChanged: (index) => setState(() => _selectedTopTab = index),
                ),
                Expanded(child: _buildWorkoutContent()),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: _moduleSwitchBarBottomGap),
                child: _WorkoutBottomNav(
                  selectedIndex: _selectedBottomTab,
                  onChanged: _handleBottomNav,
                  keyPrefix: 'workout_bottom_nav',
                ),
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
        totalGroups: _totalGroups,
        finishedGroups: _finishedGroupsTotal,
      );
    }
    if (_selectedTopTab == 3) {
      return const _WorkoutHistoryView();
    }
    final session = widget.activeWorkoutSession;
    final sourceActions = session == null
        ? _actions
        : _actions
            .where((action) => session.actionProgress.containsKey(action.name))
            .toList();
    final visibleActions = _activeBodyPart == '全部'
        ? sourceActions
        : sourceActions
            .where(
                (action) => _bodyPartLabel(action.bodyPart) == _activeBodyPart)
            .toList();
    final activePlan = _activePlan;

    return ListView(
      key: const ValueKey('workout_main_list'),
      padding: const EdgeInsets.fromLTRB(
          18, 18, 18, _moduleSwitchBarReservedHeight + 24),
      children: [
        if (session != null) ...[
          _WorkoutActivePlanBanner(plan: activePlan, session: session),
          const SizedBox(height: 14),
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
        ],
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
        if (session == null) ...[
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

  Future<void> _openPlanDetail(WorkoutPlan plan) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutPlanDetailSheet(
          plan: plan,
          actions: _actionsForPlan(plan),
          onStart: () {
            Navigator.of(context).pop();
            _startPlanTraining(plan);
          },
        );
      },
    );
  }

  void _startPlanTraining(WorkoutPlan plan) {
    final planActions = _actionsForPlan(plan);
    if (planActions.isEmpty) return;
    final progress = {for (final action in planActions) action.name: 0};
    final session = ActiveWorkoutSession(
      planId: plan.id,
      planName: plan.name,
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
          18, 18, 18, _moduleSwitchBarReservedHeight + 24),
      children: [
        const _WorkoutTemplateRail(),
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
    required this.onStart,
  });

  final WorkoutPlan plan;
  final List<WorkoutAction> actions;
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
                child: _WorkoutActionArt(
                  action: action,
                  size: 48,
                  radius: 8,
                ),
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

class _WorkoutActionArt extends StatelessWidget {
  const _WorkoutActionArt({
    required this.action,
    required this.size,
    required this.radius,
    this.iconSize = 28,
  });

  final WorkoutAction action;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: ValueKey('workout_action_art_${action.name}'),
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        action.imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) {
          return Center(
            child: Icon(action.icon, color: AppColors.primary, size: iconSize),
          );
        },
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
                        child: _WorkoutActionArt(
                          action: action,
                          size: 58,
                          radius: 8,
                          iconSize: 34,
                        ),
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
