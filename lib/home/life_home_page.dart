part of '../main.dart';

class LifeHomePage extends StatefulWidget {
  const LifeHomePage({super.key, this.onSignOut});

  final Future<void> Function()? onSignOut;

  @override
  State<LifeHomePage> createState() => _LifeHomePageState();
}

class _LifeHomePageState extends State<LifeHomePage> {
  static const _appDataStore = _AppDataStore();
  static const _widgetStore = _LifeWidgetStore();

  LifeModule _module = LifeModule.plan;
  WidgetQuickAction? _pendingQuickAction;
  int _quickActionToken = 0;
  bool _initialQuickActionChecked = false;
  int _recordedFoodCalories = 0;
  String _aiFinanceEndpoint = _defaultGlmChatEndpoint;
  String _aiFinanceModel = _defaultGlmTextModel;
  String _aiFinanceApiKey = '';
  final Map<String, int> _workoutGroupsByAction = {};
  final List<WorkoutPlan> _workoutPlans = _createDefaultWorkoutPlans();
  ActiveWorkoutSession? _activeWorkoutSession;
  final List<WorkoutHistoryEntry> _workoutHistory = [];
  final List<LifeEvent> _events = [];
  final List<TodoItem> _todos = _createSeedTodos();
  final List<FinanceRecord> _financeRecords = _createSeedFinanceRecords();

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

  int get _workoutFinishedGroups => _workoutGroupsByAction.values.fold(
        0,
        (total, groups) => total + groups,
      );

  @override
  Widget build(BuildContext context) {
    return _buildLifeHomeModulePage(
      module: _module,
      onSwitchModule: _setModule,
      onOpenModules: _openModuleSheet,
      onOpenQuickRecord: _openQuickRecordSheet,
      foodCalories: _recordedFoodCalories,
      workoutGroups: _workoutFinishedGroups,
      workoutGroupsByAction: _workoutGroupsByAction,
      workoutPlans: _workoutPlans,
      activeWorkoutSession: _activeWorkoutSession,
      workoutHistory: _workoutHistory,
      todos: _todos,
      events: _events,
      financeRecords: _financeRecords,
      todayExpense: _todayExpense,
      aiFinanceEndpoint: _aiFinanceEndpoint,
      aiFinanceModel: _aiFinanceModel,
      aiFinanceApiKey: _aiFinanceApiKey,
      onAddFinanceRecord: _addFinanceRecord,
      onEditFinanceRecord: _editFinanceRecord,
      onUpdateAiFinanceConfig: _updateAiFinanceConfig,
      onRecordFoodCalories: _recordFoodCalories,
      onUpdateWorkoutGroups: _updateWorkoutGroups,
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
  }

  int get _pendingTodoCount => _todos.where((todo) => todo.isActive).length;

  double get _todayExpense => _financeRecords
      .where((record) => record.type == '支出')
      .fold(0, (total, record) => total + record.amount);
}
