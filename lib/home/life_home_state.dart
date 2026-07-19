// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

class _FoodHomeState {
  final List<FoodLogEntry> logs = [];

  void applySnapshot(LifeSummarySnapshot snapshot) {
    logs
      ..clear()
      ..addAll(_migrateFoodLogs(snapshot));
  }
}

List<FoodLogEntry> _migrateFoodLogs(LifeSummarySnapshot snapshot) {
  final logs = snapshot.foodLogs;
  if (logs != null) {
    return logs;
  }
  // 旧版本只有无法分日的累计值，不能把它伪造成升级当天的饮食记录。
  return const [];
}

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

bool _shouldRefreshDefaultWorkoutPlan(
  WorkoutPlan restored,
  WorkoutPlan _,
) {
  return restored.actionNames.isEmpty;
}

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

class _PlanHomeState {
  final List<TodoItem> todos = _createSeedTodos();
  final List<LifeEvent> events = [];

  int get pendingTodoCount => todos.where((todo) => todo.isActive).length;

  void applySnapshot(LifeSummarySnapshot snapshot) {
    final restoredTodos = snapshot.todos;
    if (restoredTodos != null) {
      todos
        ..clear()
        ..addAll(restoredTodos);
    }
  }

  void pushEvent(LifeEvent event) {
    events.insert(0, event);
    if (events.length > 8) {
      events.removeRange(8, events.length);
    }
  }
}

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
