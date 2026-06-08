import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PingShengApp());
}

class PingShengApp extends StatelessWidget {
  const PingShengApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '平生',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
        fontFamily: 'sans',
        scaffoldBackgroundColor: AppColors.background,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const LifeHomePage(),
        '/finance': (_) => const LifeHomePage(),
        '/plan': (_) => const LifeHomePage(),
        '/food': (_) => const LifeHomePage(),
        '/workout': (_) => const LifeHomePage(),
        '/health': (_) => const LifeHomePage(),
      },
      onGenerateRoute: (settings) {
        // 桌面小组件会携带 action 查询参数，未知路由统一交给首页解析。
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LifeHomePage(),
        );
      },
    );
  }
}

enum LifeModule { plan, finance, food, workout, health }

enum WidgetQuickAction {
  addTodo,
  addFinance,
  addFood,
  startWorkout,
  openHealth,
}

class AppColors {
  static const background = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF5E7CF7);
  static const primarySoft = Color(0xFFE7EBFF);
  static const accent = Color(0xFFFFA86B);
  static const ink = Color(0xFF182033);
  static const muted = Color(0xFF8B92A6);
  static const financeRed = Color(0xFFE85C59);
  static const success = Color(0xFF41C782);
  static const line = Color(0xFFE5EAF5);
}

class LifeSummarySnapshot {
  const LifeSummarySnapshot({
    required this.foodCalories,
    required this.workoutGroupsByAction,
    required this.todos,
    required this.financeRecords,
  });

  final int foodCalories;
  final Map<String, int> workoutGroupsByAction;
  final List<TodoItem>? todos;
  final List<FinanceRecord>? financeRecords;
}

enum SystemHealthStatus {
  loading,
  ok,
  permissionRequired,
  unavailable,
  updateRequired,
  error,
}

class HealthSensorSnapshot {
  const HealthSensorSnapshot({
    required this.stepCounterAvailable,
    required this.heartRateSensorAvailable,
    required this.accelerometerAvailable,
    this.stepCounterSinceBoot,
    this.heartRateBpm,
    this.accelerationMagnitude,
    this.lastSensorUpdate,
  });

  final bool stepCounterAvailable;
  final bool heartRateSensorAvailable;
  final bool accelerometerAvailable;
  final int? stepCounterSinceBoot;
  final double? heartRateBpm;
  final double? accelerationMagnitude;
  final DateTime? lastSensorUpdate;

  String get summary {
    final connected = [
      if (stepCounterAvailable) '计步器',
      if (heartRateSensorAvailable) '心率',
      if (accelerometerAvailable) '加速度',
    ];
    return connected.isEmpty ? '未检测到可用传感器' : connected.join(' / ');
  }

  factory HealthSensorSnapshot.fromMap(Object? value) {
    final map = value is Map<Object?, Object?> ? value : const {};
    final millis = _healthInt(map['lastSensorUpdateMillis']);
    return HealthSensorSnapshot(
      stepCounterAvailable: map['stepCounterAvailable'] == true,
      heartRateSensorAvailable: map['heartRateSensorAvailable'] == true,
      accelerometerAvailable: map['accelerometerAvailable'] == true,
      stepCounterSinceBoot: _healthInt(map['stepCounterSinceBoot']),
      heartRateBpm: _healthDouble(map['heartRateBpm']),
      accelerationMagnitude: _healthDouble(map['accelerationMagnitude']),
      lastSensorUpdate:
          millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}

class HealthSystemDaySample {
  const HealthSystemDaySample({
    required this.date,
    this.steps,
    this.activeCaloriesKcal,
    this.basalCaloriesKcal,
    this.sleepMinutes,
    this.heartRateBpm,
    this.respiratoryRate,
  });

  final DateTime date;
  final int? steps;
  final double? activeCaloriesKcal;
  final double? basalCaloriesKcal;
  final int? sleepMinutes;
  final int? heartRateBpm;
  final double? respiratoryRate;

  factory HealthSystemDaySample.empty(DateTime date) {
    return HealthSystemDaySample(
        date: DateTime(date.year, date.month, date.day));
  }

  factory HealthSystemDaySample.fromMap(Object? value) {
    final map = value is Map<Object?, Object?> ? value : const {};
    final parsedDate = DateTime.tryParse(map['dateIso'] as String? ?? '');
    return HealthSystemDaySample(
      date: parsedDate ?? DateTime.now(),
      steps: _healthInt(map['steps']),
      activeCaloriesKcal: _healthDouble(map['activeCaloriesKcal']),
      basalCaloriesKcal: _healthDouble(map['basalCaloriesKcal']),
      sleepMinutes: _healthInt(map['sleepMinutes']),
      heartRateBpm: _healthInt(map['heartRateBpm']),
      respiratoryRate: _healthDouble(map['respiratoryRate']),
    );
  }
}

class HealthSystemSnapshot {
  const HealthSystemSnapshot({
    required this.status,
    required this.message,
    required this.days,
    required this.sensors,
    this.lastUpdated,
  });

  final SystemHealthStatus status;
  final String message;
  final List<HealthSystemDaySample> days;
  final HealthSensorSnapshot sensors;
  final DateTime? lastUpdated;

  bool get isReady => status == SystemHealthStatus.ok;
  bool get needsPermission => status == SystemHealthStatus.permissionRequired;

  static HealthSystemSnapshot loading() {
    return HealthSystemSnapshot(
      status: SystemHealthStatus.loading,
      message: '正在读取系统健康数据',
      days: [HealthSystemDaySample.empty(DateTime.now())],
      sensors: const HealthSensorSnapshot(
        stepCounterAvailable: false,
        heartRateSensorAvailable: false,
        accelerometerAvailable: false,
      ),
    );
  }

  static HealthSystemSnapshot unsupported(String message) {
    return HealthSystemSnapshot(
      status: SystemHealthStatus.unavailable,
      message: message,
      days: [HealthSystemDaySample.empty(DateTime.now())],
      sensors: const HealthSensorSnapshot(
        stepCounterAvailable: false,
        heartRateSensorAvailable: false,
        accelerometerAvailable: false,
      ),
      lastUpdated: DateTime.now(),
    );
  }

  factory HealthSystemSnapshot.fromMap(Map<Object?, Object?> map) {
    final rawDays = map['days'];
    final parsedDays = rawDays is List<Object?>
        ? rawDays.map(HealthSystemDaySample.fromMap).toList()
        : <HealthSystemDaySample>[];
    return HealthSystemSnapshot(
      status: _healthStatusFromName(map['status'] as String?),
      message: map['message'] as String? ?? '系统健康数据状态未知',
      days: parsedDays.isEmpty
          ? [HealthSystemDaySample.empty(DateTime.now())]
          : parsedDays,
      sensors: HealthSensorSnapshot.fromMap(map['sensors']),
      lastUpdated: DateTime.tryParse(map['lastUpdated'] as String? ?? ''),
    );
  }
}

class _SystemHealthStore {
  const _SystemHealthStore();

  static const _channel = MethodChannel('pingsheng_life/system_health');

  Future<HealthSystemSnapshot> load() async {
    try {
      final result = await _channel.invokeMethod<Object?>('loadHealthSnapshot');
      if (result is Map<Object?, Object?>) {
        return HealthSystemSnapshot.fromMap(result);
      }
      return HealthSystemSnapshot.unsupported('系统健康接口返回了无法识别的数据。');
    } on MissingPluginException {
      return HealthSystemSnapshot.unsupported('当前平台没有系统健康数据通道。');
    } on PlatformException catch (error) {
      return HealthSystemSnapshot.unsupported(
        error.message ?? '系统健康数据读取失败。',
      );
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final result =
          await _channel.invokeMethod<Object?>('requestHealthPermissions');
      if (result is Map<Object?, Object?>) {
        return result['granted'] == true;
      }
      return false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openHealthConnectSettings');
    } on MissingPluginException {
      // 非 Android 平台没有系统健康设置入口，页面仍会提示当前状态。
    }
  }
}

SystemHealthStatus _healthStatusFromName(String? name) {
  return switch (name) {
    'ok' => SystemHealthStatus.ok,
    'permissionRequired' => SystemHealthStatus.permissionRequired,
    'updateRequired' => SystemHealthStatus.updateRequired,
    'error' => SystemHealthStatus.error,
    'loading' => SystemHealthStatus.loading,
    _ => SystemHealthStatus.unavailable,
  };
}

int? _healthInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

double? _healthDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

class _LifeWidgetStore {
  const _LifeWidgetStore();

  static const _channel = MethodChannel('pingsheng_life/widget_summary');

  void setQuickActionHandler(
    Future<void> Function(String route, String? action) onAction,
  ) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'openWidgetAction') {
        return;
      }
      final args = call.arguments;
      if (args is! Map<Object?, Object?>) {
        return;
      }
      await onAction(
        args['route'] as String? ?? '/',
        args['action'] as String?,
      );
    });
  }

  void clearQuickActionHandler() {
    _channel.setMethodCallHandler(null);
  }

  Future<LifeSummarySnapshot> load() async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'loadLifeSummary',
      );
      final rawGroups = result?['workoutGroupsJson'] as String? ?? '{}';
      final decodedGroups = jsonDecode(rawGroups);
      final groups = <String, int>{};
      if (decodedGroups is Map<String, dynamic>) {
        for (final entry in decodedGroups.entries) {
          final value = entry.value;
          if (value is num) {
            groups[entry.key] = value.toInt();
          }
        }
      }
      final rawTodos = result?['todosJson'] as String?;
      final todos = rawTodos == null ? null : _decodeTodos(rawTodos);
      final rawFinanceRecords = result?['financeRecordsJson'] as String?;
      final financeRecords = rawFinanceRecords == null
          ? null
          : _decodeFinanceRecords(rawFinanceRecords);
      return LifeSummarySnapshot(
        foodCalories: (result?['foodCalories'] as num?)?.toInt() ?? 0,
        workoutGroupsByAction: groups,
        todos: todos,
        financeRecords: financeRecords,
      );
    } on MissingPluginException {
      return const LifeSummarySnapshot(
        foodCalories: 0,
        workoutGroupsByAction: {},
        todos: null,
        financeRecords: null,
      );
    } on FormatException {
      return const LifeSummarySnapshot(
        foodCalories: 0,
        workoutGroupsByAction: {},
        todos: null,
        financeRecords: null,
      );
    }
  }

  Future<void> save({
    required int foodCalories,
    required Map<String, int> workoutGroupsByAction,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
  }) async {
    try {
      await _channel.invokeMethod<void>('saveLifeSummary', {
        'foodCalories': foodCalories,
        'pendingTodos': todos.where((todo) => !todo.done).length,
        'todosJson': jsonEncode(todos.map((todo) => todo.toJson()).toList()),
        'financeRecordsJson': jsonEncode(
            financeRecords.map((record) => record.toJson()).toList()),
        'workoutGroups': workoutGroupsByAction.values.fold<int>(
          0,
          (total, groups) => total + groups,
        ),
        'workoutGroupsJson': jsonEncode(workoutGroupsByAction),
      });
    } on MissingPluginException {
      // 测试环境和非 Android 平台没有桌面小组件通道，直接跳过同步。
    }
  }

  List<TodoItem> _decodeTodos(String rawTodos) {
    final decodedTodos = jsonDecode(rawTodos);
    if (decodedTodos is! List<dynamic>) {
      return [];
    }
    return decodedTodos
        .whereType<Map<String, dynamic>>()
        .map(TodoItem.fromJson)
        .toList();
  }

  List<FinanceRecord> _decodeFinanceRecords(String rawRecords) {
    final decodedRecords = jsonDecode(rawRecords);
    if (decodedRecords is! List<dynamic>) {
      return [];
    }
    return decodedRecords
        .whereType<Map<String, dynamic>>()
        .map(FinanceRecord.fromJson)
        .toList();
  }
}

class LifeHomePage extends StatefulWidget {
  const LifeHomePage({super.key});

  @override
  State<LifeHomePage> createState() => _LifeHomePageState();
}

class _LifeHomePageState extends State<LifeHomePage> {
  static const _widgetStore = _LifeWidgetStore();

  LifeModule _module = LifeModule.plan;
  WidgetQuickAction? _pendingQuickAction;
  int _quickActionToken = 0;
  bool _initialQuickActionChecked = false;
  int _recordedFoodCalories = 0;
  final Map<String, int> _workoutGroupsByAction = {};
  final List<LifeEvent> _events = [];
  final List<TodoItem> _todos = [
    TodoItem(title: '遛狗', category: '生活', color: const Color(0xFF7D9CFF)),
    TodoItem(title: '打羽毛球', category: '健康', color: const Color(0xFFFF6F9D)),
    TodoItem(title: '做报表', category: '工作', color: const Color(0xFF9278F7)),
    TodoItem(title: '理财', category: '财务', color: AppColors.success),
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
    unawaited(_restoreLinkedSummary());
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

  Future<void> _restoreLinkedSummary() async {
    final snapshot = await _widgetStore.load();
    if (!mounted) {
      return;
    }
    // 冷启动时从原生小组件共享存储恢复数据，保证 App 和桌面摘要看到同一份状态。
    setState(() {
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
    });
  }

  void _syncLinkedSummaryToWidget() {
    // 每次共享状态变化都推送给 Android 桌面小组件，让桌面摘要即时更新。
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

  int get _pendingTodoCount => _todos.where((todo) => !todo.done).length;

  void _toggleTodo(TodoItem todo) {
    setState(() {
      todo.done = !todo.done;
      _pushLifeEvent(
        LifeEvent(
          title: todo.done ? '完成待办' : '重新打开待办',
          detail: todo.title,
          icon: Icons.event_available_rounded,
          color: todo.color,
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

class TodoItem {
  TodoItem({
    required this.title,
    required this.category,
    required this.color,
    this.done = false,
  });

  final String title;
  final String category;
  final Color color;
  bool done;

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'category': category,
      'done': done,
    };
  }

  static TodoItem fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? '生活';
    return TodoItem(
      title: json['title'] as String? ?? '未命名待办',
      category: category,
      color: _todoColorForCategory(category),
      done: json['done'] == true,
    );
  }
}

Color _todoColorForCategory(String category) {
  return switch (category) {
    '健康' => const Color(0xFFFF6F9D),
    '工作' => const Color(0xFF9278F7),
    '财务' => AppColors.success,
    _ => const Color(0xFF7D9CFF),
  };
}

class PlanModulePage extends StatefulWidget {
  const PlanModulePage({
    super.key,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todos,
    required this.events,
    required this.onToggleTodo,
    required this.onAddTodo,
    required this.onClearCompletedTodos,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final int foodCalories;
  final int workoutGroups;
  final List<TodoItem> todos;
  final List<LifeEvent> events;
  final ValueChanged<TodoItem> onToggleTodo;
  final ValueChanged<TodoItem> onAddTodo;
  final VoidCallback onClearCompletedTodos;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<PlanModulePage> createState() => _PlanModulePageState();
}

class _PlanModulePageState extends State<PlanModulePage> {
  int _selectedDay = 23;
  int _selectedTab = 0;
  String _categoryFilter = '全部';
  int _handledQuickActionToken = 0;

  List<TodoItem> get _pendingTodos =>
      widget.todos.where((todo) => !todo.done).toList();

  List<TodoItem> get _completedTodos =>
      widget.todos.where((todo) => todo.done).toList();

  List<TodoItem> get _filteredPendingTodos {
    if (_categoryFilter == '全部') {
      return _pendingTodos;
    }
    return _pendingTodos
        .where((todo) => todo.category == _categoryFilter)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _maybeHandleQuickAction();
  }

  @override
  void didUpdateWidget(covariant PlanModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  void _maybeHandleQuickAction() {
    if (widget.quickAction != WidgetQuickAction.addTodo ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 来自桌面小组件的“加待办”会直接拉起待办详情表单。
      _showAddTodoSheet();
      widget.onQuickActionHandled();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _PlanHeader(
                  selectedDay: _selectedDay,
                  onDayChanged: (day) => setState(() => _selectedDay = day),
                  onOpenModules: widget.onOpenModules,
                  onOpenMore: _openMoreSheet,
                ),
                _ModuleLinkStrip(
                  selected: LifeModule.plan,
                  onSwitchModule: widget.onSwitchModule,
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildTabContent()),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _PlanBottomNav(
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton(
          onPressed: _showAddTodoSheet,
          tooltip: 'Add',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 9,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 34),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 1) {
      return _TrayView(todos: _completedTodos);
    }
    if (_selectedTab == 2) {
      // 计划回顾读取父级共享数据，把饮食和锻炼的记录汇总到同一个复盘入口。
      return _PlanStatsView(
        todos: widget.todos,
        events: widget.events,
        foodCalories: widget.foodCalories,
        workoutGroups: widget.workoutGroups,
      );
    }
    return _TodoList(
      todos: _filteredPendingTodos,
      activeFilter: _categoryFilter,
      onToggle: _toggleTodo,
    );
  }

  void _toggleTodo(TodoItem todo) {
    widget.onToggleTodo(todo);
  }

  void _openMoreSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _PlanMoreSheet(
          activeFilter: _categoryFilter,
          completedCount: _completedTodos.length,
          onSelectFilter: (category) {
            Navigator.of(sheetContext).pop();
            setState(() {
              _categoryFilter = category;
              _selectedTab = 0;
            });
          },
          onClearCompleted: () {
            final count = _completedTodos.length;
            Navigator.of(sheetContext).pop();
            if (count == 0) {
              return;
            }
            widget.onClearCompletedTodos();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已清理 $count 项完成记录'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTodoSheet() {
    final titleController = TextEditingController();
    final categories = [
      ('生活', const Color(0xFF7D9CFF)),
      ('健康', const Color(0xFFFF6F9D)),
      ('工作', const Color(0xFF9278F7)),
      ('财务', AppColors.success),
    ];
    var selectedCategory = categories.first;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 20),
                  const Text(
                    '添加待办',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '输入要完成的事情',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: categories.map((category) {
                      final selected = selectedCategory.$1 == category.$1;
                      return ChoiceChip(
                        label: Text(category.$1),
                        selected: selected,
                        selectedColor: category.$2.withValues(alpha: 0.16),
                        backgroundColor: AppColors.background,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: selected ? category.$2 : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(
                          color: selected ? category.$2 : Colors.transparent,
                        ),
                        onSelected: (_) {
                          setSheetState(() => selectedCategory = category);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          return;
                        }
                        widget.onAddTodo(
                          TodoItem(
                            title: title,
                            category: selectedCategory.$1,
                            color: selectedCategory.$2,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '保存',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.selectedDay,
    required this.onDayChanged,
    required this.onOpenModules,
    required this.onOpenMore,
  });

  final int selectedDay;
  final ValueChanged<int> onDayChanged;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    const days = [
      ('日', 18),
      ('一', 19),
      ('二', 20),
      ('三', 21),
      ('四', 22),
      ('五', 23),
      ('六', 24),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        children: [
          Row(
            children: [
              _IconBubble(
                icon: Icons.view_sidebar_rounded,
                color: const Color(0xFF91A3FF),
                onTap: onOpenModules,
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    '2026年5月',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _IconBubble(
                icon: Icons.more_horiz_rounded,
                color: AppColors.primary,
                onTap: onOpenMore,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final selected = selectedDay == day.$2;
              return _DatePill(
                week: day.$1,
                day: day.$2,
                selected: selected,
                onTap: () => onDayChanged(day.$2),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF9AA0AD),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.week,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final String week;
  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              week,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$day',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: selected ? Colors.white : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList({
    required this.todos,
    required this.activeFilter,
    required this.onToggle,
  });

  final List<TodoItem> todos;
  final String activeFilter;
  final ValueChanged<TodoItem> onToggle;

  @override
  Widget build(BuildContext context) {
    final filtered = activeFilter != '全部';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
      children: [
        Text(
          filtered
              ? '待完成  ${todos.length} · $activeFilter'
              : '待完成  ${todos.length}',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (todos.isEmpty)
          _EmptyCard(
            title: filtered ? '这个类别没有待办' : '今天都完成了',
            subtitle: filtered ? '切回全部或添加新的$activeFilter事项' : '可以去待办箱回看已经完成的事项',
          )
        else
          ...todos.map(
            (todo) => _TodoCard(
              todo: todo,
              onTap: () => onToggle(todo),
            ),
          ),
      ],
    );
  }
}

class _PlanMoreSheet extends StatelessWidget {
  const _PlanMoreSheet({
    required this.activeFilter,
    required this.completedCount,
    required this.onSelectFilter,
    required this.onClearCompleted,
  });

  final String activeFilter;
  final int completedCount;
  final ValueChanged<String> onSelectFilter;
  final VoidCallback onClearCompleted;

  @override
  Widget build(BuildContext context) {
    const categories = ['全部', '生活', '健康', '工作', '财务'];

    return _InfoSheetFrame(
      title: '待办选项',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '筛选类别',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories.map((category) {
              return ChoiceChip(
                key: ValueKey('plan_filter_$category'),
                label: Text(category),
                selected: activeFilter == category,
                selectedColor: AppColors.primarySoft,
                backgroundColor: AppColors.surface,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: activeFilter == category
                      ? AppColors.primary
                      : AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: activeFilter == category
                      ? AppColors.primary
                      : Colors.transparent,
                ),
                onSelected: (_) => onSelectFilter(category),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: completedCount == 0 ? null : onClearCompleted,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.financeRed,
                side: BorderSide(
                  color: completedCount == 0
                      ? AppColors.muted.withValues(alpha: 0.24)
                      : AppColors.financeRed.withValues(alpha: 0.32),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.cleaning_services_rounded, size: 19),
              label: Text(
                '清理已完成 ($completedCount)',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.onTap,
  });

  final TodoItem todo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8C0D9).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: todo.done ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        todo.done ? AppColors.primary : const Color(0xFFE0E4EF),
                    width: 2,
                  ),
                ),
                child: todo.done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        decoration:
                            todo.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: todo.color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        todo.category,
                        style: TextStyle(
                          color: todo.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrayView extends StatelessWidget {
  const _TrayView({required this.todos});

  final List<TodoItem> todos;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
      children: [
        Text(
          '待办箱  ${todos.length}',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (todos.isEmpty)
          const _EmptyCard(
            title: '还没有完成记录',
            subtitle: '在待办页点击圆圈后，会归档到这里',
          )
        else
          ...todos.map(
            (todo) => _DoneCard(todo: todo),
          ),
      ],
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.todo});

  final TodoItem todo;

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
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              todo.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            todo.category,
            style: TextStyle(
              color: todo.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStatsView extends StatelessWidget {
  const _PlanStatsView({
    required this.todos,
    required this.events,
    required this.foodCalories,
    required this.workoutGroups,
  });

  final List<TodoItem> todos;
  final List<LifeEvent> events;
  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    final total = todos.length;
    final done = todos.where((todo) => todo.done).length;
    final percent = total == 0 ? 0 : (done * 100 / total).round();
    final linkedInsight = foodCalories == 0 && workoutGroups == 0
        ? '记录饮食和锻炼后，计划会自动把摄入、训练和待办放在一起复盘。'
        : '饮食 $foodCalories kcal，锻炼 $workoutGroups 组，今天的计划可以按真实状态微调。';
    // 这里把其它模块的实时记录编进计划复盘，让计划页不只是待办清单。
    final moments = <(String, String)>[
      ('☕', '优品豆浆（小杯）喝了三次'),
      ('🍽️', '饮食模块今日已记录 $foodCalories kcal'),
      ('🏋️', '锻炼模块今日已完成 $workoutGroups 组'),
      ('📘', '$total 项 todo 已完成 $done 项'),
      ('🛍️', '周六还了一笔 500 元的手机分期'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
      children: [
        _WeeklyProgressCard(
          percent: percent,
          done: done,
          total: total,
        ),
        const SizedBox(height: 16),
        _PlanLinkedReviewCard(
          foodCalories: foodCalories,
          workoutGroups: workoutGroups,
        ),
        const SizedBox(height: 16),
        _LifeEventFeedCard(events: events.take(4).toList()),
        const SizedBox(height: 16),
        const _ReviewSectionTitle(
          icon: Icons.auto_awesome_rounded,
          title: '被看见的瞬间',
        ),
        const SizedBox(height: 10),
        _MomentListCard(moments: moments),
        const SizedBox(height: 18),
        const _ReviewSectionTitle(
          icon: Icons.grid_view_rounded,
          title: '你这周的几个模式',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: _InsightCard(
                title: '周五和周六的错位',
                body: '周五消费 283 元，周六没有记录任何饮食；周六消费 591 元，饮食只有 241 卡。',
                icon: Icons.wallet_rounded,
                accent: Color(0xFF7F7AF7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InsightCard(
                title: '状态同步',
                body: linkedInsight,
                icon: Icons.hub_rounded,
                accent: Color(0xFF7D9CFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _ReviewSectionTitle(
          icon: Icons.layers_rounded,
          title: '这段时间的几个数字',
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.58,
          children: [
            const _NumberCard(
              icon: Icons.directions_walk_rounded,
              value: '20,885步',
              label: '总步数',
              color: Color(0xFF7D9CFF),
            ),
            const _NumberCard(
              icon: Icons.payments_rounded,
              value: '499.96元',
              label: '最大单笔',
              color: Color(0xFFE85C59),
            ),
            _NumberCard(
              icon: Icons.local_fire_department_rounded,
              value: '$foodCalories kcal',
              label: '饮食摄入',
              color: Color(0xFFB88955),
            ),
            _NumberCard(
              icon: Icons.fact_check_rounded,
              value: '$done项',
              label: '完成 todo',
              color: AppColors.primary,
            ),
            _NumberCard(
              icon: Icons.fitness_center_rounded,
              value: '$workoutGroups 组',
              label: '锻炼完成',
              color: AppColors.success,
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanLinkedReviewCard extends StatelessWidget {
  const _PlanLinkedReviewCard({
    required this.foodCalories,
    required this.workoutGroups,
  });

  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    return _ModuleLinkedSummaryCard(
      title: '计划联动',
      subtitle: '把饮食、锻炼和待办合成同一个本周复盘入口。',
      icon: Icons.hub_rounded,
      values: [
        ('饮食', '$foodCalories kcal'),
        ('锻炼', '$workoutGroups 组'),
      ],
    );
  }
}

class _ModuleLinkedSummaryCard extends StatelessWidget {
  const _ModuleLinkedSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.values,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<(String label, String value)> values;

  @override
  Widget build(BuildContext context) {
    // 所有模块共用这个摘要卡片，保证跨模块数据的展示口径一致。
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
          const SizedBox(width: 12),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final entry in values)
                  _LinkedValue(label: entry.$1, value: entry.$2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeEventFeedCard extends StatelessWidget {
  const _LifeEventFeedCard({required this.events});

  final List<LifeEvent> events;

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '联动记录',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Text(
              '完成待办、记录饮食或开始训练后，会在这里形成时间线。',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...List.generate(events.length, (index) {
              final event = events[index];
              return _LifeEventRow(
                event: event,
                showDivider: index != events.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _LifeEventRow extends StatelessWidget {
  const _LifeEventRow({
    required this.event,
    required this.showDivider,
  });

  final LifeEvent event;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(event.icon, color: event.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.detail,
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
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFE9ECF4)),
      ],
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({
    required this.percent,
    required this.done,
    required this.total,
  });

  final int percent;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.primarySoft,
                  color: AppColors.primary,
                ),
                Center(
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '本周回顾',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '已完成 $done 项，还有 ${total - done} 项待处理',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSectionTitle extends StatelessWidget {
  const _ReviewSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MomentListCard extends StatelessWidget {
  const _MomentListCard({required this.moments});

  final List<(String, String)> moments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(moments.length, (index) {
          final moment = moments[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Text(moment.$1, style: const TextStyle(fontSize: 21)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        moment.$2,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index != moments.length - 1)
                const Divider(height: 1, color: Color(0xFFE9ECF4)),
            ],
          );
        }),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 172),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              height: 1.45,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(icon, color: accent, size: 36),
          ),
        ],
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
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
          ),
        ],
      ),
    );
  }
}

class FinanceModulePage extends StatefulWidget {
  const FinanceModulePage({
    super.key,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.foodCalories,
    required this.workoutGroups,
    required this.records,
    required this.onAddRecord,
    required this.onEditRecord,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final int foodCalories;
  final int workoutGroups;
  final List<FinanceRecord> records;
  final ValueChanged<FinanceRecord> onAddRecord;
  final void Function(FinanceRecord oldRecord, FinanceRecord newRecord)
      onEditRecord;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<FinanceModulePage> createState() => _FinanceModulePageState();
}

class _FinanceModulePageState extends State<FinanceModulePage> {
  int _selectedTab = 0;
  bool _showExpense = true;
  String _trendRange = '7天';
  int _handledQuickActionToken = 0;
  String _aiEndpoint = 'https://api.openai.com/v1/chat/completions';
  String _aiModel = 'gpt-4o-mini';
  String _aiApiKey = '';

  @override
  void initState() {
    super.initState();
    _maybeHandleQuickAction(isInitial: true);
  }

  @override
  void didUpdateWidget(covariant FinanceModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  void _maybeHandleQuickAction({bool isInitial = false}) {
    if (widget.quickAction != WidgetQuickAction.addFinance ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    if (isInitial) {
      _selectedTab = 1;
    } else {
      setState(() => _selectedTab = 1);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 小组件点击“记账”后，直达财务记录页并打开可编辑明细。
      _openRecordSheet();
      widget.onQuickActionHandled();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _FinanceHeader(
                  onOpenModules: widget.onOpenModules,
                  onAddRecord: _openRecordSheet,
                  onAiRecord: _openAiRecordSheet,
                ),
                _ModuleLinkStrip(
                  selected: LifeModule.finance,
                  onSwitchModule: widget.onSwitchModule,
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildContent()),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _FinanceBottomNav(
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTab == 1) {
      return _FinanceRecordsView(
        records: widget.records,
        onAddRecord: widget.onAddRecord,
        onEditRecord: widget.onEditRecord,
        onAiRecord: _openAiRecordSheet,
      );
    }
    if (_selectedTab == 2) {
      return const _FinanceAssetsView();
    }
    return _FinanceOverviewView(
      showExpense: _showExpense,
      trendRange: _trendRange,
      records: widget.records,
      foodCalories: widget.foodCalories,
      workoutGroups: widget.workoutGroups,
      onOpenAssets: () => setState(() => _selectedTab = 2),
      onOpenRecords: () => setState(() => _selectedTab = 1),
      onAddRecord: _openRecordSheet,
      onAiRecord: _openAiRecordSheet,
      onToggleTrend: (showExpense) =>
          setState(() => _showExpense = showExpense),
      onChangeTrendRange: (range) => setState(() => _trendRange = range),
    );
  }

  void _openRecordSheet({FinanceRecord? record}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FinanceRecordSheet(
          record: record,
          onSave: (newRecord) {
            Navigator.of(context).pop();
            if (record == null) {
              widget.onAddRecord(newRecord);
            } else {
              widget.onEditRecord(record, newRecord);
            }
          },
        );
      },
    );
  }

  void _openAiRecordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AiFinanceRecordSheet(
          endpoint: _aiEndpoint,
          model: _aiModel,
          apiKey: _aiApiKey,
          onConfigChanged: ({
            required endpoint,
            required model,
            required apiKey,
          }) {
            _aiEndpoint = endpoint;
            _aiModel = model;
            _aiApiKey = apiKey;
          },
          onSaveAll: (records) {
            Navigator.of(context).pop();
            setState(() => _selectedTab = 1);
            // 父级插入逻辑是 insert(0)，这里反向写入能保持 AI 返回顺序。
            for (final record in records.reversed) {
              widget.onAddRecord(record);
            }
          },
        );
      },
    );
  }
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader({
    required this.onOpenModules,
    required this.onAddRecord,
    required this.onAiRecord,
  });

  final VoidCallback onOpenModules;
  final VoidCallback onAddRecord;
  final VoidCallback onAiRecord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
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
                '财务',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _IconBubble(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.primary,
            onTap: onAiRecord,
          ),
          const SizedBox(width: 8),
          _IconBubble(
            icon: Icons.add_card_rounded,
            color: AppColors.success,
            onTap: onAddRecord,
          ),
        ],
      ),
    );
  }
}

class _FinanceOverviewView extends StatelessWidget {
  const _FinanceOverviewView({
    required this.showExpense,
    required this.trendRange,
    required this.records,
    required this.foodCalories,
    required this.workoutGroups,
    required this.onOpenAssets,
    required this.onOpenRecords,
    required this.onAddRecord,
    required this.onAiRecord,
    required this.onToggleTrend,
    required this.onChangeTrendRange,
  });

  final bool showExpense;
  final String trendRange;
  final List<FinanceRecord> records;
  final int foodCalories;
  final int workoutGroups;
  final VoidCallback onOpenAssets;
  final VoidCallback onOpenRecords;
  final VoidCallback onAddRecord;
  final VoidCallback onAiRecord;
  final ValueChanged<bool> onToggleTrend;
  final ValueChanged<String> onChangeTrendRange;

  @override
  Widget build(BuildContext context) {
    final income = _financeTotal(records, '收入');
    final expense = _financeTotal(records, '支出');
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 128),
      children: [
        _NetAssetCard(
          income: income,
          expense: expense,
          onOpenAssets: onOpenAssets,
          onAddRecord: onAddRecord,
        ),
        const SizedBox(height: 14),
        _FinanceAiRecordCard(onTap: onAiRecord),
        const SizedBox(height: 14),
        _FinanceBudgetCard(
          expense: expense,
          recordCount: records.length,
        ),
        const SizedBox(height: 14),
        _ModuleLinkedSummaryCard(
          title: '财务联动',
          subtitle: '把饮食和锻炼同步到消费复盘，避免只看金额。',
          icon: Icons.account_balance_wallet_rounded,
          values: [
            ('饮食', '$foodCalories kcal'),
            ('锻炼', '$workoutGroups 组'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _FinanceMetricCard(
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFF58CE82),
                label: '本月收入',
                value: _formatMoney(income),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _FinanceMetricCard(
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFFFF766D),
                label: '本月支出',
                value: _formatMoney(expense),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _FinanceMetricCard(
                icon: Icons.sync_alt_rounded,
                iconColor: const Color(0xFF72C55D),
                label: '净现金流',
                value: _formatMoney(income - expense),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _FinanceMetricCard(
                icon: Icons.inventory_2_rounded,
                iconColor: const Color(0xFFF7BB4B),
                label: '本月待复核/总数',
                value: '0/${records.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _FinanceCategoryCard(records: records),
        const SizedBox(height: 14),
        _RecentFinanceRecordsCard(
          records: records,
          onOpenRecords: onOpenRecords,
        ),
        const SizedBox(height: 14),
        _TrendCard(
          showExpense: showExpense,
          trendRange: trendRange,
          onToggleTrend: onToggleTrend,
          onChangeRange: onChangeTrendRange,
        ),
      ],
    );
  }
}

class _NetAssetCard extends StatelessWidget {
  const _NetAssetCard({
    required this.income,
    required this.expense,
    required this.onOpenAssets,
    required this.onAddRecord,
  });

  final double income;
  final double expense;
  final VoidCallback onOpenAssets;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    final cashflow = income - expense;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFE9EDFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 0,
            child: _FinanceIllustration(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '净资产',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¥1,555.00',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _FinanceHeroPill(
                    label: '收入',
                    value: _formatMoney(income),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _FinanceHeroPill(
                    label: '支出',
                    value: _formatMoney(expense),
                    color: AppColors.financeRed,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _FinanceHeroPill(
                label: '现金流',
                value: _formatMoney(cashflow),
                color: cashflow >= 0 ? AppColors.primary : AppColors.financeRed,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenAssets,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.account_balance_rounded, size: 17),
                      label: const Text(
                        '查看资产详情',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAddRecord,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        '记一笔',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceHeroPill extends StatelessWidget {
  const _FinanceHeroPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceBudgetCard extends StatelessWidget {
  const _FinanceBudgetCard({
    required this.expense,
    required this.recordCount,
  });

  final double expense;
  final int recordCount;

  @override
  Widget build(BuildContext context) {
    const budget = 2500.0;
    final progress = (expense / budget).clamp(0.0, 1.0);
    final remaining = math.max(0.0, budget - expense);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '本月预算',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '剩余 ${_formatMoney(remaining)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: AppColors.primarySoft,
              color: progress > 0.82 ? AppColors.financeRed : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BudgetMiniStat(label: '预算', value: _formatMoney(budget)),
              _BudgetMiniStat(label: '已用', value: _formatMoney(expense)),
              _BudgetMiniStat(label: '记录', value: '$recordCount 笔'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetMiniStat extends StatelessWidget {
  const _BudgetMiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
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
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceCategoryCard extends StatelessWidget {
  const _FinanceCategoryCard({required this.records});

  final List<FinanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final expenses = records.where((record) => record.type == '支出').toList();
    final total =
        expenses.fold<double>(0, (sum, record) => sum + record.amount);
    final byTitle = <String, double>{};
    for (final record in expenses) {
      byTitle.update(record.title, (value) => value + record.amount,
          ifAbsent: () => record.amount);
    }
    final entries = byTitle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '支出分类',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (topEntries.isEmpty)
            const Text(
              '还没有支出记录',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...topEntries.map((entry) {
              final ratio = total == 0 ? 0.0 : entry.value / total;
              return _FinanceCategoryRow(
                title: entry.key,
                amount: entry.value,
                ratio: ratio,
              );
            }),
        ],
      ),
    );
  }
}

class _FinanceCategoryRow extends StatelessWidget {
  const _FinanceCategoryRow({
    required this.title,
    required this.amount,
    required this.ratio,
  });

  final String title;
  final double amount;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _financeIconForTitle(title),
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      _formatMoney(amount),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: ratio.clamp(0.0, 1.0),
                    backgroundColor: AppColors.background,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentFinanceRecordsCard extends StatelessWidget {
  const _RecentFinanceRecordsCard({
    required this.records,
    required this.onOpenRecords,
  });

  final List<FinanceRecord> records;
  final VoidCallback onOpenRecords;

  @override
  Widget build(BuildContext context) {
    final recent = records.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '最近记录',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOpenRecords,
                child: const Text(
                  '查看全部',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...recent.map(
            (record) => _CompactFinanceRecordTile(record: record),
          ),
        ],
      ),
    );
  }
}

class _CompactFinanceRecordTile extends StatelessWidget {
  const _CompactFinanceRecordTile({required this.record});

  final FinanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: record.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(record.icon, color: record.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            record.displayAmount,
            style: TextStyle(
              color: record.color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceIllustration extends StatelessWidget {
  const _FinanceIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 106,
      child: Stack(
        children: [
          Positioned(
            right: 12,
            top: 0,
            child: Container(
              width: 74,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.query_stats_rounded,
                color: AppColors.primary,
                size: 35,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 6,
            child: Container(
              width: 44,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8B8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.monetization_on_rounded,
                color: Color(0xFFF6B63E),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceMetricCard extends StatelessWidget {
  const _FinanceMetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.showExpense,
    required this.trendRange,
    required this.onToggleTrend,
    required this.onChangeRange,
  });

  final bool showExpense;
  final String trendRange;
  final ValueChanged<bool> onToggleTrend;
  final ValueChanged<String> onChangeRange;

  @override
  Widget build(BuildContext context) {
    final values = _trendValues(showExpense, trendRange);
    final total = values.fold<double>(0, (sum, value) => sum + value).round();
    final unit = showExpense ? '支出' : '收入';

    return Container(
      height: 250,
      padding: const EdgeInsets.all(18),
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
                  '收支趋势',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SegmentButton(
                label: '支出',
                selected: showExpense,
                onTap: () => onToggleTrend(true),
              ),
              const SizedBox(width: 8),
              _SegmentButton(
                label: '收入',
                selected: !showExpense,
                onTap: () => onToggleTrend(false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RangeChip(
                label: '7天',
                selected: trendRange == '7天',
                onTap: () => onChangeRange('7天'),
              ),
              const SizedBox(width: 8),
              _RangeChip(
                label: '6个月',
                selected: trendRange == '6个月',
                onTap: () => onChangeRange('6个月'),
              ),
              const Spacer(),
              Text(
                '$trendRange$unit ¥$total',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _TrendPainter(
                values: values,
                range: trendRange,
                color: showExpense
                    ? AppColors.financeRed
                    : const Color(0xFF58CE82),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  List<double> _trendValues(bool showExpense, String range) {
    if (range == '6个月') {
      return showExpense
          ? const [410, 358, 492, 283, 591, 518]
          : const [2800, 3000, 3000, 3200, 3000, 3000];
    }
    return showExpense
        ? const [0, 0, 0, 2, 12, 15, 1, 14]
        : const [4, 6, 5, 7, 8, 9, 8, 10];
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.range,
    required this.color,
  });

  final List<double> values;
  final String range;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE9ECF4)
      ..strokeWidth = 1;
    final textStyle = TextStyle(
      color: AppColors.muted.withValues(alpha: 0.72),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    const left = 4.0;
    const right = 26.0;
    const top = 8.0;
    const bottom = 24.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    for (var i = 0; i <= 3; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), gridPaint);
    }

    final maxValue = math.max(1.0, values.reduce(math.max));
    final highLabel = maxValue.round().toString();
    final middleLabel = (maxValue * 2 / 3).round().toString();
    final lowLabel = (maxValue / 3).round().toString();
    final startLabel = range == '6个月' ? '1月' : '5/17';
    final endLabel = range == '6个月' ? '6月' : '5/23';

    _drawText(canvas, highLabel, Offset(size.width - 24, top - 2), textStyle);
    _drawText(canvas, middleLabel,
        Offset(size.width - 24, top + chartHeight / 3 - 5), textStyle);
    _drawText(canvas, lowLabel,
        Offset(size.width - 24, top + chartHeight * 2 / 3 - 5), textStyle);
    _drawText(
        canvas, '0', Offset(size.width - 14, top + chartHeight - 8), textStyle);
    _drawText(canvas, startLabel, Offset(left, size.height - 14), textStyle);
    _drawText(
        canvas, endLabel, Offset(size.width - 34, size.height - 14), textStyle);

    final points = List.generate(values.length, (index) {
      final x = left + chartWidth * index / (values.length - 1);
      final y = top + chartHeight * (1 - values[index] / maxValue);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final point = points[i];
      final controlX = (previous.dx + point.dx) / 2;
      path.cubicTo(
          controlX, previous.dy, controlX, point.dy, point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, top + chartHeight)
      ..lineTo(points.first.dx, top + chartHeight)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final last = points.last;
    canvas.drawCircle(last, 4, Paint()..color = Colors.white);
    canvas.drawCircle(
        last,
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return values != oldDelegate.values ||
        range != oldDelegate.range ||
        color != oldDelegate.color;
  }
}

class FinanceRecord {
  const FinanceRecord({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final String type;

  Color get color => type == '收入' ? AppColors.success : AppColors.financeRed;

  String get displayAmount {
    final prefix = type == '收入' ? '+' : '-';
    return '$prefix${_formatMoney(amount)}';
  }

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'type': type,
    };
  }

  static FinanceRecord fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '手动记录';
    return FinanceRecord(
      icon: _financeIconForTitle(title),
      title: title,
      subtitle: json['subtitle'] as String? ?? '手动记录',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: json['type'] as String? ?? '支出',
    );
  }
}

IconData _financeIconForTitle(String title) {
  return switch (title) {
    '三餐' => Icons.restaurant_rounded,
    '咖啡' => Icons.local_cafe_rounded,
    '交通' => Icons.directions_bus_rounded,
    '购物' => Icons.shopping_bag_rounded,
    '数码分期' => Icons.phone_iphone_rounded,
    '工资' => Icons.account_balance_wallet_rounded,
    '理财收益' => Icons.savings_rounded,
    '奖金' => Icons.emoji_events_rounded,
    '报销' => Icons.assignment_return_rounded,
    '红包' => Icons.redeem_rounded,
    '转账' => Icons.swap_horiz_rounded,
    '娱乐' => Icons.movie_rounded,
    '居家' => Icons.home_rounded,
    '医疗' => Icons.medical_services_rounded,
    '教育' => Icons.school_rounded,
    _ => Icons.receipt_long_rounded,
  };
}

double _financeTotal(List<FinanceRecord> records, String type) {
  return records
      .where((record) => record.type == type)
      .fold<double>(0, (total, record) => total + record.amount);
}

String _formatMoney(double value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  final sign = value < 0 ? '-' : '';
  return '$sign¥${buffer.toString()}.${parts.last}';
}

enum AiFinanceBillType { income, expense, transfer }

class AiFinanceBillInfo {
  const AiFinanceBillInfo({
    this.amount,
    this.time,
    this.note,
    this.category,
    this.type,
    this.account,
    this.fromAccount,
    this.toAccount,
    this.tags,
    this.confidence = 0.0,
  });

  final double? amount;
  final DateTime? time;
  final String? note;
  final String? category;
  final AiFinanceBillType? type;
  final String? account;
  final String? fromAccount;
  final String? toAccount;
  final List<String>? tags;
  final double confidence;

  AiFinanceBillInfo copyWith({
    double? amount,
    DateTime? time,
    String? note,
    String? category,
    AiFinanceBillType? type,
    String? account,
    String? fromAccount,
    String? toAccount,
    List<String>? tags,
    double? confidence,
  }) {
    return AiFinanceBillInfo(
      amount: amount ?? this.amount,
      time: time ?? this.time,
      note: note ?? this.note,
      category: category ?? this.category,
      type: type ?? this.type,
      account: account ?? this.account,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      tags: tags ?? this.tags,
      confidence: confidence ?? this.confidence,
    );
  }

  factory AiFinanceBillInfo.fromJson(Map<String, dynamic> json) {
    return AiFinanceBillInfo(
      amount: (json['amount'] as num?)?.toDouble(),
      time: _parseAiFinanceTime(json['time']),
      note: json['note'] as String? ?? json['merchant'] as String?,
      category: json['category'] as String?,
      type: _parseAiFinanceBillType(json['type']),
      account: json['account'] as String?,
      fromAccount:
          json['from_account'] as String? ?? json['fromAccount'] as String?,
      toAccount: json['to_account'] as String? ?? json['toAccount'] as String?,
      tags: _parseAiFinanceTags(json['tags'] ?? json['tag']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'amount': amount,
      'time': time?.toIso8601String(),
      'note': note,
      'category': category,
      'type': type?.name,
      'account': account,
      'from_account': fromAccount,
      'to_account': toAccount,
      'tags': tags,
      'confidence': confidence,
    };
  }

  static DateTime? _parseAiFinanceTime(dynamic value) {
    if (value is! String) {
      return null;
    }
    final raw = value.trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw) ??
        DateTime.tryParse(raw.replaceAll(RegExp(r'\s+'), ''));
  }

  static AiFinanceBillType? _parseAiFinanceBillType(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().toLowerCase();
    if (text.contains('income') || text == '收入') {
      return AiFinanceBillType.income;
    }
    if (text.contains('transfer') || text == '转账' || text == '轉帳') {
      return AiFinanceBillType.transfer;
    }
    if (text.contains('expense') || text == '支出') {
      return AiFinanceBillType.expense;
    }
    return null;
  }

  static List<String>? _parseAiFinanceTags(dynamic value) {
    if (value == null) {
      return null;
    }
    final tags = <String>[];
    if (value is String) {
      tags.addAll(
        value
            .split(RegExp(r'[,\n，、;；|]+'))
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty),
      );
    } else if (value is List) {
      tags.addAll(
        value
            .map((tag) => tag.toString().trim())
            .where((tag) => tag.isNotEmpty),
      );
    }
    return tags.isEmpty ? null : tags;
  }
}

class AiFinanceJsonParser {
  const AiFinanceJsonParser();

  List<AiFinanceBillInfo> parse(String response) {
    // 这部分沿用晚安记账的核心策略：优先找 JSON 数组，失败再找单个对象。
    final arrayBlock = _extractBalancedBlock(response, '[', ']');
    if (arrayBlock != null) {
      try {
        final decoded = jsonDecode(_cleanupJson(arrayBlock));
        if (decoded is List) {
          final bills = <AiFinanceBillInfo>[];
          for (final item in decoded) {
            final map = _asStringMap(item);
            if (map == null) {
              continue;
            }
            final bill = _sanitize(AiFinanceBillInfo.fromJson(map));
            if (bill != null) {
              bills.add(bill);
            }
          }
          if (bills.isNotEmpty) {
            return bills;
          }
        }
      } catch (_) {
        // AI 可能包 Markdown 或生成 JSON5 风格，继续走单对象兜底。
      }
    }

    final objectBlock = _extractBalancedBlock(response, '{', '}');
    if (objectBlock == null) {
      return const [];
    }
    try {
      final map = _asStringMap(jsonDecode(_cleanupJson(objectBlock)));
      if (map == null) {
        return const [];
      }
      final bill = _sanitize(AiFinanceBillInfo.fromJson(map));
      return bill == null ? const [] : [bill];
    } catch (_) {
      return const [];
    }
  }

  AiFinanceBillInfo? _sanitize(AiFinanceBillInfo bill) {
    final amount = bill.amount;
    if (amount == null || amount.abs() <= 0) {
      return null;
    }
    return bill.time == null ? bill.copyWith(time: DateTime.now()) : bill;
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  String _cleanupJson(String input) {
    final out = StringBuffer();
    var inString = false;
    var escaped = false;
    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (inString) {
        out.write(char);
        if (escaped) {
          escaped = false;
        } else if (char == '\\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }
      if (char == '"') {
        inString = true;
        out.write(char);
        continue;
      }
      if (char == ',') {
        var next = index + 1;
        while (next < input.length && input[next].trim().isEmpty) {
          next++;
        }
        if (next < input.length && (input[next] == '}' || input[next] == ']')) {
          continue;
        }
      }
      out.write(char);
    }
    return out.toString();
  }

  String? _extractBalancedBlock(String text, String open, String close) {
    final start = text.indexOf(open);
    if (start < 0) {
      return null;
    }
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = start; index < text.length; index++) {
      final char = text[index];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) {
        continue;
      }
      if (char == open) {
        depth++;
      } else if (char == close) {
        depth--;
        if (depth == 0) {
          return text.substring(start, index + 1);
        }
      }
    }
    return null;
  }
}

class AiFinancePromptBuilder {
  const AiFinancePromptBuilder();

  static const _expenseCategories = [
    '三餐',
    '餐饮',
    '咖啡',
    '奶茶',
    '交通',
    '购物',
    '数码分期',
    '娱乐',
    '居家',
    '通讯',
    '水电',
    '医疗',
    '教育',
  ];

  static const _incomeCategories = [
    '工资',
    '理财收益',
    '奖金',
    '报销',
    '红包',
    '兼职',
  ];

  String build({
    required String text,
    DateTime? now,
  }) {
    final ts = now ?? DateTime.now();
    final currentDate = '${ts.year}-${_pad(ts.month)}-${_pad(ts.day)}';
    final currentTime = '$currentDate ${_pad(ts.hour)}:${_pad(ts.minute)}';
    return '''从以下自然语言中提取记账信息，返回 JSON 数组。

当前时间：$currentTime

用户输入：
$text

分类列表：
支出：${_expenseCategories.join('、')}
收入：${_incomeCategories.join('、')}
账户列表：现金、支付宝、微信、银行卡、信用卡

输出要求：
- 只返回 JSON 数组，不要解释
- 即使只有一笔，也包成 [{...}]
- 多笔消费/收入拆成多条记录
- amount：支出为负数，收入为正数，转账为正数
- time：ISO8601 格式；“昨天/前天/早上/中午/晚上”等相对时间按当前时间推断
- note：15 字以内，优先商户/商品/用途
- category：从分类列表中选择最接近的一项
- type：income、expense 或 transfer
- account/from_account/to_account/tag/tags 可选

示例：
"昨天中午吃饭50，晚上奶茶12" → [{"amount":-50,"time":"${currentDate}T12:00:00","note":"吃饭","category":"三餐","type":"expense"},{"amount":-12,"time":"${currentDate}T19:00:00","note":"奶茶","category":"咖啡","type":"expense"}]
"工资到账3000" → [{"amount":3000,"time":"${currentDate}T09:00:00","note":"工资到账","category":"工资","type":"income"}]''';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}

class AiFinanceException implements Exception {
  const AiFinanceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiFinanceClient {
  AiFinanceClient({
    this.parser = const AiFinanceJsonParser(),
    this.promptBuilder = const AiFinancePromptBuilder(),
  });

  final AiFinanceJsonParser parser;
  final AiFinancePromptBuilder promptBuilder;

  Future<List<AiFinanceBillInfo>> parseText({
    required String text,
    required String apiKey,
    required String endpoint,
    required String model,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      throw const AiFinanceException('请先输入要记账的内容');
    }
    if (apiKey.trim().isEmpty) {
      throw const AiFinanceException('请先填写 AI 接口 Key');
    }

    final uri = _resolveEndpoint(endpoint);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      request.add(
        utf8.encode(
          jsonEncode({
            'model': model.trim().isEmpty ? 'gpt-4o-mini' : model.trim(),
            'temperature': 0.1,
            'messages': [
              {
                'role': 'system',
                'content': '你是严谨的记账信息提取器，只输出 JSON 数组。',
              },
              {
                'role': 'user',
                'content': promptBuilder.build(text: trimmedText),
              },
            ],
          }),
        ),
      );
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiFinanceException('AI 接口请求失败：${response.statusCode} $body');
      }
      final content = _extractChatContent(body);
      final bills = parser.parse(content);
      if (bills.isEmpty) {
        throw const AiFinanceException('AI 没有返回可用账单，请换一种说法再试');
      }
      return bills;
    } on AiFinanceException {
      rethrow;
    } catch (error) {
      throw AiFinanceException('AI 记账失败：$error');
    } finally {
      client.close(force: true);
    }
  }

  Uri _resolveEndpoint(String endpoint) {
    final raw = endpoint.trim().isEmpty
        ? 'https://api.openai.com/v1/chat/completions'
        : endpoint.trim();
    final uri = Uri.parse(raw);
    if (uri.path.isEmpty || uri.path == '/') {
      return uri.replace(path: '/v1/chat/completions');
    }
    if (uri.path.endsWith('/v1')) {
      return uri.replace(path: '${uri.path}/chat/completions');
    }
    if (uri.path.endsWith('/v1/')) {
      return uri.replace(path: '${uri.path}chat/completions');
    }
    return uri;
  }

  String _extractChatContent(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const AiFinanceException('AI 接口返回格式不是 JSON 对象');
    }
    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic> && message['content'] is String) {
          return message['content'] as String;
        }
        if (first['text'] is String) {
          return first['text'] as String;
        }
      }
    }
    throw const AiFinanceException('AI 接口返回中没有 message.content');
  }
}

class AiFinanceRecordDraft {
  AiFinanceRecordDraft({
    required this.bill,
    required this.record,
    this.selected = true,
  });

  final AiFinanceBillInfo bill;
  final FinanceRecord record;
  bool selected;
}

FinanceRecord _financeRecordFromAiBill(AiFinanceBillInfo bill) {
  final type = _financeTypeFromAiBill(bill);
  final title = _financeTitleFromAiBill(bill, type);
  final noteParts = [
    if ((bill.note ?? '').trim().isNotEmpty) bill.note!.trim(),
    if ((bill.account ?? '').trim().isNotEmpty) bill.account!.trim(),
    if (bill.type == AiFinanceBillType.transfer)
      '${bill.fromAccount ?? '转出'} → ${bill.toAccount ?? '转入'}',
    if ((bill.tags ?? const []).isNotEmpty) bill.tags!.join('、'),
  ];
  return FinanceRecord(
    icon: _financeIconForTitle(title),
    title: title,
    subtitle: noteParts.isEmpty ? 'AI 记账' : 'AI · ${noteParts.join(' · ')}',
    amount: bill.amount?.abs() ?? 0,
    type: type,
  );
}

String _financeTypeFromAiBill(AiFinanceBillInfo bill) {
  if (bill.type == AiFinanceBillType.income || (bill.amount ?? 0) > 0) {
    return '收入';
  }
  return '支出';
}

String _financeTitleFromAiBill(AiFinanceBillInfo bill, String type) {
  final raw = '${bill.category ?? ''} ${bill.note ?? ''}'.toLowerCase();
  if (type == '收入') {
    if (raw.contains('理财') || raw.contains('收益')) return '理财收益';
    if (raw.contains('奖金')) return '奖金';
    if (raw.contains('报销')) return '报销';
    if (raw.contains('红包')) return '红包';
    return '工资';
  }
  if (bill.type == AiFinanceBillType.transfer || raw.contains('转账')) {
    return '转账';
  }
  if (raw.contains('咖啡') || raw.contains('奶茶')) return '咖啡';
  if (raw.contains('交通') ||
      raw.contains('地铁') ||
      raw.contains('公交') ||
      raw.contains('打车')) {
    return '交通';
  }
  if (raw.contains('数码') || raw.contains('手机') || raw.contains('分期')) {
    return '数码分期';
  }
  if (raw.contains('购物') ||
      raw.contains('水果') ||
      raw.contains('衣') ||
      raw.contains('超市')) {
    return '购物';
  }
  if ((bill.category ?? '').trim().isNotEmpty) {
    return bill.category!.trim();
  }
  return '三餐';
}

class _FinanceRecordsView extends StatefulWidget {
  const _FinanceRecordsView({
    required this.records,
    required this.onAddRecord,
    required this.onEditRecord,
    required this.onAiRecord,
  });

  final List<FinanceRecord> records;
  final ValueChanged<FinanceRecord> onAddRecord;
  final void Function(FinanceRecord oldRecord, FinanceRecord newRecord)
      onEditRecord;
  final VoidCallback onAiRecord;

  @override
  State<_FinanceRecordsView> createState() => _FinanceRecordsViewState();
}

class _FinanceRecordsViewState extends State<_FinanceRecordsView> {
  String _filter = '全部';

  @override
  Widget build(BuildContext context) {
    final visibleRecords = _filter == '全部'
        ? widget.records
        : widget.records.where((record) => record.type == _filter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 128),
      children: [
        _FinanceMonthSummary(records: widget.records),
        const SizedBox(height: 14),
        _FinanceAddRecordCard(
          onTap: () => _openRecordSheet(),
        ),
        const SizedBox(height: 14),
        _FinanceAiRecordCard(onTap: widget.onAiRecord),
        const SizedBox(height: 14),
        Row(
          children: [
            _RangeChip(
              label: '全部',
              selected: _filter == '全部',
              onTap: () => setState(() => _filter = '全部'),
            ),
            const SizedBox(width: 8),
            _RangeChip(
              label: '支出',
              selected: _filter == '支出',
              onTap: () => setState(() => _filter = '支出'),
            ),
            const SizedBox(width: 8),
            _RangeChip(
              label: '收入',
              selected: _filter == '收入',
              onTap: () => setState(() => _filter = '收入'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...visibleRecords.map(
          (record) => _FinanceRecordTile(
            record: record,
            onTap: () => _openRecordSheet(record: record),
          ),
        ),
      ],
    );
  }

  void _openRecordSheet({FinanceRecord? record}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FinanceRecordSheet(
          record: record,
          onSave: (newRecord) {
            Navigator.of(context).pop();
            if (record == null) {
              widget.onAddRecord(newRecord);
            } else {
              widget.onEditRecord(record, newRecord);
            }
          },
        );
      },
    );
  }
}

class _FinanceAssetsView extends StatelessWidget {
  const _FinanceAssetsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 128),
      children: const [
        _AssetTotalCard(),
        SizedBox(height: 14),
        _AssetRatioCard(),
        SizedBox(height: 14),
        _AssetAccountTile(
          icon: Icons.account_balance_rounded,
          title: '银行卡',
          subtitle: '招商储蓄卡',
          amount: '¥1,200.00',
          color: AppColors.primary,
        ),
        _AssetAccountTile(
          icon: Icons.payments_rounded,
          title: '现金',
          subtitle: '零钱与备用金',
          amount: '¥355.00',
          color: AppColors.success,
        ),
        _AssetAccountTile(
          icon: Icons.credit_card_rounded,
          title: '信用卡',
          subtitle: '本月待还',
          amount: '-¥48.00',
          color: AppColors.financeRed,
        ),
      ],
    );
  }
}

class _FinanceMonthSummary extends StatelessWidget {
  const _FinanceMonthSummary({required this.records});

  final List<FinanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final income = _financeTotal(records, '收入');
    final expense = _financeTotal(records, '支出');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SmallFinanceStat(
              title: '收入',
              value: _formatMoney(income),
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SmallFinanceStat(
              title: '支出',
              value: _formatMoney(expense),
              color: AppColors.financeRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SmallFinanceStat(
              title: '结余',
              value: _formatMoney(income - expense),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallFinanceStat extends StatelessWidget {
  const _SmallFinanceStat({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
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
      ],
    );
  }
}

class _FinanceAddRecordCard extends StatelessWidget {
  const _FinanceAddRecordCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('finance_add_record'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_card_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '记一笔',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _FinanceAiRecordCard extends StatelessWidget {
  const _FinanceAiRecordCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('finance_ai_record'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI 记账',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _AiFinanceRecordSheet extends StatefulWidget {
  const _AiFinanceRecordSheet({
    required this.endpoint,
    required this.model,
    required this.apiKey,
    required this.onConfigChanged,
    required this.onSaveAll,
  });

  final String endpoint;
  final String model;
  final String apiKey;
  final void Function({
    required String endpoint,
    required String model,
    required String apiKey,
  }) onConfigChanged;
  final ValueChanged<List<FinanceRecord>> onSaveAll;

  @override
  State<_AiFinanceRecordSheet> createState() => _AiFinanceRecordSheetState();
}

class _AiFinanceRecordSheetState extends State<_AiFinanceRecordSheet> {
  final _client = AiFinanceClient();
  late final TextEditingController _inputController;
  late final TextEditingController _endpointController;
  late final TextEditingController _modelController;
  late final TextEditingController _apiKeyController;
  final List<AiFinanceRecordDraft> _drafts = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _endpointController = TextEditingController(text: widget.endpoint);
    _modelController = TextEditingController(text: widget.model);
    _apiKeyController = TextEditingController(text: widget.apiKey);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AI 记账',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _FinanceTextField(
                  keyValue: 'ai_finance_input',
                  controller: _inputController,
                  label: '自然语言记账',
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _FinanceTextField(
                  keyValue: 'ai_finance_endpoint',
                  controller: _endpointController,
                  label: 'API 地址',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _FinanceTextField(
                        keyValue: 'ai_finance_model',
                        controller: _modelController,
                        label: '模型',
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('ai_finance_api_key'),
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  _AiFinanceMessageCard(
                    icon: Icons.error_outline_rounded,
                    color: AppColors.financeRed,
                    message: _error!,
                  ),
                ],
                if (_drafts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const _ModuleSectionTitle(
                    icon: Icons.receipt_long_rounded,
                    title: '解析结果',
                  ),
                  const SizedBox(height: 10),
                  ..._drafts.map(
                    (draft) => _AiFinanceDraftTile(
                      draft: draft,
                      onChanged: (selected) {
                        setState(() => draft.selected = selected);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('run_ai_finance_parse'),
                  onPressed: _loading ? null : _parse,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_loading ? '解析中' : 'AI 解析'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('save_ai_finance_records'),
                  onPressed: _drafts.any((draft) => draft.selected)
                      ? _saveSelected
                      : null,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('保存全部'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _parse() async {
    setState(() {
      _loading = true;
      _error = null;
      _drafts.clear();
    });
    widget.onConfigChanged(
      endpoint: _endpointController.text.trim(),
      model: _modelController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );
    try {
      final bills = await _client.parseText(
        text: _inputController.text,
        endpoint: _endpointController.text,
        model: _modelController.text,
        apiKey: _apiKeyController.text,
      );
      setState(() {
        _drafts
          ..clear()
          ..addAll(
            bills.map(
              (bill) => AiFinanceRecordDraft(
                bill: bill,
                record: _financeRecordFromAiBill(bill),
              ),
            ),
          );
      });
    } on AiFinanceException catch (error) {
      setState(() => _error = error.message);
    } catch (error) {
      setState(() => _error = 'AI 记账失败：$error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _saveSelected() {
    final records = _drafts
        .where((draft) => draft.selected)
        .map((draft) => draft.record)
        .toList();
    if (records.isEmpty) {
      setState(() => _error = '请至少选择一笔记录');
      return;
    }
    widget.onSaveAll(records);
  }
}

class _AiFinanceMessageCard extends StatelessWidget {
  const _AiFinanceMessageCard({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFinanceDraftTile extends StatelessWidget {
  const _AiFinanceDraftTile({
    required this.draft,
    required this.onChanged,
  });

  final AiFinanceRecordDraft draft;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final record = draft.record;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: draft.selected,
            activeColor: AppColors.primary,
            onChanged: (value) => onChanged(value ?? false),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: record.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(record.icon, color: record.color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.subtitle,
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
          ),
          Text(
            record.displayAmount,
            style: TextStyle(
              color: record.color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceRecordSheet extends StatefulWidget {
  const _FinanceRecordSheet({
    required this.record,
    required this.onSave,
  });

  final FinanceRecord? record;
  final ValueChanged<FinanceRecord> onSave;

  @override
  State<_FinanceRecordSheet> createState() => _FinanceRecordSheetState();
}

class _FinanceRecordSheetState extends State<_FinanceRecordSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _amountController;
  late String _type;
  late (IconData, String) _category;

  static const _categories = [
    (Icons.restaurant_rounded, '三餐'),
    (Icons.local_cafe_rounded, '咖啡'),
    (Icons.directions_bus_rounded, '交通'),
    (Icons.shopping_bag_rounded, '购物'),
    (Icons.phone_iphone_rounded, '数码分期'),
    (Icons.account_balance_wallet_rounded, '工资'),
    (Icons.savings_rounded, '理财收益'),
  ];

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.type ?? '支出';
    _category = _categories.firstWhere(
      (category) => category.$2 == record?.title,
      orElse: () => _categories.first,
    );
    _titleController =
        TextEditingController(text: record?.title ?? _category.$2);
    _subtitleController =
        TextEditingController(text: record?.subtitle ?? '手动记录');
    _amountController =
        TextEditingController(text: record?.amount.toStringAsFixed(2) ?? '18');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 18),
            Text(
              widget.record == null ? '记一笔' : '编辑记录',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _RangeChip(
                  label: '支出',
                  selected: _type == '支出',
                  onTap: () => setState(() => _type = '支出'),
                ),
                const SizedBox(width: 8),
                _RangeChip(
                  label: '收入',
                  selected: _type == '收入',
                  onTap: () => setState(() => _type = '收入'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final selected = _category.$2 == category.$2;
                return ChoiceChip(
                  label: Text(category.$2),
                  avatar: Icon(
                    category.$1,
                    size: 16,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                  selected: selected,
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: AppColors.background,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : Colors.transparent,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _category = category;
                      _titleController.text = category.$2;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _FinanceTextField(
              keyValue: 'finance_record_title',
              controller: _titleController,
              label: '分类名称',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 10),
            _FinanceTextField(
              keyValue: 'finance_record_subtitle',
              controller: _subtitleController,
              label: '备注',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 10),
            _FinanceTextField(
              keyValue: 'finance_record_amount',
              controller: _amountController,
              label: '金额',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: const ValueKey('save_finance_record'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    final title = _titleController.text.trim();
    if (amount == null || amount <= 0 || title.isEmpty) {
      return;
    }
    widget.onSave(
      FinanceRecord(
        icon: _category.$1,
        title: title,
        subtitle: _subtitleController.text.trim().isEmpty
            ? '手动记录'
            : _subtitleController.text.trim(),
        amount: amount,
        type: _type,
      ),
    );
  }
}

class _FinanceTextField extends StatelessWidget {
  const _FinanceTextField({
    required this.keyValue,
    required this.controller,
    required this.label,
    required this.keyboardType,
    this.maxLines = 1,
  });

  final String keyValue;
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey(keyValue),
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FinanceRecordTile extends StatelessWidget {
  const _FinanceRecordTile({
    required this.record,
    required this.onTap,
  });

  final FinanceRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
                color: record.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(record.icon, color: record.color, size: 23),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.subtitle,
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
            ),
            Text(
              record.displayAmount,
              style: TextStyle(
                color: record.color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetTotalCard extends StatelessWidget {
  const _AssetTotalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          _AppIconMark(),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '净资产',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '¥1,555.00',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetRatioCard extends StatelessWidget {
  const _AssetRatioCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '资产占比',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Row(
              children: const [
                Expanded(
                  flex: 77,
                  child: ColoredBox(
                    color: AppColors.primary,
                    child: SizedBox(height: 14),
                  ),
                ),
                Expanded(
                  flex: 23,
                  child: ColoredBox(
                    color: AppColors.success,
                    child: SizedBox(height: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendDot(color: AppColors.primary, label: '银行卡 77%'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.success, label: '现金 23%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AssetAccountTile extends StatelessWidget {
  const _AssetAccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
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
                const SizedBox(height: 4),
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
            amount,
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

class FoodItem {
  const FoodItem({
    required this.emoji,
    required this.name,
    required this.calorie,
    required this.unit,
    required this.group,
  });

  final String emoji;
  final String name;
  final int calorie;
  final String unit;
  final String group;
}

class FoodModulePage extends StatefulWidget {
  const FoodModulePage({
    super.key,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.onRecordCalories,
    required this.foodCalories,
    required this.workoutGroups,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final ValueChanged<int> onRecordCalories;
  final int foodCalories;
  final int workoutGroups;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<FoodModulePage> createState() => _FoodModulePageState();
}

class _FoodModulePageState extends State<FoodModulePage> {
  final List<FoodItem> _foods = [
    const FoodItem(
        emoji: '🥗', name: '混合沙拉', calorie: 80, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🍣', name: '三文鱼寿司', calorie: 142, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🥪', name: '三明治', calorie: 250, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🍕', name: '披萨（芝士）', calorie: 266, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🥟', name: '水饺', calorie: 230, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🍱', name: '便当', calorie: 168, unit: '100 克', group: '常见'),
    const FoodItem(
        emoji: '🥯', name: '贝果', calorie: 257, unit: '100 克', group: '早餐'),
    const FoodItem(
        emoji: '🥟', name: '包子', calorie: 227, unit: '100 克', group: '早餐'),
    const FoodItem(
        emoji: '🍳', name: '煎蛋', calorie: 196, unit: '100 克', group: '早餐'),
    const FoodItem(
        emoji: '🥛', name: '豆浆', calorie: 31, unit: '100 毫升', group: '早餐'),
    const FoodItem(
        emoji: '🥣', name: '小米粥', calorie: 46, unit: '100 克', group: '汤粥'),
    const FoodItem(
        emoji: '🍲', name: '皮蛋瘦肉粥', calorie: 75, unit: '100 克', group: '汤粥'),
    const FoodItem(
        emoji: '🍜', name: '番茄蛋汤', calorie: 28, unit: '100 克', group: '汤粥'),
    const FoodItem(
        emoji: '🍚', name: '米饭', calorie: 116, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍜', name: '面条', calorie: 137, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍞', name: '全麦面包', calorie: 246, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🌽', name: '玉米', calorie: 112, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍠', name: '红薯', calorie: 90, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🥣', name: '燕麦片', calorie: 377, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍚', name: '糙米饭', calorie: 111, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🍜', name: '荞麦面', calorie: 120, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🥔', name: '土豆', calorie: 81, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🌾', name: '藜麦饭', calorie: 120, unit: '100 克', group: '主食杂粮'),
    const FoodItem(
        emoji: '🥚', name: '鸡蛋', calorie: 144, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🍗', name: '鸡胸肉', calorie: 133, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🥩', name: '牛肉', calorie: 125, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🥛', name: '纯牛奶', calorie: 54, unit: '100 毫升', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🧀', name: '无糖酸奶', calorie: 72, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🥛', name: '豆腐', calorie: 81, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🍖', name: '猪里脊', calorie: 155, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🍗', name: '鸡腿肉', calorie: 181, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🧀', name: '低脂奶酪', calorie: 180, unit: '100 克', group: '肉蛋奶'),
    const FoodItem(
        emoji: '🥚', name: '蛋白', calorie: 60, unit: '100 克', group: '低脂高蛋白'),
    const FoodItem(
        emoji: '🍗', name: '即食鸡胸', calorie: 120, unit: '100 克', group: '低脂高蛋白'),
    const FoodItem(
        emoji: '🥛', name: '希腊酸奶', calorie: 59, unit: '100 克', group: '低脂高蛋白'),
    const FoodItem(
        emoji: '🥩', name: '瘦牛肉', calorie: 106, unit: '100 克', group: '低脂高蛋白'),
    const FoodItem(
        emoji: '🐟', name: '鳕鱼', calorie: 88, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🦐', name: '虾仁', calorie: 99, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🦀', name: '蟹肉', calorie: 97, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🦑', name: '鱿鱼', calorie: 75, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🐟', name: '金枪鱼', calorie: 110, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🦪', name: '扇贝', calorie: 69, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🐟', name: '带鱼', calorie: 127, unit: '100 克', group: '海鲜水产'),
    const FoodItem(
        emoji: '🥦', name: '西兰花', calorie: 36, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🥬', name: '生菜', calorie: 16, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍅', name: '番茄', calorie: 15, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍎', name: '苹果', calorie: 53, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍌', name: '香蕉', calorie: 93, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🫐', name: '蓝莓', calorie: 57, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🥒', name: '黄瓜', calorie: 16, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🥕', name: '胡萝卜', calorie: 32, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍓', name: '草莓', calorie: 32, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🥑', name: '牛油果', calorie: 171, unit: '100 克', group: '蔬菜水果'),
    const FoodItem(
        emoji: '🍛', name: '番茄炒蛋', calorie: 91, unit: '100 克', group: '家常菜'),
    const FoodItem(
        emoji: '🥬', name: '清炒时蔬', calorie: 64, unit: '100 克', group: '家常菜'),
    const FoodItem(
        emoji: '🍗', name: '土豆炖鸡', calorie: 128, unit: '100 克', group: '家常菜'),
    const FoodItem(
        emoji: '🥩', name: '青椒牛肉', calorie: 142, unit: '100 克', group: '家常菜'),
    const FoodItem(
        emoji: '🍔', name: '汉堡', calorie: 256, unit: '100 克', group: '外卖快餐'),
    const FoodItem(
        emoji: '🍟', name: '薯条', calorie: 312, unit: '100 克', group: '外卖快餐'),
    const FoodItem(
        emoji: '🍜', name: '麻辣烫', calorie: 118, unit: '100 克', group: '外卖快餐'),
    const FoodItem(
        emoji: '🍱', name: '盖浇饭', calorie: 164, unit: '100 克', group: '外卖快餐'),
    const FoodItem(
        emoji: '☕', name: '美式咖啡', calorie: 1, unit: '100 毫升', group: '收藏'),
    const FoodItem(
        emoji: '🥤', name: '可乐', calorie: 43, unit: '100 毫升', group: '收藏'),
    const FoodItem(
        emoji: '🍵', name: '无糖绿茶', calorie: 0, unit: '100 毫升', group: '饮品'),
    const FoodItem(
        emoji: '🧋', name: '珍珠奶茶', calorie: 52, unit: '100 毫升', group: '饮品'),
    const FoodItem(
        emoji: '🧃', name: '橙汁', calorie: 45, unit: '100 毫升', group: '饮品'),
    const FoodItem(
        emoji: '🥤', name: '苏打水', calorie: 0, unit: '100 毫升', group: '饮品'),
    const FoodItem(
        emoji: '🥜', name: '坚果', calorie: 607, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🍫', name: '黑巧克力', calorie: 600, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🍪', name: '苏打饼干', calorie: 408, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🍦', name: '冰淇淋', calorie: 207, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🍰', name: '蛋糕', calorie: 347, unit: '100 克', group: '零食'),
    const FoodItem(
        emoji: '🥜', name: '杏仁', calorie: 578, unit: '100 克', group: '坚果种子'),
    const FoodItem(
        emoji: '🌰', name: '核桃', calorie: 646, unit: '100 克', group: '坚果种子'),
    const FoodItem(
        emoji: '🌻', name: '南瓜子', calorie: 559, unit: '100 克', group: '坚果种子'),
    const FoodItem(
        emoji: '🧂', name: '生抽', calorie: 63, unit: '100 毫升', group: '调味酱料'),
    const FoodItem(
        emoji: '🍯', name: '蜂蜜', calorie: 321, unit: '100 克', group: '调味酱料'),
    const FoodItem(
        emoji: '🥫', name: '番茄酱', calorie: 83, unit: '100 克', group: '调味酱料'),
    const FoodItem(
        emoji: '🍵', name: '拿铁咖啡', calorie: 50, unit: '100 毫升', group: '自定义'),
  ];

  final List<FoodItem> _selectedFoods = [];
  final TextEditingController _foodSearchController = TextEditingController();
  String _activeGroup = '常见';
  String _category = '三餐';
  String _foodQuery = '';
  int _handledQuickActionToken = 0;

  int get _totalCalories =>
      _selectedFoods.fold(0, (total, food) => total + food.calorie);

  @override
  void initState() {
    super.initState();
    _maybeHandleQuickAction();
  }

  @override
  void didUpdateWidget(covariant FoodModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  @override
  void dispose() {
    _foodSearchController.dispose();
    super.dispose();
  }

  void _maybeHandleQuickAction() {
    if (widget.quickAction != WidgetQuickAction.addFood ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 小组件“记饮食”打开自定义食物表单，用户可以马上补名称、热量和份量。
      setState(() => _activeGroup = '自定义');
      _openCustomFoodSheet();
      widget.onQuickActionHandled();
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _foodQuery.trim();
    final visibleFoods = _foods.where((food) {
      final groupMatches = query.isNotEmpty || food.group == _activeGroup;
      final queryMatches = query.isEmpty || food.name.contains(query);
      return groupMatches && queryMatches;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _FoodHeader(
                  category: _category,
                  onOpenModules: widget.onOpenModules,
                  onOpenCategories: _openCategorySheet,
                ),
                _ModuleLinkStrip(
                  selected: LifeModule.food,
                  onSwitchModule: widget.onSwitchModule,
                ),
                const SizedBox(height: 10),
                _FoodSearchBar(
                  category: _category,
                  controller: _foodSearchController,
                  onChanged: (value) => setState(() => _foodQuery = value),
                  onClear: _clearFoodSearch,
                ),
                _FoodTabs(
                  active: _activeGroup,
                  onChanged: (group) => setState(() => _activeGroup = group),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 112),
                    children: [
                      _ModuleLinkedSummaryCard(
                        title: '饮食联动',
                        subtitle: '已记录的摄入会同步到健康、计划和桌面入口。',
                        icon: Icons.restaurant_rounded,
                        values: [
                          ('今日', '${widget.foodCalories} kcal'),
                          ('锻炼', '${widget.workoutGroups} 组'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_activeGroup == '自定义')
                        _FoodAddCustomCard(onTap: _openCustomFoodSheet),
                      if (visibleFoods.isEmpty)
                        _FoodEmptyState(
                          group: _activeGroup,
                          query: query,
                          onAddCustom: _openCustomFoodSheet,
                        )
                      else
                        ...visibleFoods.map((food) {
                          return _FoodCard(
                            food: food,
                            onAdd: () =>
                                setState(() => _selectedFoods.add(food)),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _FoodSelectedBar(
                count: _selectedFoods.length,
                calories: _totalCalories,
                onRecord: _recordFoods,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFoodSearch() {
    _foodSearchController.clear();
    setState(() => _foodQuery = '');
  }

  void _recordFoods() {
    if (_selectedFoods.isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已记录 ${_selectedFoods.length} 项，$_totalCalories 千卡'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.onRecordCalories(_totalCalories);
    setState(_selectedFoods.clear);
  }

  void _openCategorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FoodCategorySheet(
          selected: _category,
          onSelect: (category) {
            Navigator.of(context).pop();
            setState(() => _category = category);
          },
        );
      },
    );
  }

  void _openCustomFoodSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CustomFoodSheet(
          initialName: _foodQuery.trim(),
          onSave: (name, calorie, unit) {
            Navigator.of(context).pop();
            setState(() {
              _foods.add(
                FoodItem(
                  emoji: '🍱',
                  name: name,
                  calorie: calorie,
                  unit: unit,
                  group: '自定义',
                ),
              );
              _activeGroup = '自定义';
              _foodSearchController.clear();
              _foodQuery = '';
            });
          },
        );
      },
    );
  }
}

class _FoodHeader extends StatelessWidget {
  const _FoodHeader({
    required this.category,
    required this.onOpenModules,
    required this.onOpenCategories,
  });

  final String category;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Row(
        children: [
          _IconBubble(
            icon: Icons.arrow_back_ios_new_rounded,
            color: AppColors.ink,
            onTap: onOpenModules,
          ),
          const Expanded(
            child: Center(
              child: Text(
                '添加食物',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _IconBubble(
            icon: Icons.grid_view_rounded,
            color: AppColors.primary,
            onTap: onOpenCategories,
          ),
        ],
      ),
    );
  }
}

class _FoodSearchBar extends StatelessWidget {
  const _FoodSearchBar({
    required this.category,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final String category;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8C0D9).withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.muted, size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const ValueKey('food_search_field'),
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '请输入食物名称',
                  hintStyle: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                tooltip: '清空',
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.muted,
                  size: 18,
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodTabs extends StatelessWidget {
  const _FoodTabs({
    required this.active,
    required this.onChanged,
  });

  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const quickGroups = ['常见', '收藏', '自定义'];
    const allGroups = [
      '常见',
      '早餐',
      '主食杂粮',
      '肉蛋奶',
      '低脂高蛋白',
      '海鲜水产',
      '蔬菜水果',
      '家常菜',
      '外卖快餐',
      '汤粥',
      '饮品',
      '零食',
      '坚果种子',
      '调味酱料',
      '收藏',
      '自定义',
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: quickGroups.map((group) {
            final selected = active == group;
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(group),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: Column(
                  children: [
                    Text(
                      group,
                      style: TextStyle(
                        color: selected ? AppColors.ink : AppColors.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: selected ? 20 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView(
            key: const ValueKey('food_group_scroller'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: allGroups.map((group) {
              return _FoodChip(
                label: group,
                selected: active == group,
                onTap: () => onChanged(group),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _FoodChip extends StatelessWidget {
  const _FoodChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('food_group_$label'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _FoodAddCustomCard extends StatelessWidget {
  const _FoodAddCustomCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('add_custom_food_button'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '添加自定义食物',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _FoodEmptyState extends StatelessWidget {
  const _FoodEmptyState({
    required this.group,
    required this.query,
    required this.onAddCustom,
  });

  final String group;
  final String query;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final isCustom = group == '自定义';
    final title = query.isEmpty ? '这里还没有食物' : '没有匹配的食物';
    final subtitle = query.isEmpty ? '添加常吃项后会出现在这里' : '换个关键词试试，或添加为自定义食物';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.muted, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isCustom) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAddCustom,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '添加自定义食物',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.food,
    required this.onAdd,
  });

  final FoodItem food;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onAdd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8C0D9).withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(food.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${food.calorie} 千卡 / ${food.unit}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomFoodSheet extends StatefulWidget {
  const _CustomFoodSheet({
    required this.initialName,
    required this.onSave,
  });

  final String initialName;
  final void Function(String name, int calorie, String unit) onSave;

  @override
  State<_CustomFoodSheet> createState() => _CustomFoodSheetState();
}

class _CustomFoodSheetState extends State<_CustomFoodSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _calorieController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _calorieController = TextEditingController(text: '120');
    _unitController = TextEditingController(text: '1 份');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '自定义食物',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _SheetTextField(
                keyName: 'custom_food_name',
                controller: _nameController,
                label: '食物名称',
                hint: '例如：燕麦酸奶',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SheetTextField(
                      keyName: 'custom_food_calorie',
                      controller: _calorieController,
                      label: '热量',
                      hint: '120',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetTextField(
                      keyName: 'custom_food_unit',
                      controller: _unitController,
                      label: '单位',
                      hint: '1 份',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const ValueKey('save_custom_food_button'),
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();
    final calorie = int.tryParse(_calorieController.text.trim());
    if (name.isEmpty || unit.isEmpty || calorie == null || calorie <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写有效的食物名称、热量和单位'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSave(name, calorie, unit);
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.keyName,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  final String keyName;
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey(keyName),
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FoodSelectedBar extends StatelessWidget {
  const _FoodSelectedBar({
    required this.count,
    required this.calories,
    required this.onRecord,
  });

  final int count;
  final int calories;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Container(
        height: 58,
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9FA8C7).withValues(alpha: 0.24),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '已选 $count 项 · $calories 千卡',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: onRecord,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '记录',
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

class _FoodCategorySheet extends StatelessWidget {
  const _FoodCategorySheet({
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const sections = [
      (
        '餐饮',
        Icons.restaurant_rounded,
        [
          ('三餐', '🍽️'),
          ('外卖', '🥡'),
          ('饮品', '🧋'),
          ('咖啡', '☕'),
          ('零食饮水', '🧃'),
          ('食材', '🥦'),
          ('烘焙甜品', '🍰'),
          ('酒水', '🍷'),
        ],
      ),
      (
        '交通',
        Icons.directions_car_filled_rounded,
        [
          ('打车', '🚙'),
          ('公共交通', '🚍'),
          ('火车', '🚄'),
          ('机票', '✈️'),
          ('共享单车', '🚲'),
          ('充电', '🔌'),
          ('停车', '🅿️'),
          ('加油', '⛽'),
          ('车辆维护', '🛠️'),
        ],
      ),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const _SheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              _IconBubble(
                icon: Icons.close_rounded,
                color: const Color(0xFF9A8FF7),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    '分类',
                    style: TextStyle(
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
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: sections.map((section) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModuleSectionTitle(icon: section.$2, title: section.$1),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.08,
                      children: section.$3.map((item) {
                        return _FoodCategoryTile(
                          emoji: item.$2,
                          label: item.$1,
                          selected: selected == item.$1,
                          onTap: () => onSelect(item.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCategoryTile extends StatelessWidget {
  const _FoodCategoryTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFE2B853) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutAction {
  const WorkoutAction({
    required this.name,
    required this.detail,
    required this.icon,
    required this.groups,
    required this.status,
  });

  final String name;
  final String detail;
  final IconData icon;
  final int groups;
  final String status;
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
    ),
    WorkoutAction(
      name: '宽握高位下拉',
      detail: '4组 × 12次 × 30kg',
      icon: Icons.fitness_center_rounded,
      groups: 4,
      status: '未开始',
    ),
    WorkoutAction(
      name: '器械推胸',
      detail: '4组 × 12次 × 20kg',
      icon: Icons.sports_gymnastics_rounded,
      groups: 4,
      status: '未开始',
    ),
    WorkoutAction(
      name: '坐姿绳索划船',
      detail: '4组 × 12次 × 30kg',
      icon: Icons.rowing_rounded,
      groups: 4,
      status: '未开始',
    ),
    WorkoutAction(
      name: '平板支撑',
      detail: '3组 × 60s',
      icon: Icons.self_improvement_rounded,
      groups: 3,
      status: '未开始',
    ),
  ];

  int _selectedTopTab = 0;
  int _selectedBottomTab = 1;
  WorkoutAction? _activeAction;
  int _handledQuickActionToken = 0;

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
        onBack: () => setState(() => _activeAction = null),
        onStartGroup: _finishNextGroup,
        onSwitchModule: widget.onSwitchModule,
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
                _ModuleLinkStrip(
                  selected: LifeModule.workout,
                  onSwitchModule: widget.onSwitchModule,
                ),
                const SizedBox(height: 12),
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
                padding: const EdgeInsets.only(bottom: 18),
                child: _WorkoutBottomNav(
                  selectedIndex: _selectedBottomTab,
                  onChanged: _handleBottomNav,
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 128),
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
        const SizedBox(height: 18),
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
              '${_actions.length} 添加动作',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._actions.map(
          (action) => _WorkoutActionCard(
            action: action,
            finishedGroups: _finishedGroupsFor(action),
            onTap: () => setState(() {
              _activeAction = action;
            }),
          ),
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
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 8),
          Text(
            finishedGroups >= totalGroups ? '今日训练已完成' : '下一步：$nextActionName',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text(
                  '开始动作',
                  style: TextStyle(fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutPlanView extends StatelessWidget {
  const _WorkoutPlanView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 128),
      children: const [
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 128),
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 128),
      children: const [
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

class _WorkoutActionDetailPage extends StatelessWidget {
  const _WorkoutActionDetailPage({
    required this.action,
    required this.finishedGroups,
    required this.onBack,
    required this.onStartGroup,
    required this.onSwitchModule,
  });

  final WorkoutAction action;
  final int finishedGroups;
  final VoidCallback onBack;
  final VoidCallback onStartGroup;
  final ValueChanged<LifeModule> onSwitchModule;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 112),
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
                      const Expanded(
                        child: _WorkoutProgressBox(
                          label: '当前休息',
                          value: '未开始',
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
                  const Text(
                    '开始后按组记录，完成一组会自动开启 2 分钟休息提醒。',
                    style: TextStyle(
                      color: AppColors.ink,
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
        child: _WorkoutBottomNav(
          selectedIndex: 1,
          onChanged: (index) {
            if (index == 0) {
              onSwitchModule(LifeModule.health);
            }
            if (index == 2) {
              onSwitchModule(LifeModule.food);
            }
          },
        ),
      ),
    );
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
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

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
    );
  }
}

class HealthMetric {
  const HealthMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bars,
    required this.hasData,
    required this.source,
    required this.statusText,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final List<double> bars;
  final bool hasData;
  final String source;
  final String statusText;
}

class HealthDay {
  const HealthDay({
    required this.date,
    required this.week,
    required this.day,
    required this.ringProgress,
    required this.ringLabels,
    required this.metrics,
    required this.statusMessage,
  });

  final DateTime date;
  final String week;
  final String day;
  final List<double> ringProgress;
  final List<String> ringLabels;
  final List<HealthMetric> metrics;
  final String statusMessage;

  String get title => '${date.month}月$day日⌄';
}

class HealthModulePage extends StatefulWidget {
  const HealthModulePage({
    super.key,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.foodCalories,
    required this.workoutGroups,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final int foodCalories;
  final int workoutGroups;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<HealthModulePage> createState() => _HealthModulePageState();
}

class _HealthModulePageState extends State<HealthModulePage> {
  static const _healthStore = _SystemHealthStore();

  var _selectedIndex = 0;
  int _handledQuickActionToken = 0;
  var _loadingHealth = true;
  HealthSystemSnapshot _systemHealth = HealthSystemSnapshot.loading();

  List<HealthDay> get _days => _buildHealthDays(_systemHealth);

  HealthDay get _selectedDay {
    final days = _days;
    final index = math.min(_selectedIndex, days.length - 1);
    return days[index];
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadSystemHealth());
    _maybeHandleQuickAction();
  }

  @override
  void didUpdateWidget(covariant HealthModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  void _maybeHandleQuickAction() {
    if (widget.quickAction != WidgetQuickAction.openHealth ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 小组件“健康详情”直达健康总览弹层，显示饮食和锻炼联动后的完整数据。
      _openSummarySheet();
      widget.onQuickActionHandled();
    });
  }

  Future<void> _loadSystemHealth() async {
    if (mounted) {
      setState(() => _loadingHealth = true);
    }
    final snapshot = await _healthStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _systemHealth = snapshot;
      _loadingHealth = false;
      _selectedIndex = math.max(0, _buildHealthDays(snapshot).length - 1);
    });
  }

  Future<void> _requestSystemHealthAccess() async {
    await _healthStore.requestPermissions();
    await _loadSystemHealth();
  }

  Future<void> _openSystemHealthSettings() async {
    await _healthStore.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    final selectedDay = _selectedDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 190),
              children: [
                _HealthHeader(
                  title: selectedDay.title,
                  onOpenModules: widget.onOpenModules,
                  onOpenSummary: _openSummarySheet,
                ),
                const SizedBox(height: 14),
                _ModuleLinkStrip(
                  selected: LifeModule.health,
                  onSwitchModule: widget.onSwitchModule,
                ),
                const SizedBox(height: 16),
                _HealthDateStrip(
                  days: days,
                  selectedDay: selectedDay,
                  onSelect: (day) {
                    setState(() => _selectedIndex = days.indexOf(day));
                  },
                ),
                const SizedBox(height: 16),
                _HealthSystemStatusCard(
                  snapshot: _systemHealth,
                  loading: _loadingHealth,
                  onRefresh: _loadSystemHealth,
                  onRequestPermission: _requestSystemHealthAccess,
                  onOpenSettings: _openSystemHealthSettings,
                ),
                const SizedBox(height: 14),
                _HealthRingsCard(day: selectedDay),
                const SizedBox(height: 14),
                _HealthLinkedSummaryCard(
                  foodCalories: widget.foodCalories,
                  workoutGroups: widget.workoutGroups,
                ),
                const SizedBox(height: 14),
                _HealthSensorCard(snapshot: _systemHealth.sensors),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: selectedDay.metrics
                      .map(
                        (metric) => _HealthMetricCard(
                          metric: metric,
                          onTap: () => _openMetricSheet(metric),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _WorkoutBottomNav(
                  selectedIndex: 0,
                  onChanged: (index) {
                    if (index == 1) {
                      widget.onSwitchModule(LifeModule.workout);
                    }
                    if (index == 2) {
                      widget.onSwitchModule(LifeModule.food);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMetricSheet(HealthMetric metric) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthMetricSheet(
        day: _selectedDay,
        metric: metric,
      ),
    );
  }

  void _openSummarySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthSummarySheet(
        day: _selectedDay,
        foodCalories: widget.foodCalories,
        workoutGroups: widget.workoutGroups,
      ),
    );
  }

  List<HealthDay> _buildHealthDays(HealthSystemSnapshot snapshot) {
    // 健康页只接受系统健康/传感器返回值；缺权限时保留真实日期但不填假指标。
    final samples = snapshot.days.isEmpty
        ? [HealthSystemDaySample.empty(DateTime.now())]
        : snapshot.days;
    return samples
        .map((sample) => _buildHealthDay(sample, samples, snapshot))
        .toList();
  }

  HealthDay _buildHealthDay(
    HealthSystemDaySample sample,
    List<HealthSystemDaySample> samples,
    HealthSystemSnapshot snapshot,
  ) {
    final stepsTrend = _trendValues(samples, (day) => day.steps);
    final activeTrend = _trendValues(samples, (day) => day.activeCaloriesKcal);
    final basalTrend = _trendValues(samples, (day) => day.basalCaloriesKcal);
    final sleepTrend = _trendValues(samples, (day) => day.sleepMinutes);
    final heartTrend = _trendValues(samples, (day) => day.heartRateBpm);
    final respiratoryTrend =
        _trendValues(samples, (day) => day.respiratoryRate);
    final sensorHeartRate = snapshot.sensors.heartRateBpm?.round();
    final heartRate = sample.heartRateBpm ?? sensorHeartRate;
    final heartSource = sample.heartRateBpm == null && sensorHeartRate != null
        ? '传感器实时'
        : 'Health Connect';

    return HealthDay(
      date: sample.date,
      week: _weekdayLabel(sample.date),
      day: sample.date.day.toString(),
      statusMessage: snapshot.message,
      ringProgress: [
        _progress(sample.steps, 10000),
        _progress(sample.activeCaloriesKcal, 500),
        snapshot.sensors.accelerometerAvailable ? 1.0 : 0.0,
      ],
      ringLabels: [
        _percentLabel(sample.steps, 10000),
        _percentLabel(sample.activeCaloriesKcal, 500),
        snapshot.sensors.accelerometerAvailable ? '已连接' : '无传感器',
      ],
      metrics: [
        _metric(
          title: '今日基础代谢',
          value: sample.basalCaloriesKcal?.round().toString(),
          unit: 'kcal',
          icon: Icons.bolt_rounded,
          color: const Color(0xFFFFD749),
          bars: basalTrend,
          source: 'Health Connect',
        ),
        _metric(
          title: '今日能量',
          value: sample.activeCaloriesKcal?.round().toString(),
          unit: 'kcal',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFFA14A),
          bars: activeTrend,
          source: 'Health Connect',
        ),
        _metric(
          title: '今日步数',
          value: _formatOptionalWhole(sample.steps),
          unit: '步',
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFF61CE86),
          bars: stepsTrend,
          source: 'Health Connect',
        ),
        _metric(
          title: '昨晚睡眠',
          value: _formatOptionalSleep(sample.sleepMinutes),
          unit: '小时',
          icon: Icons.dark_mode_rounded,
          color: const Color(0xFF8D7CF6),
          bars: sleepTrend,
          source: 'Health Connect',
        ),
        _metric(
          title: heartSource == '传感器实时' ? '实时心率' : '今日心率',
          value: heartRate?.toString(),
          unit: 'bpm',
          icon: Icons.favorite_rounded,
          color: const Color(0xFFFF7A83),
          bars: heartTrend,
          source: heartSource,
        ),
        _metric(
          title: '今日呼吸',
          value: sample.respiratoryRate?.toStringAsFixed(1),
          unit: '次/分',
          icon: Icons.air_rounded,
          color: const Color(0xFFB58CFF),
          bars: respiratoryTrend,
          source: 'Health Connect',
        ),
      ],
    );
  }

  HealthMetric _metric({
    required String title,
    required String? value,
    required String unit,
    required IconData icon,
    required Color color,
    required List<double> bars,
    required String source,
  }) {
    final hasData = value != null;
    return HealthMetric(
      title: title,
      value: value ?? '--',
      unit: hasData ? unit : '无系统记录',
      icon: icon,
      color: color,
      bars: hasData ? bars : const [],
      hasData: hasData,
      source: source,
      statusText: hasData ? source : _systemHealth.message,
    );
  }

  List<double> _trendValues(
    List<HealthSystemDaySample> samples,
    num? Function(HealthSystemDaySample sample) selector,
  ) {
    final values = <double>[];
    for (final sample in samples) {
      final value = selector(sample);
      if (value != null) {
        values.add(math.max(0, value.toDouble()));
      }
    }
    return values;
  }

  double _progress(num? value, num goal) {
    if (value == null || goal <= 0) {
      return 0;
    }
    return (value / goal).clamp(0.0, 1.0).toDouble();
  }

  String _percentLabel(num? value, num goal) {
    if (value == null || goal <= 0) {
      return '无数据';
    }
    return '${((value / goal) * 100).round()}%';
  }

  String _weekdayLabel(DateTime date) {
    final today = DateTime.now();
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return '今天';
    }
    return const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
  }

  String _formatWhole(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String? _formatOptionalWhole(int? value) {
    if (value == null) {
      return null;
    }
    return _formatWhole(value);
  }

  String? _formatOptionalSleep(int? minutes) {
    if (minutes == null) {
      return null;
    }
    return _formatSleep(minutes);
  }

  String _formatSleep(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return '${hours}h ${rest}m';
  }
}

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({
    required this.title,
    required this.onOpenModules,
    required this.onOpenSummary,
  });

  final String title;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenSummary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(
          icon: Icons.view_sidebar_rounded,
          color: const Color(0xFF91A3FF),
          onTap: onOpenModules,
        ),
        Expanded(
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        _IconBubble(
          icon: Icons.grid_view_rounded,
          color: AppColors.primary,
          onTap: onOpenSummary,
        ),
      ],
    );
  }
}

class _HealthDateStrip extends StatelessWidget {
  const _HealthDateStrip({
    required this.days,
    required this.selectedDay,
    required this.onSelect,
  });

  final List<HealthDay> days;
  final HealthDay selectedDay;
  final ValueChanged<HealthDay> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: days.map((day) {
            final selected = day.day == selectedDay.day;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelect(day),
                child: SizedBox(
                  width: 38,
                  child: Column(
                    children: [
                      Text(
                        day.week,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: CustomPaint(
                          painter: _MiniRingsPainter(
                            selected: selected,
                            progress: day.ringProgress,
                          ),
                          child: Center(
                            child: Text(
                              day.day,
                              style: TextStyle(
                                color:
                                    selected ? AppColors.ink : AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _HealthSystemStatusCard extends StatelessWidget {
  const _HealthSystemStatusCard({
    required this.snapshot,
    required this.loading,
    required this.onRefresh,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final HealthSystemSnapshot snapshot;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final title = loading
        ? '正在读取系统健康数据'
        : switch (snapshot.status) {
            SystemHealthStatus.ok => '系统健康数据已连接',
            SystemHealthStatus.permissionRequired => '需要 Health Connect 授权',
            SystemHealthStatus.updateRequired => '需要更新 Health Connect',
            SystemHealthStatus.error => '系统健康读取失败',
            SystemHealthStatus.loading => '正在读取系统健康数据',
            SystemHealthStatus.unavailable => '系统健康数据未连接',
          };
    final color = snapshot.isReady ? AppColors.success : AppColors.primary;

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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  snapshot.isReady
                      ? Icons.verified_rounded
                      : Icons.health_and_safety_rounded,
                  color: color,
                ),
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
                    const SizedBox(height: 4),
                    Text(
                      snapshot.message,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HealthStatusPill(
                label: 'Health Connect',
                value: snapshot.isReady ? '已授权' : '未授权',
              ),
              _HealthStatusPill(
                label: '传感器',
                value: snapshot.sensors.summary,
              ),
              _HealthStatusPill(
                label: '刷新',
                value: snapshot.lastUpdated == null
                    ? '未完成'
                    : _formatUpdated(snapshot.lastUpdated!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('刷新'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed:
                      snapshot.isReady ? onOpenSettings : onRequestPermission,
                  icon: Icon(
                    snapshot.isReady
                        ? Icons.settings_rounded
                        : Icons.lock_open_rounded,
                    size: 18,
                  ),
                  label: Text(snapshot.isReady ? '设置' : '授权'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatUpdated(DateTime value) {
    final local = value.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.hour}:$minute';
  }
}

class _HealthStatusPill extends StatelessWidget {
  const _HealthStatusPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthRingsCard extends StatelessWidget {
  const _HealthRingsCard({required this.day});

  final HealthDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 136,
            height: 136,
            child: CustomPaint(
              painter: _ActivityRingsPainter(progress: day.ringProgress),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RingLegend(
                  color: const Color(0xFF48CE81),
                  title: '步数',
                  value: day.ringLabels[0],
                ),
                const SizedBox(height: 12),
                _RingLegend(
                  color: const Color(0xFFFF9559),
                  title: '能量',
                  value: day.ringLabels[1],
                ),
                const SizedBox(height: 12),
                _RingLegend(
                  color: const Color(0xFF7D9CFF),
                  title: '传感',
                  value: day.ringLabels[2],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingLegend extends StatelessWidget {
  const _RingLegend({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
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
      ],
    );
  }
}

class _HealthLinkedSummaryCard extends StatelessWidget {
  const _HealthLinkedSummaryCard({
    required this.foodCalories,
    required this.workoutGroups,
  });

  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    return _ModuleLinkedSummaryCard(
      title: '模块联动',
      subtitle: '饮食和锻炼记录会同步影响健康总览。',
      icon: Icons.monitor_heart_rounded,
      values: [
        ('饮食', '$foodCalories kcal'),
        ('锻炼', '$workoutGroups 组'),
      ],
    );
  }
}

class _HealthSensorCard extends StatelessWidget {
  const _HealthSensorCard({required this.snapshot});

  final HealthSensorSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final values = [
      (
        '计步器',
        snapshot.stepCounterSinceBoot == null
            ? (snapshot.stepCounterAvailable ? '可用' : '无')
            : '${snapshot.stepCounterSinceBoot} 步'
      ),
      (
        '心率',
        snapshot.heartRateBpm == null
            ? (snapshot.heartRateSensorAvailable ? '待读取' : '无')
            : '${snapshot.heartRateBpm!.round()} bpm'
      ),
      (
        '加速度',
        snapshot.accelerationMagnitude == null
            ? (snapshot.accelerometerAvailable ? '可用' : '无')
            : snapshot.accelerationMagnitude!.toStringAsFixed(1)
      ),
    ];
    return _ModuleLinkedSummaryCard(
      title: '手机传感器',
      subtitle: '来自系统 SensorManager 的实时设备能力和读数。',
      icon: Icons.sensors_rounded,
      values: values,
    );
  }
}

class _LinkedValue extends StatelessWidget {
  const _LinkedValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HealthMetricCard extends StatelessWidget {
  const _HealthMetricCard({
    required this.metric,
    required this.onTap,
  });

  final HealthMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: metric.bars.isEmpty
                  ? Center(
                      child: Text(
                        metric.hasData ? metric.source : '等待系统数据',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _TinyBarsPainter(
                        values: metric.bars,
                        color: metric.color,
                      ),
                      child: const SizedBox.expand(),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(metric.icon, color: metric.color, size: 22),
              ],
            ),
            Text(
              metric.unit,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthMetricSheet extends StatelessWidget {
  const _HealthMetricSheet({
    required this.day,
    required this.metric,
  });

  final HealthDay day;
  final HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final average = metric.bars.isEmpty
        ? null
        : (metric.bars.fold<double>(0, (sum, value) => sum + value) /
                metric.bars.length)
            .toStringAsFixed(1);

    return _InfoSheetFrame(
      title: metric.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: metric.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(metric.icon, color: metric.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.title.replaceAll('⌄', ''),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.hasData
                            ? '${metric.value} ${metric.unit}'
                            : metric.value,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 120,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: metric.bars.isEmpty
                ? Center(
                    child: Text(
                      metric.statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _TinyBarsPainter(
                      values: metric.bars,
                      color: metric.color,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 14),
          _EmptyCard(
            title: '趋势摘要',
            subtitle: average == null
                ? '当前没有来自 ${metric.source} 的可用采样点。'
                : '最近 ${metric.bars.length} 个真实采样点平均值 $average，当前记录为 ${metric.value} ${metric.unit}。',
          ),
        ],
      ),
    );
  }
}

class _HealthSummarySheet extends StatelessWidget {
  const _HealthSummarySheet({
    required this.day,
    required this.foodCalories,
    required this.workoutGroups,
  });

  final HealthDay day;
  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    final steps = day.metrics.firstWhere((metric) => metric.title == '今日步数');
    final energy = day.metrics.firstWhere((metric) => metric.title == '今日能量');
    final sleep = day.metrics.firstWhere((metric) => metric.title == '昨晚睡眠');

    return _InfoSheetFrame(
      title: '健康总览',
      child: Column(
        children: [
          _HealthSummaryTile(
            color: const Color(0xFF48CE81),
            title: '活动完成',
            value: day.ringLabels[0],
          ),
          _HealthSummaryTile(
            color: const Color(0xFFFF9559),
            title: '能量消耗',
            value: '${energy.value} ${energy.unit}',
          ),
          _HealthSummaryTile(
            color: AppColors.primary,
            title: '饮食摄入',
            value: '$foodCalories kcal',
          ),
          _HealthSummaryTile(
            color: const Color(0xFF43C6C8),
            title: '锻炼完成',
            value: '$workoutGroups 组',
          ),
          _HealthSummaryTile(
            color: const Color(0xFF61CE86),
            title: '步数',
            value: '${steps.value} ${steps.unit}',
          ),
          _HealthSummaryTile(
            color: const Color(0xFF8D7CF6),
            title: '睡眠',
            value: sleep.value,
          ),
        ],
      ),
    );
  }
}

class _HealthSummaryTile extends StatelessWidget {
  const _HealthSummaryTile({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  const _ActivityRingsPainter({required this.progress});

  final List<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16;
    final rings = [
      (radius: 56.0, color: const Color(0xFF48CE81), value: progress[0]),
      (radius: 38.0, color: const Color(0xFFFF9559), value: progress[1]),
      (radius: 20.0, color: const Color(0xFF7D9CFF), value: progress[2]),
    ];

    for (final ring in rings) {
      paint.color = const Color(0xFFE9ECF4);
      canvas.drawCircle(center, ring.radius, paint);
      paint.color = ring.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ring.radius),
        -math.pi / 2,
        math.pi * 2 * ring.value,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _MiniRingsPainter extends CustomPainter {
  const _MiniRingsPainter({
    required this.selected,
    required this.progress,
  });

  final bool selected;
  final List<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = selected ? 2.7 : 2.2;
    final colors = [
      const Color(0xFF48CE81),
      const Color(0xFFFF9559),
      const Color(0xFF7D9CFF),
    ];

    for (var i = 0; i < 3; i++) {
      final radius = 15.0 - i * 4;
      paint.color = const Color(0xFFE7EAF2);
      canvas.drawCircle(center, radius, paint);
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress[i],
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRingsPainter oldDelegate) {
    return selected != oldDelegate.selected || progress != oldDelegate.progress;
  }
}

class _TinyBarsPainter extends CustomPainter {
  _TinyBarsPainter({
    required this.values,
    required this.color,
  });

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFE9ECF4)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      axisPaint,
    );
    if (values.isEmpty) {
      return;
    }

    final maxValue = math.max(1.0, values.reduce(math.max));
    final barWidth = size.width / (values.length * 1.55);
    final gap = barWidth * 0.55;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < values.length; i++) {
      final x = i * (barWidth + gap) + barWidth / 2;
      final height = (size.height - 8) * values[i] / maxValue;
      paint.strokeWidth = barWidth;
      canvas.drawLine(
        Offset(x, size.height - 4),
        Offset(x, size.height - 4 - height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TinyBarsPainter oldDelegate) {
    return values != oldDelegate.values || color != oldDelegate.color;
  }
}

class PlaceholderModulePage extends StatelessWidget {
  const PlaceholderModulePage({
    super.key,
    required this.module,
    required this.onOpenModules,
    required this.onSwitchModule,
  });

  final LifeModule module;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;

  @override
  Widget build(BuildContext context) {
    final info = switch (module) {
      LifeModule.food => (
          '饮食',
          Icons.restaurant_rounded,
          '下一张会按 1.png/2.png 做食物添加、分类选择、卡路里合计。'
        ),
      LifeModule.workout => (
          '锻炼',
          Icons.fitness_center_rounded,
          '下一步会按 8.png/6.png 做训练列表、动作组、开始动作。'
        ),
      LifeModule.health => (
          '健康',
          Icons.monitor_heart_rounded,
          '后续会按 9.png 做健康圆环、睡眠、步数、心率、能量卡片。'
        ),
      _ => ('模块', Icons.apps_rounded, '这个模块马上补。'),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  _IconBubble(
                    icon: Icons.view_sidebar_rounded,
                    color: const Color(0xFF91A3FF),
                    onTap: onOpenModules,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        info.$1,
                        style: const TextStyle(
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
              const SizedBox(height: 28),
              _EmptyCard(
                title: info.$1,
                subtitle: info.$3,
              ),
              const Spacer(),
              _ModuleQuickNav(
                selected: module,
                onSwitchModule: onSwitchModule,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleSheet extends StatelessWidget {
  const _ModuleSheet({
    required this.selected,
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
    required this.events,
    required this.onSelect,
  });

  final LifeModule selected;
  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;
  final List<LifeEvent> events;
  final ValueChanged<LifeModule> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              _IconBubble(
                icon: Icons.close_rounded,
                color: const Color(0xFF9A8FF7),
                onTap: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    '功能模块',
                    style: TextStyle(
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
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              key: const ValueKey('module_sheet_scroll'),
              children: [
                _ModuleProfileCard(
                  onSelectHeatDay: (day) => _showHeatMapDaySheet(context, day),
                ),
                const SizedBox(height: 16),
                // 模块中心也读取应用级共享状态，方便从任意模块回看今日联动进度。
                _ModuleLinkedSummaryCard(
                  title: '今日联动',
                  subtitle: '计划、健康和桌面小组件都会同步这里的实时状态。',
                  icon: Icons.hub_rounded,
                  values: [
                    ('待办', '$pendingTodos 项'),
                    ('饮食', '$foodCalories kcal'),
                    ('锻炼', '$workoutGroups 组'),
                  ],
                ),
                const SizedBox(height: 16),
                _LifeEventFeedCard(events: events.take(5).toList()),
                const SizedBox(height: 16),
                const _ModuleSectionTitle(
                  icon: Icons.grid_view_rounded,
                  title: '功能模块',
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final tileWidth = (constraints.maxWidth - 24) / 3;
                    final tileHeight = tileWidth / 1.05;
                    Widget tile(Widget child) {
                      return SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: child,
                      );
                    }

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        tile(
                          _ModuleTile(
                            tileKey: const ValueKey('module_sheet_plan'),
                            icon: Icons.event_available_rounded,
                            label: '计划待办',
                            selected: selected == LifeModule.plan,
                            onTap: () => onSelect(LifeModule.plan),
                          ),
                        ),
                        tile(
                          _ModuleTile(
                            tileKey: const ValueKey('module_sheet_finance'),
                            icon: Icons.account_balance_wallet_rounded,
                            label: '财务',
                            selected: selected == LifeModule.finance,
                            onTap: () => onSelect(LifeModule.finance),
                          ),
                        ),
                        tile(
                          _ModuleTile(
                            tileKey: const ValueKey('module_sheet_food'),
                            icon: Icons.restaurant_rounded,
                            label: '饮食',
                            selected: selected == LifeModule.food,
                            onTap: () => onSelect(LifeModule.food),
                          ),
                        ),
                        tile(
                          _ModuleTile(
                            tileKey: const ValueKey('module_sheet_workout'),
                            icon: Icons.fitness_center_rounded,
                            label: '锻炼',
                            selected: selected == LifeModule.workout,
                            onTap: () => onSelect(LifeModule.workout),
                          ),
                        ),
                        tile(
                          _ModuleTile(
                            tileKey: const ValueKey('module_sheet_health'),
                            icon: Icons.monitor_heart_rounded,
                            label: '健康',
                            selected: selected == LifeModule.health,
                            onTap: () => onSelect(LifeModule.health),
                          ),
                        ),
                        tile(
                          _ModuleTile(
                            tileKey: const ValueKey('module_sheet_settings'),
                            icon: Icons.settings_rounded,
                            label: '设置',
                            selected: false,
                            onTap: () => _showSettingsSheet(context),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ModuleListItem(
                  icon: Icons.info_outline_rounded,
                  title: '关于 App',
                  onTap: () => _showAboutSheet(context),
                ),
                _ModuleListItem(
                  icon: Icons.article_outlined,
                  title: '使用指导',
                  onTap: () => _showGuideSheet(context),
                ),
                _ModuleListItem(
                  icon: Icons.edit_rounded,
                  title: '问题反馈',
                  onTap: () => _showFeedbackSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AboutAppSheet(),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SettingsSheet(),
    );
  }

  void _showHeatMapDaySheet(BuildContext context, int day) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HeatMapDaySheet(day: day),
    );
  }

  void _showGuideSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _GuideSheet(),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FeedbackSheet(),
    );
  }
}

class _ModuleProfileCard extends StatelessWidget {
  const _ModuleProfileCard({
    required this.onSelectHeatDay,
  });

  final ValueChanged<int> onSelectHeatDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _AppIconMark(),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '平生',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFFC846), size: 30),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '2026年 05月',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _ModuleHeatMap(onSelectDay: onSelectHeatDay),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _ModuleStat(value: '984', label: '天\n坚持记录')),
              Expanded(child: _ModuleStat(value: '76', label: '条\n总记录')),
              Expanded(child: _ModuleStat(value: '联动', label: '热力图')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppIconMark extends StatelessWidget {
  const _AppIconMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.waves_rounded, color: Colors.white, size: 28),
    );
  }
}

class _ModuleHeatMap extends StatelessWidget {
  const _ModuleHeatMap({
    required this.onSelectDay,
  });

  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    const values = [
      3,
      4,
      2,
      2,
      1,
      1,
      3,
      2,
      2,
      1,
      0,
      2,
      3,
      2,
      3,
      2,
      1,
      1,
      3,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ];

    return SizedBox(
      height: 132,
      child: Column(
        children: [
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              children: List.generate(values.length, (index) {
                final value = values[index];
                final day = index + 1;
                final label = day == 15 ? '15' : (day == 31 ? '31' : '');
                // 热力图每个日期格都可点击，避免模块中心出现只可看的“死图”。
                return InkWell(
                  key: ValueKey('module_heat_day_$day'),
                  borderRadius: BorderRadius.circular(5),
                  onTap: () => onSelectDay(day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: value == 0
                          ? const Color(0xFFF2F4FA)
                          : Color.lerp(
                              const Color(0xFFBBC8FF),
                              AppColors.primary,
                              value / 4,
                            ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: value > 2 ? Colors.white : AppColors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatMapDaySheet extends StatelessWidget {
  const _HeatMapDaySheet({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final level = switch (day % 5) {
      0 => '高活跃',
      1 || 2 => '轻记录',
      3 => '稳定记录',
      _ => '待补充',
    };
    final recordCount = day % 5;

    return _InfoSheetFrame(
      title: '2026年5月$day日',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EmptyCard(
            title: level,
            subtitle: recordCount == 0
                ? '这一天还没有本地联动记录，可以从待办、饮食、锻炼或健康模块补齐。'
                : '这一天有 $recordCount 条模块记录，可继续进入对应模块查看细节。',
          ),
          const SizedBox(height: 14),
          const _ModuleSectionTitle(
            icon: Icons.link_rounded,
            title: '关联模块',
          ),
          const SizedBox(height: 10),
          const _HeatMapActionTile(
            icon: Icons.event_available_rounded,
            title: '计划待办',
            subtitle: '查看当天事项和完成状态',
          ),
          const _HeatMapActionTile(
            icon: Icons.restaurant_rounded,
            title: '饮食记录',
            subtitle: '查看当天摄入和食物选择',
          ),
          const _HeatMapActionTile(
            icon: Icons.fitness_center_rounded,
            title: '锻炼记录',
            subtitle: '查看训练组数和动作进度',
          ),
          const _HeatMapActionTile(
            icon: Icons.monitor_heart_rounded,
            title: '健康总览',
            subtitle: '查看系统健康数据状态',
          ),
        ],
      ),
    );
  }
}

class _HeatMapActionTile extends StatelessWidget {
  const _HeatMapActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _SettingsIcon(icon: icon),
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
                const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}

class _ModuleStat extends StatelessWidget {
  const _ModuleStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ModuleListItem extends StatelessWidget {
  const _ModuleListItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF9AA8EC), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _widgetDirectRecord = true;
  bool _summaryOpensDetail = true;
  bool _dailyReminder = true;
  bool _lowCalorieHint = false;
  String _defaultMeal = '三餐';
  String _themeMode = '跟随系统';

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
      title: '设置',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsSectionTitle(
            icon: Icons.widgets_rounded,
            title: '桌面小组件',
          ),
          _SettingsSwitchTile(
            tileKey: const ValueKey('setting_widget_direct_record'),
            icon: Icons.touch_app_rounded,
            title: '快捷按钮直接记录',
            subtitle: '待办、饮食、记账、锻炼',
            value: _widgetDirectRecord,
            onChanged: (value) => setState(() => _widgetDirectRecord = value),
          ),
          _SettingsSwitchTile(
            tileKey: const ValueKey('setting_summary_detail'),
            icon: Icons.open_in_new_rounded,
            title: '摘要进入详情',
            subtitle: '标题和摘要仍打开 App',
            value: _summaryOpensDetail,
            onChanged: (value) => setState(() => _summaryOpensDetail = value),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle(
            icon: Icons.restaurant_rounded,
            title: '饮食记录',
          ),
          _SettingsChoiceCard<String>(
            title: '默认餐次',
            value: _defaultMeal,
            options: const ['早餐', '午餐', '晚餐', '加餐', '三餐'],
            labelBuilder: (value) => value,
            onChanged: (value) => setState(() => _defaultMeal = value),
          ),
          _SettingsSwitchTile(
            tileKey: const ValueKey('setting_low_calorie_hint'),
            icon: Icons.tips_and_updates_rounded,
            title: '轻食提示',
            subtitle: '优先显示低脂高蛋白',
            value: _lowCalorieHint,
            onChanged: (value) => setState(() => _lowCalorieHint = value),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle(
            icon: Icons.palette_rounded,
            title: '显示与提醒',
          ),
          _SettingsChoiceCard<String>(
            title: '外观模式',
            value: _themeMode,
            options: const ['跟随系统', '浅色', '深色'],
            labelBuilder: (value) => value,
            onChanged: (value) => setState(() => _themeMode = value),
          ),
          _SettingsSwitchTile(
            tileKey: const ValueKey('setting_daily_reminder'),
            icon: Icons.notifications_active_rounded,
            title: '每日记录提醒',
            subtitle: '计划、饮食和锻炼',
            value: _dailyReminder,
            onChanged: (value) => setState(() => _dailyReminder = value),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle(
            icon: Icons.help_center_rounded,
            title: '帮助',
          ),
          _SettingsActionTile(
            icon: Icons.quiz_rounded,
            title: 'Q&A',
            subtitle: '健康数据、传感器、小组件常见问题',
            onTap: () => _showQaSheet(context),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle(
            icon: Icons.sync_rounded,
            title: '数据',
          ),
          _SettingsActionTile(
            icon: Icons.widgets_outlined,
            title: '刷新桌面小组件',
            subtitle: '同步当前联动摘要',
            onTap: () => _showSettingsSnack(context, '已请求刷新桌面小组件'),
          ),
          _SettingsActionTile(
            icon: Icons.file_download_rounded,
            title: '导出本地记录',
            subtitle: '计划、财务、饮食、锻炼',
            onTap: () => _showSettingsSnack(context, '已生成本地导出任务'),
          ),
        ],
      ),
    );
  }

  void _showSettingsSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQaSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _QaSheet(),
    );
  }
}

class _QaSheet extends StatelessWidget {
  const _QaSheet();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        '健康模块的数据从哪里来？',
        '步数、能量、基础代谢、睡眠、心率和呼吸频率来自手机系统 Health Connect；计步器、心率和加速度传感器状态来自 Android SensorManager。'
      ),
      ('为什么有些指标显示无系统记录？', 'App 不再使用演示数据。没有授权、系统没有记录、设备没有对应传感器时，会直接显示无系统记录。'),
      (
        '怎样开启真实健康数据？',
        '进入健康页点击授权，按系统提示允许 Health Connect 读取步数、能量、睡眠、心率和呼吸数据，再回到 App 刷新。'
      ),
      ('桌面小组件的健康摘要如何更新？', 'App 成功读取系统健康数据后会写入本机共享摘要，小组件读取同一份状态；没授权时只显示健康待授权。'),
      (
        '数据会上传吗？',
        '当前实现只读取本机系统数据并在本机展示，不接入服务器上传。你可以随时在系统 Health Connect 权限里关闭访问。'
      ),
    ];

    return _InfoSheetFrame(
      title: 'Q&A',
      child: Column(
        children: items
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.muted,
                  title: Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.$2,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
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

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.tileKey,
  });

  final Key? tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: tileKey,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _SettingsIcon(icon: icon),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsChoiceCard<T> extends StatelessWidget {
  const _SettingsChoiceCard({
    required this.title,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = option == value;
              final label = labelBuilder(option);
              return ChoiceChip(
                key: ValueKey('setting_choice_$label'),
                label: Text(label),
                selected: selected,
                selectedColor: AppColors.primarySoft,
                backgroundColor: AppColors.background,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.line,
                ),
                onSelected: (_) => onChanged(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _SettingsIcon(icon: icon),
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
                    const SizedBox(height: 4),
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
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}

class _AboutAppSheet extends StatelessWidget {
  const _AboutAppSheet();

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
      title: '关于 App',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _AboutHero(),
          SizedBox(height: 18),
          _FeatureIntroCard(
            icon: Icons.account_balance_wallet_rounded,
            title: '财务管理',
            body: '收支记录、资产统计、趋势分析',
            color: Color(0xFF7F7AF7),
          ),
          _FeatureIntroCard(
            icon: Icons.monitor_heart_rounded,
            title: '健康数据',
            body: '运动锻炼、睡眠心率、能量消耗',
            color: Color(0xFFFF747C),
          ),
          _FeatureIntroCard(
            icon: Icons.event_available_rounded,
            title: '计划待办',
            body: '日历视图、待办清单、分类管理',
            color: Color(0xFF7D9CFF),
          ),
          _FeatureIntroCard(
            icon: Icons.fitness_center_rounded,
            title: '科学锻炼',
            body: '训练计划、动作指导、数据追踪',
            color: AppColors.primary,
          ),
          _FeatureIntroCard(
            icon: Icons.restaurant_rounded,
            title: '饮食记录',
            body: '热量计算、食物分类、饮食分析',
            color: AppColors.success,
          ),
          SizedBox(height: 12),
          Center(
            child: Text(
              '一个 App 管理你的全部生活',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const _AppIconMark(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '平生',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '全能生活助手',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '财务、健康、计划、饮食一站管理',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureIntroCard extends StatelessWidget {
  const _FeatureIntroCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 25),
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
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSheet extends StatelessWidget {
  const _GuideSheet();

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
      title: '使用指导',
      child: Column(
        children: const [
          _GuideStep(
            number: '1',
            title: '先选模块',
            body: '点击左上角模块按钮，在财务、健康、计划、锻炼、饮食之间切换。',
          ),
          _GuideStep(
            number: '2',
            title: '每天记录一点',
            body: '待办可以勾选归档，饮食可以添加食物，锻炼可以按组完成。',
          ),
          _GuideStep(
            number: '3',
            title: '回看你的生活模式',
            body: '计划页的本周回顾和健康/财务图表会把分散记录整理成趋势。',
          ),
          _GuideStep(
            number: '4',
            title: '逐步补齐真实数据',
            body: '当前是原型数据，后面可以接本地数据库、云同步和提醒通知。',
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
  });

  final String number;
  final String title;
  final String body;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _controller = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
      title: '问题反馈',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: '写下你遇到的问题或想要的功能',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                setState(() => _sent = true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '提交反馈',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (_sent) ...[
            const SizedBox(height: 14),
            const _EmptyCard(
              title: '已收到',
              subtitle: '原型里先做本地反馈状态，后续可以接入邮件、接口或工单系统。',
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoSheetFrame extends StatelessWidget {
  const _InfoSheetFrame({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 16),
          Row(
            children: [
              _IconBubble(
                icon: Icons.close_rounded,
                color: const Color(0xFF9A8FF7),
                onTap: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    title,
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
          const SizedBox(height: 18),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [child],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleSectionTitle extends StatelessWidget {
  const _ModuleSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    this.tileKey,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key? tileKey;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: tileKey,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8C0D9).withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : const Color(0xFF8FA2E9),
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBottomNav extends StatelessWidget {
  const _PlanBottomNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.event_available_rounded, '待办'),
      (Icons.archive_rounded, '待办箱'),
      (Icons.fact_check_rounded, '计划'),
    ];

    return _CapsuleNav(
      selectedIndex: selectedIndex,
      items: items,
      onChanged: onChanged,
      keyPrefix: 'plan_bottom_nav',
    );
  }
}

class _FinanceBottomNav extends StatelessWidget {
  const _FinanceBottomNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.insert_chart_rounded, '总览'),
      (Icons.receipt_long_rounded, '记录'),
      (Icons.account_balance_rounded, '资产'),
    ];

    return _CapsuleNav(
      selectedIndex: selectedIndex,
      items: items,
      onChanged: onChanged,
    );
  }
}

class _ModuleQuickNav extends StatelessWidget {
  const _ModuleQuickNav({
    required this.selected,
    required this.onSwitchModule,
    this.keyPrefix,
  });

  final LifeModule selected;
  final ValueChanged<LifeModule> onSwitchModule;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    return _CapsuleNav(
      selectedIndex: switch (selected) {
        LifeModule.finance => 0,
        LifeModule.plan => 1,
        LifeModule.food => 2,
        LifeModule.workout => 3,
        LifeModule.health => 4,
      },
      items: const [
        (Icons.account_balance_wallet_rounded, '财务'),
        (Icons.event_available_rounded, '计划'),
        (Icons.restaurant_rounded, '饮食'),
        (Icons.fitness_center_rounded, '锻炼'),
        (Icons.monitor_heart_rounded, '健康'),
      ],
      compact: true,
      keyPrefix: keyPrefix,
      onChanged: (index) {
        final modules = [
          LifeModule.finance,
          LifeModule.plan,
          LifeModule.food,
          LifeModule.workout,
          LifeModule.health,
        ];
        onSwitchModule(modules[index]);
      },
    );
  }
}

class _ModuleLinkStrip extends StatelessWidget {
  const _ModuleLinkStrip({
    required this.selected,
    required this.onSwitchModule,
  });

  final LifeModule selected;
  final ValueChanged<LifeModule> onSwitchModule;

  @override
  Widget build(BuildContext context) {
    // 这里是所有主模块共用的联动入口，保证任意模块都能直接跳到其它模块。
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        // 小屏手机宽度不足时允许横向滑动，避免顶部模块入口出现 RenderFlex 溢出条。
        child: _ModuleQuickNav(
          selected: selected,
          onSwitchModule: onSwitchModule,
          keyPrefix: 'module_link',
        ),
      ),
    );
  }
}

class _CapsuleNav extends StatelessWidget {
  const _CapsuleNav({
    required this.selectedIndex,
    required this.items,
    required this.onChanged,
    this.compact = false,
    this.keyPrefix,
  });

  final int selectedIndex;
  final List<(IconData, String)> items;
  final ValueChanged<int> onChanged;
  final bool compact;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = selectedIndex == index;
          return InkWell(
            key: keyPrefix == null ? null : ValueKey('${keyPrefix}_$index'),
            borderRadius: BorderRadius.circular(15),
            onTap: () => onChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: compact ? 52 : 88,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$1,
                    size: 23,
                    color: selected ? Colors.white : AppColors.muted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD7DBE8),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
