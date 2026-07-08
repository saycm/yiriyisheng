// 中文注释：业务数据模型，负责 App 内状态、序列化和恢复。

part of 'models.dart';

class LifeSummarySnapshot {
  const LifeSummarySnapshot({
    required this.foodCalories,
    required this.workoutGroupsByAction,
    required this.todos,
    required this.financeRecords,
    this.foodLogs,
    this.workoutProgressDate,
    this.workoutPlans,
    this.activeWorkoutSession,
    this.workoutHistory,
    this.aiFinanceEndpoint = defaultGlmChatEndpoint,
    this.aiFinanceModel = defaultGlmTextModel,
    this.aiFinanceApiKey = '',
    this.aiFinanceParseStrategy = AiFinanceParseStrategy.defaults,
    this.aiFinanceCustomPrompt = '',
  });

  final int foodCalories;
  final Map<String, int> workoutGroupsByAction;
  final List<TodoItem>? todos;
  final List<FinanceRecord>? financeRecords;
  final List<FoodLogEntry>? foodLogs;
  final DateTime? workoutProgressDate;
  final List<WorkoutPlan>? workoutPlans;
  final ActiveWorkoutSession? activeWorkoutSession;
  final List<WorkoutHistoryEntry>? workoutHistory;
  final String aiFinanceEndpoint;
  final String aiFinanceModel;
  final String aiFinanceApiKey;
  final AiFinanceParseStrategy aiFinanceParseStrategy;
  final String aiFinanceCustomPrompt;
}

class FoodItem {
  const FoodItem({
    required this.emoji,
    required this.name,
    required this.calorie,
    required this.unit,
    required this.group,
    this.protein,
    this.carbs,
    this.fat,
  });

  final String emoji;
  final String name;
  final int calorie;
  final String unit;
  final String group;
  final double? protein;
  final double? carbs;
  final double? fat;

  Map<String, Object?> toJson() {
    return {
      'emoji': emoji,
      'name': name,
      'calorie': calorie,
      'unit': unit,
      'group': group,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  static FoodItem fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final calorie = json['calorie'];
    return FoodItem(
      emoji: json['emoji'] as String? ?? '🍱',
      name: name is String && name.isNotEmpty ? name : '未命名食物',
      calorie: calorie is num
          ? calorie.toInt()
          : int.tryParse(calorie?.toString() ?? '') ?? 0,
      unit: json['unit'] as String? ?? '1 份',
      group: json['group'] as String? ?? '自定义',
      protein: _numToDouble(json['protein']),
      carbs: _numToDouble(json['carbs']),
      fat: _numToDouble(json['fat']),
    );
  }
}

class FoodLogEntry {
  const FoodLogEntry({
    required this.food,
    required this.meal,
    required this.servings,
    required this.note,
    required this.recordedAt,
  });

  final FoodItem food;
  final String meal;
  final double servings;
  final String note;
  final DateTime recordedAt;

  int get calories => (food.calorie * servings).round();
  double get protein => _foodMacro(food, _FoodMacro.protein) * servings;
  double get carbs => _foodMacro(food, _FoodMacro.carbs) * servings;
  double get fat => _foodMacro(food, _FoodMacro.fat) * servings;

  Map<String, Object?> toJson() {
    return {
      'food': food.toJson(),
      'meal': meal,
      'servings': servings,
      'note': note,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  static FoodLogEntry fromJson(Map<String, Object?> json) {
    final food = json['food'];
    final servings = json['servings'];
    return FoodLogEntry(
      food: food is Map
          ? FoodItem.fromJson(food.cast<String, Object?>())
          : const FoodItem(
              emoji: '🍱',
              name: '未命名食物',
              calorie: 0,
              unit: '1 份',
              group: '自定义',
            ),
      meal: json['meal'] as String? ?? '午餐',
      servings: servings is num
          ? servings.toDouble()
          : double.tryParse(servings?.toString() ?? '') ?? 1,
      note: json['note'] as String? ?? '',
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

enum _FoodMacro { protein, carbs, fat }

double _foodMacro(FoodItem food, _FoodMacro macro) {
  final direct = switch (macro) {
    _FoodMacro.protein => food.protein,
    _FoodMacro.carbs => food.carbs,
    _FoodMacro.fat => food.fat,
  };
  if (direct != null) {
    return direct;
  }

  final ratios = switch (_normalizeFoodGroup(food.group)) {
    '蛋白' => (0.22, 0.06, 0.06),
    '主食' => (0.05, 0.20, 0.02),
    '蔬果' => (0.03, 0.12, 0.01),
    '饮品' => (0.02, 0.10, 0.01),
    '零食' => (0.08, 0.28, 0.12),
    _ => (0.10, 0.18, 0.07),
  };
  final ratio = switch (macro) {
    _FoodMacro.protein => ratios.$1,
    _FoodMacro.carbs => ratios.$2,
    _FoodMacro.fat => ratios.$3,
  };
  return food.calorie * ratio;
}

String normalizeFoodGroup(String group) => _normalizeFoodGroup(group);

String _normalizeFoodGroup(String group) {
  return switch (group) {
    '常用' || '常见' || '早餐' || '汤粥' || '家常菜' => '常用',
    '主食' || '主食杂粮' => '主食',
    '蛋白' || '肉蛋奶' || '低脂高蛋白' || '海鲜水产' => '蛋白',
    '蔬果' || '蔬菜水果' => '蔬果',
    '收藏' || '饮品' => '饮品',
    '零食' || '坚果种子' || '烘焙甜品' || '调味酱料' => '零食',
    '外卖' || '外卖快餐' => '外卖',
    '自定义' => '自定义',
    _ => '自定义',
  };
}

double? _numToDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
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

  DateTime postponeToNextWorkday({DateTime? today}) {
    final todayDate = DateUtils.dateOnly(today ?? DateTime.now());
    final rawDueDate = dueDate;
    final currentDueDate =
        rawDueDate == null ? null : DateUtils.dateOnly(rawDueDate);
    final baseDate =
        currentDueDate == null || currentDueDate.isBefore(todayDate)
            ? todayDate
            : currentDueDate;
    dueDate = nextWorkdayAfter(baseDate);
    status = TodoStatus.postponed;
    postponedCount++;
    return dueDate!;
  }

  DateTime postponeToTomorrow() {
    return postponeToNextWorkday();
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
      'dueDate': dateToJson(dueDate),
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
    final status = enumByName(
      TodoStatus.values,
      json['status'] as String?,
      fallback:
          json['done'] == true ? TodoStatus.completed : TodoStatus.notStarted,
    );
    return TodoItem(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '未命名待办',
      category: category,
      color: todoColorForCategory(category),
      priority: enumByName(
        TodoPriority.values,
        json['priority'] as String?,
        fallback: TodoPriority.shouldDo,
      ),
      status: status,
      dueDate: dateFromJson(json['dueDate'] as String?),
      note: json['note'] as String? ?? '',
      repeatRule: enumByName(
        TodoRepeatRule.values,
        json['repeatRule'] as String?,
        fallback: TodoRepeatRule.none,
      ),
      linkedModules: linkedModulesFromJson(json['linkedModules']),
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
  health('状态', Icons.monitor_heart_rounded, Color(0xFFFF6F9D));

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
      TodoLinkedModule.health => '看状态',
    };
  }
}

class FinanceRecord {
  const FinanceRecord({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    this.date,
    this.account = '银行卡',
    this.tags = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final String type;
  final DateTime? date;
  final String account;
  final List<String> tags;

  Color get color => type == '收入' ? AppColors.success : AppColors.financeRed;

  String get displayAmount {
    final prefix = type == '收入' ? '+' : '-';
    return '$prefix${formatMoney(amount)}';
  }

  Map<String, Object?> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'type': type,
      'date': date?.toIso8601String(),
      'account': account,
      'tags': tags,
    };
  }

  static FinanceRecord fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '手动记录';
    final account = json['account'] as String?;
    return FinanceRecord(
      icon: financeIconForTitle(title),
      title: title,
      subtitle: json['subtitle'] as String? ?? '手动记录',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: json['type'] as String? ?? '支出',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      account:
          account == null || account.trim().isEmpty ? '银行卡' : account.trim(),
      tags: financeStringListFromJson(json['tags']),
    );
  }
}

double todayFinanceTotal(
  List<FinanceRecord> records,
  String type,
  DateTime today,
) {
  final targetDay = DateUtils.dateOnly(today);
  return records.where((record) {
    final date = record.date;
    return record.type == type &&
        date != null &&
        DateUtils.isSameDay(date, targetDay);
  }).fold(0, (total, record) => total + record.amount);
}

int todayFoodCalories(List<FoodLogEntry> logs, DateTime today) {
  return todayFoodLogs(logs, today)
      .fold(0, (total, entry) => total + entry.calories);
}

List<FoodLogEntry> todayFoodLogs(List<FoodLogEntry> logs, DateTime today) {
  final targetDay = DateUtils.dateOnly(today);
  return logs
      .where((entry) => DateUtils.isSameDay(entry.recordedAt, targetDay))
      .toList(growable: false);
}

int todayWorkoutGroups({
  required List<WorkoutHistoryEntry> history,
  required ActiveWorkoutSession? activeSession,
  Map<String, int> progressGroupsByAction = const {},
  required DateTime today,
}) {
  final targetDay = DateUtils.dateOnly(today);
  final completedGroups = history.where((entry) {
    return DateUtils.isSameDay(entry.finishedAt, targetDay);
  }).fold<int>(0, (total, entry) => total + entry.totalGroups);
  final session = activeSession;
  final activeGroups = session == null ||
          !DateUtils.isSameDay(session.startedAt, targetDay)
      ? 0
      : session.actionProgress.values.fold<int>(
          0,
          (total, groups) => total + groups,
        );
  final progressGroups = session == null
      ? progressGroupsByAction.values.fold<int>(
          0,
          (total, groups) => total + groups,
        )
      : 0;
  return completedGroups + activeGroups + progressGroups;
}

bool isSameLocalDay(DateTime? value, DateTime day) {
  return value != null && DateUtils.isSameDay(value, DateUtils.dateOnly(day));
}

Color todoColorForCategory(String category) {
  return switch (category) {
    '健康' => const Color(0xFFFF6F9D),
    '状态' => const Color(0xFFFF6F9D),
    '工作' => const Color(0xFF9278F7),
    '财务' => AppColors.success,
    '学习' => const Color(0xFFB88955),
    _ => const Color(0xFF7D9CFF),
  };
}

T enumByName<T extends Enum>(
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

List<TodoLinkedModule> linkedModulesFromJson(Object? value) {
  if (value is! List<dynamic>) {
    return [];
  }
  return value
      .whereType<String>()
      .map(
        (name) => enumByName(
          TodoLinkedModule.values,
          name,
          fallback: TodoLinkedModule.health,
        ),
      )
      .toSet()
      .toList();
}

List<String> financeStringListFromJson(Object? value) {
  if (value is! List<dynamic>) {
    return [];
  }
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String? dateToJson(DateTime? value) {
  if (value == null) {
    return null;
  }
  final date = DateUtils.dateOnly(value);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime nextWorkdayAfter(DateTime date) {
  var target = DateUtils.dateOnly(date).add(const Duration(days: 1));
  while (target.weekday == DateTime.saturday ||
      target.weekday == DateTime.sunday) {
    target = target.add(const Duration(days: 1));
  }
  return target;
}

DateTime? dateFromJson(String? value) {
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

IconData financeIconForTitle(String title) {
  return switch (title) {
    '三餐' => Icons.restaurant_rounded,
    '咖啡' => Icons.local_cafe_rounded,
    '外卖快餐' => Icons.delivery_dining_rounded,
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
    '通讯' => Icons.phone_android_rounded,
    '水电' => Icons.water_drop_rounded,
    '医疗' => Icons.medical_services_rounded,
    '教育' => Icons.school_rounded,
    '兼职' => Icons.work_history_rounded,
    _ => Icons.receipt_long_rounded,
  };
}

String formatMoney(double value) {
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

String linkedTodoPrompt(TodoItem todo, TodoLinkedModule module) {
  return switch (module) {
    TodoLinkedModule.finance => '${todo.title} 已完成，可以补一条财务记录。',
    TodoLinkedModule.food => '${todo.title} 已完成，可以补充饮食记录。',
    TodoLinkedModule.workout => '${todo.title} 已完成，可以记录训练组数。',
    TodoLinkedModule.health => todo.done
        ? '${todo.title} 已完成，状态模块会同步今日状态。'
        : '${todo.title} 未完成，明天关注睡眠和恢复。',
  };
}
