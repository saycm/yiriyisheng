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
  final List<LifeEvent> _events = [];
  final List<TodoItem> _todos = [
    TodoItem(
      title: '遛狗',
      category: '生活',
      color: const Color(0xFF7D9CFF),
      priority: TodoPriority.shouldDo,
      dueDate: DateUtils.dateOnly(DateTime.now()),
    ),
    TodoItem(
      title: '打羽毛球',
      category: '健康',
      color: const Color(0xFFFF6F9D),
      priority: TodoPriority.mustDo,
      dueDate: DateUtils.dateOnly(DateTime.now()),
      linkedModules: const [TodoLinkedModule.workout, TodoLinkedModule.health],
    ),
    TodoItem(
      title: '做报表',
      category: '工作',
      color: const Color(0xFF9278F7),
      priority: TodoPriority.mustDo,
      status: TodoStatus.inProgress,
      dueDate: DateUtils.dateOnly(DateTime.now()),
    ),
    TodoItem(
      title: '还信用卡',
      category: '财务',
      color: AppColors.success,
      priority: TodoPriority.mustDo,
      dueDate: DateUtils.dateOnly(DateTime.now()),
      linkedModules: const [TodoLinkedModule.finance],
      note: '完成后补一条还款记录。',
    ),
    TodoItem(
      title: '早睡',
      category: '健康',
      color: const Color(0xFFFF6F9D),
      priority: TodoPriority.shouldDo,
      dueDate: DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1)),
      repeatRule: TodoRepeatRule.daily,
      linkedModules: const [TodoLinkedModule.health],
    ),
    TodoItem(
      title: '整理学习清单',
      category: '学习',
      color: const Color(0xFFB88955),
      priority: TodoPriority.canDelay,
      note: '无日期任务先放进待办箱。',
    ),
  ];
  final List<FinanceRecord> _financeRecords = [
    FinanceRecord(
      icon: Icons.restaurant_rounded,
      title: '三餐',
      subtitle: '原味板烧鸡腿麦满分',
      amount: 18,
      type: '支出',
    ),
    FinanceRecord(
      icon: Icons.phone_iphone_rounded,
      title: '数码分期',
      subtitle: '手机分期还款',
      amount: 500,
      type: '支出',
    ),
    FinanceRecord(
      icon: Icons.account_balance_wallet_rounded,
      title: '工资',
      subtitle: '本月收入',
      amount: 3000,
      type: '收入',
    ),
    FinanceRecord(
      icon: Icons.local_cafe_rounded,
      title: '咖啡',
      subtitle: '优品豆浆（小杯）',
      amount: 6,
      type: '支出',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    // Android 桌面小组件会把目标模块和快捷动作写进初始路由，冷启动时直接落到对应操作。
    _module = _moduleFromRoute(initialRoute);
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
      final initialAction = _quickActionFromRoute(routeName);
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

  LifeModule _moduleFromRoute(String route) {
    final path = _routePath(route);
    return switch (path) {
      '/finance' => LifeModule.finance,
      '/food' => LifeModule.food,
      '/workout' => LifeModule.workout,
      '/health' => LifeModule.health,
      _ => LifeModule.plan,
    };
  }

  String _routePath(String route) {
    final uri = Uri.tryParse(route);
    final path = uri?.path ?? route;
    return path.isEmpty ? '/' : path;
  }

  WidgetQuickAction? _quickActionFromRoute(String route) {
    final uri = Uri.tryParse(route);
    return _quickActionFromName(uri?.queryParameters['action']);
  }

  WidgetQuickAction? _quickActionFromName(String? action) {
    return switch (action) {
      'add_todo' => WidgetQuickAction.addTodo,
      'add_finance' => WidgetQuickAction.addFinance,
      'add_food' => WidgetQuickAction.addFood,
      'start_workout' => WidgetQuickAction.startWorkout,
      'open_health' => WidgetQuickAction.openHealth,
      _ => null,
    };
  }

  void _setModule(LifeModule module) {
    setState(() => _module = module);
  }

  Future<void> _handleWidgetQuickAction(
      String route, String? actionName) async {
    final action = _quickActionFromName(actionName);
    if (!mounted) {
      return;
    }
    setState(() {
      _module = _moduleFromRoute(route);
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

  @override
  void dispose() {
    _widgetStore.clearQuickActionHandler();
    super.dispose();
  }

  int get _workoutFinishedGroups => _workoutGroupsByAction.values.fold(
        0,
        (total, groups) => total + groups,
      );

  void _recordFoodCalories(int calories) {
    // 饮食模块的记录会进入应用级共享状态，健康模块据此展示今日摄入。
    setState(() {
      _recordedFoodCalories += calories;
      _pushLifeEvent(
        LifeEvent(
          title: '记录饮食',
          detail: '$calories kcal 已同步到健康和计划',
          icon: Icons.restaurant_rounded,
          color: AppColors.success,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _updateWorkoutGroups(String actionName, int finishedGroups) {
    // 锻炼模块完成组数保存在父级，切换到健康/饮食/计划后仍能联动展示。
    final previousGroups = _workoutGroupsByAction[actionName] ?? 0;
    setState(() {
      _workoutGroupsByAction[actionName] = finishedGroups;
      if (finishedGroups > previousGroups) {
        _pushLifeEvent(
          LifeEvent(
            title: '完成锻炼',
            detail: '$actionName · $finishedGroups 组',
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
          ),
        );
      }
    });
    _syncLinkedSummaryToWidget();
  }

  Future<void> _restoreAppData() async {
    final stored = await _appDataStore.load();
    if (!mounted) {
      return;
    }
    if (stored != null) {
      setState(() => _applyLifeSummarySnapshot(stored));
      _syncLinkedSummaryToWidget();
      return;
    }

    final snapshot = await _widgetStore.load();
    if (!mounted) {
      return;
    }
    // 兼容旧版本：首次有 SQLite 前，从桌面小组件共享摘要迁移一次。
    setState(() => _applyLifeSummarySnapshot(snapshot));
    _syncLinkedSummaryToWidget();
  }

  void _applyLifeSummarySnapshot(LifeSummarySnapshot snapshot) {
    _recordedFoodCalories = snapshot.foodCalories;
    _workoutGroupsByAction
      ..clear()
      ..addAll(snapshot.workoutGroupsByAction);
    final restoredTodos = snapshot.todos;
    if (restoredTodos != null) {
      _todos
        ..clear()
        ..addAll(restoredTodos);
    }
    final restoredFinanceRecords = snapshot.financeRecords;
    if (restoredFinanceRecords != null) {
      _financeRecords
        ..clear()
        ..addAll(restoredFinanceRecords);
    }
    _aiFinanceEndpoint = snapshot.aiFinanceEndpoint.trim().isEmpty
        ? _defaultGlmChatEndpoint
        : snapshot.aiFinanceEndpoint;
    _aiFinanceModel = snapshot.aiFinanceModel.trim().isEmpty
        ? _defaultGlmTextModel
        : snapshot.aiFinanceModel;
    _aiFinanceApiKey = snapshot.aiFinanceApiKey;
  }

  void _syncLinkedSummaryToWidget() {
    // App 主数据写 SQLite；桌面小组件只接收摘要和快捷入口数据。
    unawaited(
      _appDataStore.save(
        foodCalories: _recordedFoodCalories,
        workoutGroupsByAction: _workoutGroupsByAction,
        todos: _todos,
        financeRecords: _financeRecords,
        aiFinanceEndpoint: _aiFinanceEndpoint,
        aiFinanceModel: _aiFinanceModel,
        aiFinanceApiKey: _aiFinanceApiKey,
      ),
    );
    unawaited(
      _widgetStore.save(
        foodCalories: _recordedFoodCalories,
        workoutGroupsByAction: _workoutGroupsByAction,
        todos: _todos,
        financeRecords: _financeRecords,
      ),
    );
  }

  void _openModuleSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ModuleSheet(
          selected: _module,
          pendingTodos: _pendingTodoCount,
          foodCalories: _recordedFoodCalories,
          workoutGroups: _workoutFinishedGroups,
          events: _events,
          onSelect: (module) {
            Navigator.of(context).pop();
            _setModule(module);
          },
          onSignOut: widget.onSignOut,
        );
      },
    );
  }

  void _openQuickRecordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _QuickRecordSheet(
          onSelect: (action) {
            Navigator.of(context).pop();
            _dispatchQuickRecordAction(action);
          },
        );
      },
    );
  }

  void _dispatchQuickRecordAction(WidgetQuickAction action) {
    final module = switch (action) {
      WidgetQuickAction.addTodo => LifeModule.plan,
      WidgetQuickAction.addFinance => LifeModule.finance,
      WidgetQuickAction.addFood => LifeModule.food,
      WidgetQuickAction.startWorkout => LifeModule.workout,
      WidgetQuickAction.openHealth => LifeModule.health,
    };
    setState(() {
      _module = module;
      _pendingQuickAction = action;
      _quickActionToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _buildModulePage()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom +
                    _moduleSwitchBarBottomGap,
              ),
              child: Material(
                color: Colors.transparent,
                child: _ModuleLinkStrip(
                  selected: _module,
                  onSwitchModule: _setModule,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModulePage() {
    return switch (_module) {
      LifeModule.finance => FinanceModulePage(
          onOpenModules: _openModuleSheet,
          onSwitchModule: _setModule,
          foodCalories: _recordedFoodCalories,
          workoutGroups: _workoutFinishedGroups,
          records: _financeRecords,
          onAddRecord: _addFinanceRecord,
          onEditRecord: _editFinanceRecord,
          aiEndpoint: _aiFinanceEndpoint,
          aiModel: _aiFinanceModel,
          aiApiKey: _aiFinanceApiKey,
          onAiConfigChanged: _updateAiFinanceConfig,
          quickAction: _pendingQuickAction,
          quickActionToken: _quickActionToken,
          onQuickActionHandled: _markQuickActionHandled,
        ),
      LifeModule.plan => PlanModulePage(
          onOpenModules: _openModuleSheet,
          onSwitchModule: _setModule,
          onOpenQuickRecord: _openQuickRecordSheet,
          foodCalories: _recordedFoodCalories,
          workoutGroups: _workoutFinishedGroups,
          todayExpense: _todayExpense,
          healthStatusText: '正常',
          todos: _todos,
          events: _events,
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
        ),
      LifeModule.food => FoodModulePage(
          onOpenModules: _openModuleSheet,
          onSwitchModule: _setModule,
          onRecordCalories: _recordFoodCalories,
          foodCalories: _recordedFoodCalories,
          workoutGroups: _workoutFinishedGroups,
          quickAction: _pendingQuickAction,
          quickActionToken: _quickActionToken,
          onQuickActionHandled: _markQuickActionHandled,
        ),
      LifeModule.workout => WorkoutModulePage(
          onOpenModules: _openModuleSheet,
          onSwitchModule: _setModule,
          finishedGroupsByAction: _workoutGroupsByAction,
          onUpdateActionGroups: _updateWorkoutGroups,
          foodCalories: _recordedFoodCalories,
          quickAction: _pendingQuickAction,
          quickActionToken: _quickActionToken,
          onQuickActionHandled: _markQuickActionHandled,
        ),
      LifeModule.health => HealthModulePage(
          onOpenModules: _openModuleSheet,
          onSwitchModule: _setModule,
          foodCalories: _recordedFoodCalories,
          workoutGroups: _workoutFinishedGroups,
          quickAction: _pendingQuickAction,
          quickActionToken: _quickActionToken,
          onQuickActionHandled: _markQuickActionHandled,
        ),
    };
  }

  int get _pendingTodoCount => _todos.where((todo) => todo.isActive).length;

  double get _todayExpense => _financeRecords
      .where((record) => record.type == '支出')
      .fold(0, (total, record) => total + record.amount);

  void _toggleTodo(TodoItem todo) {
    final wasDone = todo.done;
    var shouldShowLinkedActions = false;
    setState(() {
      todo.done = !todo.done;
      _pushLifeEvent(
        LifeEvent(
          title: todo.done ? '完成待办' : '重新打开待办',
          detail: todo.done ? _todoCompletionDetail(todo) : todo.title,
          icon: Icons.event_available_rounded,
          color: todo.color,
        ),
      );
      if (!wasDone && todo.done) {
        _pushLinkedTodoEvent(todo);
        shouldShowLinkedActions = todo.linkedModules.isNotEmpty;
      }
    });
    _syncLinkedSummaryToWidget();
    if (shouldShowLinkedActions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openTodoLinkedActionSheet(todo);
        }
      });
    }
  }

  void _updateTodo(TodoItem todo) {
    final index = _todos.indexWhere((item) => item.id == todo.id);
    if (index == -1) {
      return;
    }
    setState(() => _todos[index] = todo);
    _syncLinkedSummaryToWidget();
  }

  void _postponeTodo(TodoItem todo) {
    setState(() {
      todo.postponeToTomorrow();
      _pushLifeEvent(
        LifeEvent(
          title: '延后待办',
          detail: '${todo.title} · 明天处理',
          icon: Icons.event_repeat_rounded,
          color: todo.color,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _archiveTodo(TodoItem todo) {
    setState(() {
      todo.archive();
      _pushLifeEvent(
        LifeEvent(
          title: '归档待办',
          detail: todo.title,
          icon: Icons.archive_rounded,
          color: AppColors.muted,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _deleteTodo(TodoItem todo) {
    setState(() {
      _todos.removeWhere((item) => item.id == todo.id);
      _pushLifeEvent(
        LifeEvent(
          title: '删除待办',
          detail: todo.title,
          icon: Icons.delete_outline_rounded,
          color: AppColors.financeRed,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _addTodo(TodoItem todo) {
    setState(() {
      _todos.add(todo);
      _pushLifeEvent(
        LifeEvent(
          title: '新增待办',
          detail: todo.title,
          icon: Icons.add_task_rounded,
          color: todo.color,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _clearCompletedTodos() {
    final count = _todos.where((todo) => todo.done).length;
    setState(() {
      _todos.removeWhere((todo) => todo.done);
      if (count > 0) {
        _pushLifeEvent(
          LifeEvent(
            title: '清理待办箱',
            detail: '移除 $count 项完成记录',
            icon: Icons.archive_rounded,
            color: AppColors.muted,
          ),
        );
      }
    });
    _syncLinkedSummaryToWidget();
  }

  void _pushLinkedTodoEvent(TodoItem todo) {
    for (final module in todo.linkedModules) {
      _pushLifeEvent(
        LifeEvent(
          title: '${module.label}提醒',
          detail: _linkedTodoPrompt(todo, module),
          icon: module.icon,
          color: module.color,
        ),
      );
    }
  }

  void _openTodoLinkedActionSheet(TodoItem todo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _TodoLinkedActionSheet(
          todo: todo,
          onSelect: (module) {
            Navigator.of(context).pop();
            _openLinkedModuleAction(module);
          },
        );
      },
    );
  }

  void _openLinkedModuleAction(TodoLinkedModule linkedModule) {
    final target = linkedModule.lifeModule;
    final action = linkedModule.quickAction;
    setState(() {
      _module = target;
      _pendingQuickAction = action;
      _quickActionToken++;
    });
  }

  String _todoCompletionDetail(TodoItem todo) {
    if (todo.linkedModules.isEmpty) {
      return todo.title;
    }
    return '${todo.title} · ${todo.linkedModules.map((module) => module.label).join('/')}联动';
  }

  void _addFinanceRecord(FinanceRecord record) {
    setState(() => _financeRecords.insert(0, record));
    _syncLinkedSummaryToWidget();
  }

  void _editFinanceRecord(FinanceRecord oldRecord, FinanceRecord newRecord) {
    final index = _financeRecords.indexOf(oldRecord);
    if (index == -1) {
      return;
    }
    setState(() => _financeRecords[index] = newRecord);
    _syncLinkedSummaryToWidget();
  }

  void _updateAiFinanceConfig({
    required String endpoint,
    required String model,
    required String apiKey,
  }) {
    setState(() {
      _aiFinanceEndpoint =
          endpoint.trim().isEmpty ? _defaultGlmChatEndpoint : endpoint.trim();
      _aiFinanceModel =
          model.trim().isEmpty ? _defaultGlmTextModel : model.trim();
      _aiFinanceApiKey = apiKey.trim();
    });
    _syncLinkedSummaryToWidget();
  }

  void _pushLifeEvent(LifeEvent event) {
    // 所有模块产生的关键操作都汇入同一条时间线，计划复盘和模块中心共用。
    _events.insert(0, event);
    if (_events.length > 8) {
      _events.removeRange(8, _events.length);
    }
  }
}

class LifeEvent {
  const LifeEvent({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
}

class _TodoLinkedActionSheet extends StatelessWidget {
  const _TodoLinkedActionSheet({
    required this.todo,
    required this.onSelect,
  });

  final TodoItem todo;
  final ValueChanged<TodoLinkedModule> onSelect;

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
      title: '继续记录',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            todo.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '任务已完成，可以顺手把相关模块的数据补齐。',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...todo.linkedModules.map(
            (module) => _TodoLinkedActionTile(
              module: module,
              prompt: _linkedTodoPrompt(todo, module),
              onTap: () => onSelect(module),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '稍后处理',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoLinkedActionTile extends StatelessWidget {
  const _TodoLinkedActionTile({
    required this.module,
    required this.prompt,
    required this.onTap,
  });

  final TodoLinkedModule module;
  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
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
                    color: module.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(module.icon, color: module.color, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.actionLabel,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        prompt,
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
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.muted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickRecordSheet extends StatelessWidget {
  const _QuickRecordSheet({required this.onSelect});

  final ValueChanged<WidgetQuickAction> onSelect;

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
      title: '快速记录',
      child: Column(
        children: [
          _QuickRecordTile(
            key: const ValueKey('quick_record_todo'),
            icon: Icons.add_task_rounded,
            color: AppColors.primary,
            title: '加待办',
            subtitle: '写下今天或待办箱里的事',
            onTap: () => onSelect(WidgetQuickAction.addTodo),
          ),
          _QuickRecordTile(
            key: const ValueKey('quick_record_finance'),
            icon: Icons.receipt_long_rounded,
            color: AppColors.financeRed,
            title: '记一笔',
            subtitle: '支出、收入或转账',
            onTap: () => onSelect(WidgetQuickAction.addFinance),
          ),
          _QuickRecordTile(
            key: const ValueKey('quick_record_food'),
            icon: Icons.restaurant_rounded,
            color: AppColors.success,
            title: '记饮食',
            subtitle: '补一餐或常吃食物',
            onTap: () => onSelect(WidgetQuickAction.addFood),
          ),
          _QuickRecordTile(
            key: const ValueKey('quick_record_workout'),
            icon: Icons.fitness_center_rounded,
            color: const Color(0xFF9278F7),
            title: '完成一组',
            subtitle: '进入今日训练动作',
            onTap: () => onSelect(WidgetQuickAction.startWorkout),
          ),
          _QuickRecordTile(
            key: const ValueKey('quick_record_health'),
            icon: Icons.favorite_rounded,
            color: const Color(0xFFFF6F9D),
            title: '看健康',
            subtitle: '打开身体状态仪表盘',
            onTap: () => onSelect(WidgetQuickAction.openHealth),
          ),
        ],
      ),
    );
  }
}

class _QuickRecordTile extends StatelessWidget {
  const _QuickRecordTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
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
                  child: Icon(icon, color: color, size: 23),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
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
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.muted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _linkedTodoPrompt(TodoItem todo, TodoLinkedModule module) {
  return switch (module) {
    TodoLinkedModule.finance => '${todo.title} 已完成，可以补一条财务记录。',
    TodoLinkedModule.food => '${todo.title} 已完成，可以补充饮食记录。',
    TodoLinkedModule.workout => '${todo.title} 已完成，可以记录训练组数。',
    TodoLinkedModule.health => todo.done
        ? '${todo.title} 已完成，健康模块会同步今日状态。'
        : '${todo.title} 未完成，明天关注睡眠和恢复。',
  };
}
