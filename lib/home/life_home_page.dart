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
  }

  void _syncLinkedSummaryToWidget() {
    // App 主数据写 SQLite；桌面小组件只接收摘要和快捷入口数据。
    unawaited(
      _appDataStore.save(
        foodCalories: _recordedFoodCalories,
        workoutGroupsByAction: _workoutGroupsByAction,
        todos: _todos,
        financeRecords: _financeRecords,
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

  @override
  Widget build(BuildContext context) {
    return switch (_module) {
      LifeModule.finance => FinanceModulePage(
          onOpenModules: _openModuleSheet,
          onSwitchModule: _setModule,
          foodCalories: _recordedFoodCalories,
          workoutGroups: _workoutFinishedGroups,
          records: _financeRecords,
          onAddRecord: _addFinanceRecord,
          onEditRecord: _editFinanceRecord,
          quickAction: _pendingQuickAction,
          quickActionToken: _quickActionToken,
          onQuickActionHandled: _markQuickActionHandled,
        ),
      LifeModule.plan => PlanModulePage(
          onOpenModules: _openModuleSheet,
          onSwitchModule: _setModule,
          foodCalories: _recordedFoodCalories,
          workoutGroups: _workoutFinishedGroups,
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

class TodoItem {
  TodoItem({
    String? id,
    required this.title,
    required this.category,
    required this.color,
    this.priority = TodoPriority.shouldDo,
    this.status = TodoStatus.notStarted,
    this.dueDate,
    this.note = '',
    this.repeatRule = TodoRepeatRule.none,
    List<TodoLinkedModule> linkedModules = const [],
    this.postponedCount = 0,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? _newLocalId(),
        linkedModules = List.of(linkedModules),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final String category;
  final Color color;
  TodoPriority priority;
  TodoStatus status;
  DateTime? dueDate;
  String note;
  TodoRepeatRule repeatRule;
  List<TodoLinkedModule> linkedModules;
  int postponedCount;
  final DateTime createdAt;
  DateTime? completedAt;

  bool get done => status == TodoStatus.completed;

  set done(bool value) {
    status = value ? TodoStatus.completed : TodoStatus.notStarted;
    completedAt = value ? DateTime.now() : null;
  }

  bool get isActive =>
      status != TodoStatus.completed && status != TodoStatus.archived;

  bool get isInbox => dueDate == null && isActive;

  bool isDueOn(DateTime day) =>
      dueDate != null && DateUtils.isSameDay(dueDate, day);

  TodoItem copyWith({
    String? title,
    String? category,
    Color? color,
    TodoPriority? priority,
    TodoStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? note,
    TodoRepeatRule? repeatRule,
    List<TodoLinkedModule>? linkedModules,
    int? postponedCount,
    DateTime? completedAt,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      note: note ?? this.note,
      repeatRule: repeatRule ?? this.repeatRule,
      linkedModules: linkedModules ?? this.linkedModules,
      postponedCount: postponedCount ?? this.postponedCount,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  void postponeToTomorrow() {
    dueDate = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    status = TodoStatus.postponed;
    postponedCount++;
  }

  void archive() {
    status = TodoStatus.archived;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'priority': priority.name,
      'status': status.name,
      'dueDate': _dateToJson(dueDate),
      'note': note,
      'repeatRule': repeatRule.name,
      'linkedModules': linkedModules.map((module) => module.name).toList(),
      'postponedCount': postponedCount,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'done': done,
    };
  }

  static TodoItem fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? '生活';
    final status = _enumByName(
      TodoStatus.values,
      json['status'] as String?,
      fallback:
          json['done'] == true ? TodoStatus.completed : TodoStatus.notStarted,
    );
    return TodoItem(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '未命名待办',
      category: category,
      color: _todoColorForCategory(category),
      priority: _enumByName(
        TodoPriority.values,
        json['priority'] as String?,
        fallback: TodoPriority.shouldDo,
      ),
      status: status,
      dueDate: _dateFromJson(json['dueDate'] as String?),
      note: json['note'] as String? ?? '',
      repeatRule: _enumByName(
        TodoRepeatRule.values,
        json['repeatRule'] as String?,
        fallback: TodoRepeatRule.none,
      ),
      linkedModules: _linkedModulesFromJson(json['linkedModules']),
      postponedCount: (json['postponedCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}

enum TodoPriority {
  mustDo('必须做', Icons.priority_high_rounded, AppColors.financeRed),
  shouldDo('应该做', Icons.flag_rounded, AppColors.primary),
  canDelay('可推迟', Icons.low_priority_rounded, AppColors.muted);

  const TodoPriority(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

enum TodoStatus {
  notStarted('未开始', Icons.radio_button_unchecked_rounded),
  inProgress('进行中', Icons.timelapse_rounded),
  completed('已完成', Icons.check_circle_rounded),
  postponed('已延后', Icons.event_repeat_rounded),
  archived('已归档', Icons.archive_rounded);

  const TodoStatus(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum TodoRepeatRule {
  none('不重复'),
  daily('每天'),
  weekly('每周'),
  monthly('每月'),
  custom('自定义周期');

  const TodoRepeatRule(this.label);

  final String label;
}

enum TodoLinkedModule {
  finance('财务', Icons.account_balance_wallet_rounded, AppColors.success),
  food('饮食', Icons.restaurant_rounded, Color(0xFFB88955)),
  workout('锻炼', Icons.fitness_center_rounded, AppColors.primary),
  health('健康', Icons.monitor_heart_rounded, Color(0xFFFF6F9D));

  const TodoLinkedModule(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  LifeModule get lifeModule {
    return switch (this) {
      TodoLinkedModule.finance => LifeModule.finance,
      TodoLinkedModule.food => LifeModule.food,
      TodoLinkedModule.workout => LifeModule.workout,
      TodoLinkedModule.health => LifeModule.health,
    };
  }

  WidgetQuickAction get quickAction {
    return switch (this) {
      TodoLinkedModule.finance => WidgetQuickAction.addFinance,
      TodoLinkedModule.food => WidgetQuickAction.addFood,
      TodoLinkedModule.workout => WidgetQuickAction.startWorkout,
      TodoLinkedModule.health => WidgetQuickAction.openHealth,
    };
  }

  String get actionLabel {
    return switch (this) {
      TodoLinkedModule.finance => '去记账',
      TodoLinkedModule.food => '记饮食',
      TodoLinkedModule.workout => '记录训练',
      TodoLinkedModule.health => '看健康',
    };
  }
}

Color _todoColorForCategory(String category) {
  return switch (category) {
    '健康' => const Color(0xFFFF6F9D),
    '工作' => const Color(0xFF9278F7),
    '财务' => AppColors.success,
    '学习' => const Color(0xFFB88955),
    _ => const Color(0xFF7D9CFF),
  };
}

T _enumByName<T extends Enum>(
  List<T> values,
  String? name, {
  required T fallback,
}) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}

List<TodoLinkedModule> _linkedModulesFromJson(Object? value) {
  if (value is! List<dynamic>) {
    return [];
  }
  return value
      .whereType<String>()
      .map(
        (name) => _enumByName(
          TodoLinkedModule.values,
          name,
          fallback: TodoLinkedModule.health,
        ),
      )
      .toSet()
      .toList();
}

String? _dateToJson(DateTime? value) {
  if (value == null) {
    return null;
  }
  final date = DateUtils.dateOnly(value);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime? _dateFromJson(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  return parsed == null ? null : DateUtils.dateOnly(parsed);
}

String _newLocalId() {
  final micros = DateTime.now().microsecondsSinceEpoch;
  final salt = math.Random().nextInt(1 << 20).toRadixString(16);
  return 'todo_${micros}_$salt';
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
