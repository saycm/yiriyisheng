// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

/// 饮食模块的首页内存状态：只保存饮食记录列表。
class _FoodHomeState {
  final List<FoodLogEntry> logs = [];

  // 用持久化快照恢复饮食记录。
  void applySnapshot(LifeSummarySnapshot snapshot) {
    logs
      ..clear()
      ..addAll(_migrateFoodLogs(snapshot));
  }
}

/// 把旧版快照迁移成饮食记录列表；旧版累计热量无法拆分到具体日期，直接丢弃。
List<FoodLogEntry> _migrateFoodLogs(LifeSummarySnapshot snapshot) {
  final logs = snapshot.foodLogs;
  if (logs != null) {
    return logs;
  }
  // 旧版本只有无法分日的累计值，不能把它伪造成升级当天的饮食记录。
  return const [];
}

/// 锻炼模块的首页内存状态：动作组数、计划、进行中会话和历史记录。
class _WorkoutHomeState {
  final Map<String, int> groupsByAction = {};
  final List<WorkoutPlan> plans = createDefaultWorkoutPlans();
  ActiveWorkoutSession? activeSession;
  final List<WorkoutHistoryEntry> history = [];
  DateTime? progressDate;

  int get finishedGroups => groupsByAction.values.fold(
        0,
        (total, groups) => total + groups,
      );

  // 恢复锻炼相关数据，并把旧计划与默认计划合并。
  void applySnapshot(LifeSummarySnapshot snapshot) {
    groupsByAction
      ..clear()
      ..addAll(snapshot.workoutGroupsByAction);
    progressDate = snapshot.workoutProgressDate;

    plans
      ..clear()
      ..addAll(_mergeWorkoutPlans(snapshot.workoutPlans));

    activeSession = _migrateWorkoutSession(
      snapshot.activeWorkoutSession,
      plans,
    );

    final restoredHistory = snapshot.workoutHistory;
    if (restoredHistory != null) {
      history
        ..clear()
        ..addAll(restoredHistory);
    }
  }
}

/// 合并默认训练计划和用户保存的计划，保证新增的默认动作能出现。
List<WorkoutPlan> _mergeWorkoutPlans(List<WorkoutPlan>? restoredPlans) {
  final defaults = createDefaultWorkoutPlans();
  if (restoredPlans == null || restoredPlans.isEmpty) {
    return defaults;
  }

  final defaultIds = {for (final plan in defaults) plan.id};
  final restoredById = {for (final plan in restoredPlans) plan.id: plan};
  final merged = <WorkoutPlan>[];

  for (final defaultPlan in defaults) {
    final restored = restoredById[defaultPlan.id];
    if (restored == null ||
        _shouldRefreshDefaultWorkoutPlan(restored, defaultPlan)) {
      merged.add(defaultPlan);
    } else {
      merged.add(restored);
    }
  }

  for (final restored in restoredPlans) {
    if (!defaultIds.contains(restored.id)) {
      merged.add(restored);
    }
  }

  return merged;
}

/// 判断默认训练计划是否需要刷新（动作列表为空的旧数据）。
bool _shouldRefreshDefaultWorkoutPlan(
  WorkoutPlan restored,
  WorkoutPlan _,
) {
  return restored.actionNames.isEmpty;
}

/// 迁移进行中的训练会话，过滤掉已不存在的动作。
ActiveWorkoutSession? _migrateWorkoutSession(
  ActiveWorkoutSession? session,
  List<WorkoutPlan> plans,
) {
  if (session == null) {
    return null;
  }

  for (final plan in plans) {
    if (plan.id != session.planId) {
      continue;
    }
    if (plan.actionNames.isEmpty) {
      return session.actionProgress.isEmpty ? null : session;
    }
    return ActiveWorkoutSession(
      id: session.id,
      planId: plan.id,
      planName: plan.name,
      startedAt: session.startedAt,
      actionProgress: {
        for (final actionName in plan.actionNames)
          actionName: session.groupsFor(actionName),
      },
      feedback: session.feedback,
    );
  }

  return session.actionProgress.isEmpty ? null : session;
}

/// 计划模块的首页内存状态：待办列表和事件流。
class _PlanHomeState {
  final List<TodoItem> todos = _createSeedTodos();
  final List<LifeEvent> events = [];

  int get pendingTodoCount => todos.where((todo) => todo.isActive).length;

  // 恢复待办列表。
  void applySnapshot(LifeSummarySnapshot snapshot) {
    final restoredTodos = snapshot.todos;
    if (restoredTodos != null) {
      todos
        ..clear()
        ..addAll(restoredTodos);
    }
  }

  // 插入一条生活事件，最多保留 8 条。
  void pushEvent(LifeEvent event) {
    events.insert(0, event);
    if (events.length > 8) {
      events.removeRange(8, events.length);
    }
  }
}

/// 财务模块的首页内存状态：财务记录和 AI 配置。
class _FinanceHomeState {
  final List<FinanceRecord> records = _createSeedFinanceRecords();
  String aiEndpoint = defaultGlmChatEndpoint;
  String aiModel = defaultGlmTextModel;
  String aiApiKey = '';
  AiFinanceParseStrategy aiParseStrategy = AiFinanceParseStrategy.defaults;
  String aiCustomPrompt = '';

  double get todayExpense => records
      .where((record) =>
          record.type == '支出' && isSameLocalDay(record.date, DateTime.now()))
      .fold(0, (total, record) => total + record.amount);

  // 恢复财务记录和 AI 配置。
  void applySnapshot(LifeSummarySnapshot snapshot) {
    final restoredRecords = snapshot.financeRecords;
    if (restoredRecords != null) {
      records
        ..clear()
        ..addAll(restoredRecords);
    }

    aiEndpoint = snapshot.aiFinanceEndpoint.trim().isEmpty
        ? defaultGlmChatEndpoint
        : snapshot.aiFinanceEndpoint;
    aiModel = snapshot.aiFinanceModel.trim().isEmpty
        ? defaultGlmTextModel
        : snapshot.aiFinanceModel;
    aiApiKey = snapshot.aiFinanceApiKey;
    aiParseStrategy = snapshot.aiFinanceParseStrategy;
    aiCustomPrompt = snapshot.aiFinanceCustomPrompt;
  }

  // 更新 AI 记账配置，空值回退到默认接口/模型。
  void updateAiConfig({
    required String endpoint,
    required String model,
    required String apiKey,
    AiFinanceParseStrategy? parseStrategy,
    String? customPrompt,
  }) {
    aiEndpoint =
        endpoint.trim().isEmpty ? defaultGlmChatEndpoint : endpoint.trim();
    aiModel = model.trim().isEmpty ? defaultGlmTextModel : model.trim();
    aiApiKey = apiKey.trim();
    aiParseStrategy = parseStrategy ?? aiParseStrategy;
    aiCustomPrompt = customPrompt ?? aiCustomPrompt;
  }
}
