// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

/// 首页根组件：承载五个生活模块，并管理模块切换、快捷动作和数据恢复。
class LifeHomePage extends StatefulWidget {
  const LifeHomePage({
    super.key,
    this.onSignOut,
    this.appDataStore,
    this.now,
  });

  final Future<void> Function()? onSignOut;
  final LifeSummaryStore? appDataStore;
  final DateTime Function()? now;

  @override
  State<LifeHomePage> createState() => _LifeHomePageState();
}

/// 首页状态：持有各模块的内存状态，处理生命周期、快捷动作和整体布局。
class _LifeHomePageState extends State<LifeHomePage>
    with WidgetsBindingObserver {
  static const _defaultAppDataStore = AppDataStore();
  static const _widgetStore = LifeWidgetStore();

  LifeModule _module = LifeModule.plan;
  WidgetQuickAction? _pendingQuickAction;
  int _quickActionToken = 0;
  bool _initialQuickActionChecked = false;
  final _foodState = _FoodHomeState();
  final _workoutState = _WorkoutHomeState();
  final _planState = _PlanHomeState();
  final _financeState = _FinanceHomeState();
  bool _appDataSaveFailed = false;
  bool _appDataLoadFailed = false;
  bool _appDataRestoreComplete = false;
  late DateTime _visibleDay;

  LifeSummaryStore get _appDataStore =>
      widget.appDataStore ?? _defaultAppDataStore;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    // 监听 App 前后台切换，跨天后刷新“今天”的显示。
    WidgetsBinding.instance.addObserver(this);
    _visibleDay = DateUtils.dateOnly(_now);
    final initialRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    // Android 桌面小组件会把目标模块和快捷动作写进初始路由，冷启动时直接落到对应操作。
    _module = _lifeModuleFromRoute(initialRoute);
    _widgetStore.setQuickActionHandler(_handleWidgetQuickAction);
    unawaited(_restoreAppData());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 回到前台且日期变化时，刷新可见日期并同步小组件摘要。
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }
    final currentDay = DateUtils.dateOnly(_now);
    if (DateUtils.isSameDay(currentDay, _visibleDay)) {
      return;
    }
    setState(() => _visibleDay = currentDay);
    _syncLinkedSummaryToWidget();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 首帧后检查初始路由里是否带小组件快捷动作（只处理一次）。
    if (_initialQuickActionChecked) {
      return;
    }
    _initialQuickActionChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final routeName = ModalRoute.of(context)?.settings.name ??
          WidgetsBinding.instance.platformDispatcher.defaultRouteName;
      final initialAction = _widgetQuickActionFromRoute(routeName);
      if (initialAction == null) {
        return;
      }
      setState(() {
        // 初始路由栈可能同时包含根页和目标页，只让当前可见页面消费桌面快捷动作。
        _pendingQuickAction = initialAction;
        _quickActionToken++;
      });
    });
  }

  void _setModule(LifeModule module) {
    // 切换底部模块，只改当前模块枚举，各模块状态仍保留在父级。
    setState(() => _module = module);
  }

  Future<void> _handleWidgetQuickAction(
      String route, String? actionName) async {
    // 桌面小组件点击时：先切模块，再投递一次性快捷动作。
    final action = _widgetQuickActionFromName(actionName);
    if (!mounted) {
      return;
    }
    setState(() {
      _module = _lifeModuleFromRoute(route);
      if (action != null) {
        // 小组件的快捷动作只消费一次，避免页面刷新时重复弹窗。
        _pendingQuickAction = action;
        _quickActionToken++;
      }
    });
  }

  void _markQuickActionHandled() {
    // 模块消费完快捷动作后清空，避免重复弹窗。
    if (!mounted || _pendingQuickAction == null) {
      return;
    }
    setState(() => _pendingQuickAction = null);
  }

  void _updateState(VoidCallback mutation) {
    setState(mutation);
  }

  int todayFoodCaloriesFromState(DateTime today) {
    return todayFoodCalories(_foodState.logs, today);
  }

  int weekFoodCaloriesFromState(DateTime today) {
    // 本周热量：从本周一到下周一之间的饮食记录累加。
    final start = _startOfWeek(today);
    final end = start.add(const Duration(days: 7));
    return _foodState.logs
        .where((entry) =>
            !entry.recordedAt.isBefore(start) && entry.recordedAt.isBefore(end))
        .fold(0, (total, entry) => total + entry.calories);
  }

  Map<String, int> todayWorkoutGroupsByActionFromState(DateTime today) {
    // 本地进度只在当天有效，跨天后归零。
    return isSameLocalDay(_workoutState.progressDate, today)
        ? _workoutState.groupsByAction
        : const <String, int>{};
  }

  int todayWorkoutGroupsFromState(DateTime today) {
    return todayWorkoutGroups(
      history: _workoutState.history,
      activeSession: _workoutState.activeSession,
      progressGroupsByAction: todayWorkoutGroupsByActionFromState(today),
      today: today,
    );
  }

  int weekWorkoutGroupsFromState(DateTime today) {
    final start = _startOfWeek(today);
    final end = start.add(const Duration(days: 7));
    var total = _workoutState.history
        .where((entry) =>
            !entry.finishedAt.isBefore(start) && entry.finishedAt.isBefore(end))
        .fold<int>(0, (sum, entry) => sum + entry.totalGroups);
    final activeSession = _workoutState.activeSession;
    if (activeSession != null &&
        !activeSession.startedAt.isBefore(start) &&
        activeSession.startedAt.isBefore(end)) {
      total += activeSession.actionProgress.values
          .fold<int>(0, (sum, groups) => sum + groups);
    }
    final progressDate = _workoutState.progressDate;
    if (progressDate != null &&
        !progressDate.isBefore(start) &&
        progressDate.isBefore(end)) {
      total += _workoutState.groupsByAction.values
          .fold<int>(0, (sum, groups) => sum + groups);
    }
    return total;
  }

  DateTime _startOfWeek(DateTime day) {
    // 以周一为一周起点。
    final date = DateUtils.dateOnly(day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  @override
  void dispose() {
    // 移除生命周期监听并注销小组件回调。
    WidgetsBinding.instance.removeObserver(this);
    _widgetStore.clearQuickActionHandler();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 汇总各模块的今日/本周统计后，构建当前模块页面。
    final today = _now;
    final todayFoodCalories = todayFoodCaloriesFromState(today);
    final todayWorkoutGroups = todayWorkoutGroupsFromState(today);
    final page = _buildLifeHomeModulePage(
      module: _module,
      onSwitchModule: _setModule,
      onOpenModules: _openModuleSheet,
      onOpenQuickRecord: _openQuickRecordSheet,
      currentDate: today,
      foodCalories: todayFoodCalories,
      weeklyFoodCalories: weekFoodCaloriesFromState(today),
      foodLogs: _foodState.logs,
      workoutGroups: todayWorkoutGroups,
      weeklyWorkoutGroups: weekWorkoutGroupsFromState(today),
      workoutGroupsByAction: todayWorkoutGroupsByActionFromState(today),
      workoutPlans: _workoutState.plans,
      activeWorkoutSession: _workoutState.activeSession,
      workoutHistory: _workoutState.history,
      todos: _planState.todos,
      events: _planState.events,
      financeRecords: _financeState.records,
      todayExpense: todayFinanceTotal(_financeState.records, '支出', today),
      aiFinanceEndpoint: _financeState.aiEndpoint,
      aiFinanceModel: _financeState.aiModel,
      aiFinanceApiKey: _financeState.aiApiKey,
      aiFinanceParseStrategy: _financeState.aiParseStrategy,
      aiFinanceCustomPrompt: _financeState.aiCustomPrompt,
      onAddFinanceRecord: _addFinanceRecord,
      onEditFinanceRecord: _editFinanceRecord,
      onUpdateAiFinanceConfig: _updateAiFinanceConfig,
      onRecordFoodLogs: _recordFoodLogs,
      onUpdateWorkoutGroups: _updateWorkoutGroups,
      onUpdateWorkoutPlan: _updateWorkoutPlan,
      onStartWorkoutSession: _startWorkoutSession,
      onUpdateWorkoutSession: _updateWorkoutSession,
      onFinishWorkoutSession: _finishWorkoutSession,
      onToggleTodo: _toggleTodo,
      onUpdateTodo: _updateTodo,
      onPostponeTodo: _postponeTodo,
      onArchiveTodo: _archiveTodo,
      onDeleteTodo: _deleteTodo,
      onAddTodo: _addTodo,
      onClearCompletedTodos: _clearCompletedTodos,
      onOpenLinkedTodoAction: _openLinkedModuleAction,
      quickAction: _appDataRestoreComplete ? _pendingQuickAction : null,
      quickActionToken: _quickActionToken,
      onQuickActionHandled: _markQuickActionHandled,
    );
    // 数据恢复完成前先遮罩页面，避免用户在旧数据上操作。
    if (_appDataRestoreComplete && !_appDataSaveFailed && !_appDataLoadFailed) {
      return page;
    }
    return Stack(
      children: [
        AbsorbPointer(
          absorbing: !_appDataRestoreComplete,
          child: page,
        ),
        if (!_appDataRestoreComplete)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66F4F7FC),
              child: Center(
                child: SizedBox.square(
                  key: ValueKey('app_data_restore_progress'),
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
          ),
        if (_appDataSaveFailed || _appDataLoadFailed)
          _AppDataFailureBanner(
            message: _appDataLoadFailed ? '数据读取失败，已停止自动保存。' : '数据保存失败，请稍后重试。',
          ),
      ],
    );
  }

  int get _pendingTodoCount => _planState.pendingTodoCount;
}

/// 数据读写失败时顶部的红色提示条。
class _AppDataFailureBanner extends StatelessWidget {
  const _AppDataFailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Material(
              key: const ValueKey('app_data_save_failure_banner'),
              color: AppColors.financeRed,
              elevation: 10,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
