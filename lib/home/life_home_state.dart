part of 'life_home.dart';

class _FoodHomeState {
  int calories = 0;

  void applySnapshot(LifeSummarySnapshot snapshot) {
    calories = snapshot.foodCalories;
  }
}

class _WorkoutHomeState {
  final Map<String, int> groupsByAction = {};
  final List<WorkoutPlan> plans = createDefaultWorkoutPlans();
  ActiveWorkoutSession? activeSession;
  final List<WorkoutHistoryEntry> history = [];

  int get finishedGroups => groupsByAction.values.fold(
        0,
        (total, groups) => total + groups,
      );

  void applySnapshot(LifeSummarySnapshot snapshot) {
    groupsByAction
      ..clear()
      ..addAll(snapshot.workoutGroupsByAction);

    final restoredPlans = snapshot.workoutPlans;
    if (restoredPlans != null && restoredPlans.isNotEmpty) {
      plans
        ..clear()
        ..addAll(restoredPlans);
    }

    activeSession = snapshot.activeWorkoutSession;

    final restoredHistory = snapshot.workoutHistory;
    if (restoredHistory != null) {
      history
        ..clear()
        ..addAll(restoredHistory);
    }
  }
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

  double get todayExpense => records
      .where((record) => record.type == '支出')
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
  }

  void updateAiConfig({
    required String endpoint,
    required String model,
    required String apiKey,
    AiFinanceParseStrategy? parseStrategy,
  }) {
    aiEndpoint =
        endpoint.trim().isEmpty ? defaultGlmChatEndpoint : endpoint.trim();
    aiModel = model.trim().isEmpty ? defaultGlmTextModel : model.trim();
    aiApiKey = apiKey.trim();
    aiParseStrategy = parseStrategy ?? aiParseStrategy;
  }
}
