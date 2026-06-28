part of '../main.dart';

class LifeSummarySnapshot {
  const LifeSummarySnapshot({
    required this.foodCalories,
    required this.workoutGroupsByAction,
    required this.todos,
    required this.financeRecords,
    this.workoutPlans,
    this.activeWorkoutSession,
    this.workoutHistory,
    this.aiFinanceEndpoint = _defaultGlmChatEndpoint,
    this.aiFinanceModel = _defaultGlmTextModel,
    this.aiFinanceApiKey = '',
  });

  final int foodCalories;
  final Map<String, int> workoutGroupsByAction;
  final List<TodoItem>? todos;
  final List<FinanceRecord>? financeRecords;
  final List<WorkoutPlan>? workoutPlans;
  final ActiveWorkoutSession? activeWorkoutSession;
  final List<WorkoutHistoryEntry>? workoutHistory;
  final String aiFinanceEndpoint;
  final String aiFinanceModel;
  final String aiFinanceApiKey;
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

class FinanceRecord {
  const FinanceRecord({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    this.date,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final String type;
  final DateTime? date;

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
      'date': date?.toIso8601String(),
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
      date: DateTime.tryParse(json['date'] as String? ?? ''),
    );
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

IconData _financeIconForTitle(String title) {
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
