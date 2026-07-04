// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

class LifeHomePage extends StatefulWidget {
  const LifeHomePage({super.key, this.onSignOut, this.appDataStore});

  final Future<void> Function()? onSignOut;
  final LifeSummaryStore? appDataStore;

  @override
  State<LifeHomePage> createState() => _LifeHomePageState();
}

class _LifeHomePageState extends State<LifeHomePage> {
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

  LifeSummaryStore get _appDataStore =>
      widget.appDataStore ?? _defaultAppDataStore;

  @override
  void initState() {
    super.initState();
    final initialRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    // Android 桌面小组件会把目标模块和快捷动作写进初始路由，冷启动时直接落到对应操作。
    _module = _lifeModuleFromRoute(initialRoute);
    _widgetStore.setQuickActionHandler(_handleWidgetQuickAction);
    unawaited(_restoreAppData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    setState(() => _module = module);
  }

  Future<void> _handleWidgetQuickAction(
      String route, String? actionName) async {
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
    if (!mounted || _pendingQuickAction == null) {
      return;
    }
    setState(() => _pendingQuickAction = null);
  }

  void _updateState(VoidCallback mutation) {
    setState(mutation);
  }

  @override
  void dispose() {
    _widgetStore.clearQuickActionHandler();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _buildLifeHomeModulePage(
      module: _module,
      onSwitchModule: _setModule,
      onOpenModules: _openModuleSheet,
      onOpenQuickRecord: _openQuickRecordSheet,
      foodCalories: _foodState.calories,
      workoutGroups: _workoutState.finishedGroups,
      workoutGroupsByAction: _workoutState.groupsByAction,
      workoutPlans: _workoutState.plans,
      activeWorkoutSession: _workoutState.activeSession,
      workoutHistory: _workoutState.history,
      todos: _planState.todos,
      events: _planState.events,
      financeRecords: _financeState.records,
      todayExpense: _financeState.todayExpense,
      aiFinanceEndpoint: _financeState.aiEndpoint,
      aiFinanceModel: _financeState.aiModel,
      aiFinanceApiKey: _financeState.aiApiKey,
      aiFinanceParseStrategy: _financeState.aiParseStrategy,
      aiFinanceCustomPrompt: _financeState.aiCustomPrompt,
      onAddFinanceRecord: _addFinanceRecord,
      onEditFinanceRecord: _editFinanceRecord,
      onUpdateAiFinanceConfig: _updateAiFinanceConfig,
      onRecordFoodCalories: _recordFoodCalories,
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
      quickAction: _pendingQuickAction,
      quickActionToken: _quickActionToken,
      onQuickActionHandled: _markQuickActionHandled,
    );
    if (!_appDataSaveFailed) {
      return page;
    }
    return Stack(
      children: [
        page,
        const _AppDataSaveFailureBanner(),
      ],
    );
  }

  int get _pendingTodoCount => _planState.pendingTodoCount;
}

class _AppDataSaveFailureBanner extends StatelessWidget {
  const _AppDataSaveFailureBanner();

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
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  '数据保存失败，请稍后重试。',
                  style: TextStyle(
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
