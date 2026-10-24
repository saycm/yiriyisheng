// 中文注释：业务数据模型，负责 App 内状态、序列化和恢复。

part of 'models.dart';

/// 首页聚合快照：一次性承载各模块需要恢复的核心数据。
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

/// 食物库中的一条食物：名称、热量、单位和三大营养素。
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

/// 一条饮食记录：吃了哪种食物、哪一餐、份数和记录时间。
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

/// 三大营养素类型，用于在没有显式营养数据时按分类估算。
enum _FoodMacro { protein, carbs, fat }

/// 计算食物某类营养素含量；没有显式数据时按食物分类的热量比例估算。
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

/// 对外暴露的食物分类归一化函数。
String normalizeFoodGroup(String group) => _normalizeFoodGroup(group);

/// 把各种食物分类别名归一化成少量标准分类。
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

/// 待办事项：标题、分类、优先级、状态、日期、重复规则和关联模块。
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
    int? repeatAnchorDay,
    List<TodoLinkedModule> linkedModules = const [],
    this.postponedCount = 0,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? _newLocalId(),
        repeatAnchorDay = repeatRule == TodoRepeatRule.monthly
            ? (repeatAnchorDay ?? dueDate?.day)
            : null,
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
  final int? repeatAnchorDay;
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
      repeatAnchorDay: repeatAnchorDay,
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

  TodoItem? createNextOccurrence() {
    if (!done) {
      return null;
    }
    final baseDate = dueDate ?? completedAt;
    if (baseDate == null) {
      return null;
    }
    final normalizedDate = DateUtils.dateOnly(baseDate);
    final nextDate = switch (repeatRule) {
      TodoRepeatRule.daily => normalizedDate.add(const Duration(days: 1)),
      TodoRepeatRule.weekly => normalizedDate.add(const Duration(days: 7)),
      TodoRepeatRule.monthly => _nextTodoMonth(
          normalizedDate,
          repeatAnchorDay ?? normalizedDate.day,
        ),
      TodoRepeatRule.none || TodoRepeatRule.custom => null,
    };
    if (nextDate == null) {
      return null;
    }

    return TodoItem(
      id: _nextTodoOccurrenceId(id, nextDate),
      title: title,
      category: category,
      color: color,
      priority: priority,
      status: TodoStatus.notStarted,
      dueDate: nextDate,
      note: note,
      repeatRule: repeatRule,
      repeatAnchorDay: repeatRule == TodoRepeatRule.monthly
          ? (repeatAnchorDay ?? normalizedDate.day)
          : null,
      linkedModules: linkedModules,
    );
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
      'repeatAnchorDay': repeatAnchorDay,
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
      repeatAnchorDay: (json['repeatAnchorDay'] as num?)?.toInt(),
      linkedModules: linkedModulesFromJson(json['linkedModules']),
      postponedCount: (json['postponedCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}

/// 判断一条重复待办是否仍保持“未被人为修改”的状态，用于安全地重建重复实例。
bool isUntouchedTodoOccurrence(TodoItem actual, TodoItem expected) {
  final sameDueDate = actual.dueDate == null || expected.dueDate == null
      ? actual.dueDate == expected.dueDate
      : DateUtils.isSameDay(actual.dueDate, expected.dueDate);
  return actual.id == expected.id &&
      actual.status == TodoStatus.notStarted &&
      actual.completedAt == null &&
      actual.postponedCount == 0 &&
      actual.title == expected.title &&
      actual.category == expected.category &&
      actual.color == expected.color &&
      actual.priority == expected.priority &&
      sameDueDate &&
      actual.note == expected.note &&
      actual.repeatRule == expected.repeatRule &&
      actual.repeatAnchorDay == expected.repeatAnchorDay &&
      listEquals(actual.linkedModules, expected.linkedModules);
}

/// 待办优先级：必须做 / 应该做 / 可推迟。
enum TodoPriority {
  mustDo('必须做', Icons.priority_high_rounded, AppColors.financeRed),
  shouldDo('应该做', Icons.flag_rounded, AppColors.primary),
  canDelay('可推迟', Icons.low_priority_rounded, AppColors.muted);

  const TodoPriority(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// 待办状态：未开始、进行中、已完成、已延后、已归档。
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

/// 待办重复规则：不重复、每天、每周、每月、自定义。
enum TodoRepeatRule {
  none('不重复'),
  daily('每天'),
  weekly('每周'),
  monthly('每月'),
  custom('自定义周期');

  const TodoRepeatRule(this.label);

  final String label;
}

/// 计算下一次每月重复的日期，并把日期限制在目标月份的天数内。
DateTime _nextTodoMonth(DateTime date, int anchorDay) {
  final firstDayOfFollowingMonth = DateTime(date.year, date.month + 2);
  final lastDayOfNextMonth =
      firstDayOfFollowingMonth.subtract(const Duration(days: 1)).day;
  return DateTime(
    date.year,
    date.month + 1,
    anchorDay.clamp(1, lastDayOfNextMonth),
  );
}

/// 为重复待办生成带日期后缀的新 ID，保持同一系列可被识别。
String _nextTodoOccurrenceId(String currentId, DateTime date) {
  final seriesId = currentId.replaceFirst(RegExp(r'__repeat_\d{8}$'), '');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${seriesId}__repeat_${date.year}$month$day';
}

/// 待办可关联的模块，以及对应的跳转动作和按钮文案。
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

/// 财务记录：一笔收入、支出或转账。
class FinanceRecord {
  const FinanceRecord({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    this.date,
    this.account = '银行卡',
    this.toAccount,
    this.tags = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final String type;
  final DateTime? date;
  final String account;
  final String? toAccount;
  final List<String> tags;

  Color get color => switch (type) {
        '收入' => AppColors.success,
        '转账' => AppColors.primary,
        _ => AppColors.financeRed,
      };

  String get displayAmount {
    if (type == '转账') {
      return formatMoney(amount);
    }
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
      'toAccount': toAccount,
      'tags': tags,
    };
  }

  static FinanceRecord fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '手动记录';
    final account = json['account'] as String?;
    final toAccount = json['toAccount'] as String?;
    return FinanceRecord(
      icon: financeIconForTitle(title),
      title: title,
      subtitle: json['subtitle'] as String? ?? '手动记录',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      type: json['type'] as String? ?? '支出',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      account:
          account == null || account.trim().isEmpty ? '银行卡' : account.trim(),
      toAccount: toAccount == null || toAccount.trim().isEmpty
          ? null
          : toAccount.trim(),
      tags: financeStringListFromJson(json['tags']),
    );
  }
}

/// 统计某一天某一类型（收入/支出）的总额。
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

/// 统计某一天饮食记录的总热量。
int todayFoodCalories(List<FoodLogEntry> logs, DateTime today) {
  return todayFoodLogs(logs, today)
      .fold(0, (total, entry) => total + entry.calories);
}

/// 过滤出某一天的饮食记录。
List<FoodLogEntry> todayFoodLogs(List<FoodLogEntry> logs, DateTime today) {
  final targetDay = DateUtils.dateOnly(today);
  return logs
      .where((entry) => DateUtils.isSameDay(entry.recordedAt, targetDay))
      .toList(growable: false);
}

/// 统计某一天的训练组数：已完成历史 + 进行中会话 + 本地进度。
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
  final activeGroups =
      session == null || !DateUtils.isSameDay(session.startedAt, targetDay)
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

/// 判断两个时间是否是同一个本地日期。
bool isSameLocalDay(DateTime? value, DateTime day) {
  return value != null && DateUtils.isSameDay(value, DateUtils.dateOnly(day));
}

/// 根据待办分类返回对应主题色。
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

/// 按枚举 name 反序列化，找不到时返回 fallback。
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

/// 把 JSON 中的模块名数组转换成去重后的关联模块列表。
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

/// 把 JSON 数组转换成去空白后的字符串列表。
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

/// 把日期序列化成 yyyy-MM-dd，无日期返回 null。
String? dateToJson(DateTime? value) {
  if (value == null) {
    return null;
  }
  final date = DateUtils.dateOnly(value);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// 返回 date 之后的下一个工作日（跳过周六周日）。
DateTime nextWorkdayAfter(DateTime date) {
  var target = DateUtils.dateOnly(date).add(const Duration(days: 1));
  while (target.weekday == DateTime.saturday ||
      target.weekday == DateTime.sunday) {
    target = target.add(const Duration(days: 1));
  }
  return target;
}

/// 解析 yyyy-MM-dd 日期，非法或空值返回 null。
DateTime? dateFromJson(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  return parsed == null ? null : DateUtils.dateOnly(parsed);
}

/// 生成本地待办 ID：时间戳 + 随机盐，保证离线也能唯一。
String _newLocalId() {
  final micros = DateTime.now().microsecondsSinceEpoch;
  final salt = math.Random().nextInt(1 << 20).toRadixString(16);
  return 'todo_${micros}_$salt';
}

/// 根据财务记录标题选择图标。
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

/// 把金额格式化成带千分位和 ¥ 前缀的字符串。
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

/// 生成待办完成后引导用户去关联模块记录的提示文案。
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
