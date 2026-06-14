part of '../main.dart';

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
        'pendingTodos': todos.where((todo) => todo.isActive).length,
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
