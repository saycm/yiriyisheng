// 中文注释：本地存储层，负责 SQLite 持久化和桌面小组件数据同步。

part of 'storage.dart';

/// 桌面小组件数据通道：读取小组件摘要、写入摘要，并接收快捷动作回调。
class LifeWidgetStore {
  const LifeWidgetStore();

  static const _channel = MethodChannel('pingsheng_life/widget_summary');

  // 注册小组件快捷动作回调，收到原生事件后转到对应模块。
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

  // 取消快捷动作回调。
  void clearQuickActionHandler() {
    _channel.setMethodCallHandler(null);
  }

  // 从 Android 小组件读取摘要快照；通道不可用时返回空快照。
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
      final rawFoodLogs = result?['foodLogsJson'] as String?;
      return LifeSummarySnapshot(
        foodCalories: (result?['foodCalories'] as num?)?.toInt() ?? 0,
        foodLogs: rawFoodLogs == null ? null : _decodeFoodLogs(rawFoodLogs),
        workoutGroupsByAction: groups,
        workoutProgressDate:
            dateFromJson(result?['workoutProgressDate'] as String?),
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

  // 把首页摘要同步给 Android 小组件。
  Future<void> save({
    required int foodCalories,
    required List<FoodLogEntry> foodLogs,
    required Map<String, int> workoutGroupsByAction,
    required DateTime? workoutProgressDate,
    required int workoutGroups,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
  }) async {
    try {
      await _channel.invokeMethod<void>('saveLifeSummary', {
        'foodCalories': foodCalories,
        'foodLogsJson': jsonEncode(foodLogs.map((entry) => entry.toJson()).toList()),
        'pendingTodos': todos.where((todo) => todo.isActive).length,
        'todosJson': jsonEncode(todos.map((todo) => todo.toJson()).toList()),
        'financeRecordsJson': jsonEncode(
            financeRecords.map((record) => record.toJson()).toList()),
        'workoutGroups': workoutGroups,
        'workoutGroupsJson': jsonEncode(workoutGroupsByAction),
        'workoutProgressDate': dateToJson(workoutProgressDate) ?? '',
      });
    } on MissingPluginException {
      // 测试环境和非 Android 平台没有桌面小组件通道，直接跳过同步。
    }
  }

  // 解析小组件传来的待办 JSON。
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

  // 解析小组件传来的财务记录 JSON。
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

  // 解析小组件传来的饮食记录 JSON。
  List<FoodLogEntry> _decodeFoodLogs(String rawLogs) {
    final decodedLogs = jsonDecode(rawLogs);
    if (decodedLogs is! List<dynamic>) {
      return [];
    }
    return decodedLogs
        .whereType<Map<String, dynamic>>()
        .map(FoodLogEntry.fromJson)
        .toList();
  }
}
