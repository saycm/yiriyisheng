# 锻炼完整训练系统实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 把锻炼模块升级为从计划开始、训练中记录、完成后生成历史、数据页读取真实训练记录的闭环系统。

**架构：** 保持当前 `part of main.dart` 结构，新增专注的锻炼模型文件，并把训练计划、当前训练会话、训练历史纳入 `LifeSummarySnapshot` 和 SQLite 快照存储。`LifeHomePage` 继续作为跨模块状态中枢，`WorkoutModulePage` 负责锻炼模块内部交互和 UI。

**技术栈：** Flutter、Dart、sqflite、Widget Test、现有 `part` 文件结构。

---

## 文件结构

### 创建

- `lib/modules/workout/workout_models.dart`
  存放锻炼领域模型：`WorkoutPlan`、`ActiveWorkoutSession`、`WorkoutActionResult`、`WorkoutHistoryEntry`、`WorkoutMetricKind`、`WorkoutMetricDetail`。

### 修改

- `lib/main.dart`
  添加 `part 'modules/workout/workout_models.dart';`。

- `lib/models/life_data.dart`
  扩展 `LifeSummarySnapshot`，加入训练计划、当前训练会话、训练历史。

- `lib/storage/app_data_store.dart`
  升级 SQLite 版本，新增训练计划、当前训练会话、训练历史表，读写新模型。

- `lib/home/life_home_page.dart`
  增加 `_workoutPlans`、`_activeWorkoutSession`、`_workoutHistory` 状态，并传给锻炼模块。

- `lib/home/life_home_persistence.dart`
  恢复和保存训练计划、训练会话、训练历史。

- `lib/home/life_home_mutations.dart`
  增加开始计划训练、更新训练会话、完成训练、再次训练同计划的跨模块状态方法。

- `lib/home/home_module_page_builder.dart`
  把新增锻炼状态和回调传给 `WorkoutModulePage`。

- `lib/modules/workout/workout_module.dart`
  改造计划、训练、数据、历史页面，让它们基于新增模型联动。

- `test/widget_test.dart`
  增加锻炼计划闭环、训练完成生成历史、数据页读取真实记录、历史详情再次训练的 widget test。

---

## 任务 1：新增锻炼领域模型

**文件：**
- 创建：`lib/modules/workout/workout_models.dart`
- 修改：`lib/main.dart`
- 修改：`lib/models/life_data.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的模型序列化测试**

在 `test/widget_test.dart` 的 `main()` 内添加测试：

```dart
  test('workout models serialize and restore training history', () {
    final startedAt = DateTime(2026, 6, 29, 8, 0);
    final finishedAt = DateTime(2026, 6, 29, 8, 32);

    final entry = WorkoutHistoryEntry(
      id: 'history-1',
      planId: 'plan-chest',
      planName: '胸背强化',
      startedAt: startedAt,
      finishedAt: finishedAt,
      durationMinutes: 32,
      totalGroups: 8,
      estimatedCalories: 184,
      actionResults: const [
        WorkoutActionResult(
          actionName: '蝴蝶机夹胸',
          bodyPart: '胸背',
          targetGroups: 4,
          finishedGroups: 4,
          reps: '8次',
          weight: '30kg',
        ),
        WorkoutActionResult(
          actionName: '宽握高位下拉',
          bodyPart: '胸背',
          targetGroups: 4,
          finishedGroups: 4,
          reps: '12次',
          weight: '30kg',
        ),
      ],
      feedback: '适中',
    );

    final restored = WorkoutHistoryEntry.fromJson(entry.toJson());

    expect(restored.id, 'history-1');
    expect(restored.planName, '胸背强化');
    expect(restored.durationMinutes, 32);
    expect(restored.totalGroups, 8);
    expect(restored.estimatedCalories, 184);
    expect(restored.actionResults.map((item) => item.actionName), [
      '蝴蝶机夹胸',
      '宽握高位下拉',
    ]);
  });
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout models serialize and restore training history"
```

预期：失败，报错包含 `WorkoutHistoryEntry` 未定义。

- [ ] **步骤 3：创建锻炼模型文件**

创建 `lib/modules/workout/workout_models.dart`：

```dart
part of '../../main.dart';

class WorkoutPlan {
  WorkoutPlan({
    String? id,
    required this.name,
    required this.target,
    required List<String> bodyParts,
    required List<String> actionNames,
    required this.estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _newLocalId(),
        bodyParts = List.of(bodyParts),
        actionNames = List.of(actionNames),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String name;
  String target;
  List<String> bodyParts;
  List<String> actionNames;
  int estimatedMinutes;
  final DateTime createdAt;
  DateTime updatedAt;

  int totalGroupsFrom(List<WorkoutAction> actions) {
    return actions
        .where((action) => actionNames.contains(action.name))
        .fold(0, (total, action) => total + action.groups);
  }

  WorkoutPlan copyWith({
    String? name,
    String? target,
    List<String>? bodyParts,
    List<String>? actionNames,
    int? estimatedMinutes,
    DateTime? updatedAt,
  }) {
    return WorkoutPlan(
      id: id,
      name: name ?? this.name,
      target: target ?? this.target,
      bodyParts: bodyParts ?? this.bodyParts,
      actionNames: actionNames ?? this.actionNames,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'target': target,
      'bodyParts': bodyParts,
      'actionNames': actionNames,
      'estimatedMinutes': estimatedMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static WorkoutPlan fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '未命名计划',
      target: json['target'] as String? ?? '今日训练',
      bodyParts: _stringListFromJson(json['bodyParts']),
      actionNames: _stringListFromJson(json['actionNames']),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 20,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ActiveWorkoutSession {
  ActiveWorkoutSession({
    String? id,
    required this.planId,
    required this.planName,
    required this.startedAt,
    required Map<String, int> actionProgress,
    this.feedback = '适中',
  })  : id = id ?? _newLocalId(),
        actionProgress = Map.of(actionProgress);

  final String id;
  final String planId;
  final String planName;
  final DateTime startedAt;
  final Map<String, int> actionProgress;
  String feedback;

  int groupsFor(String actionName) => actionProgress[actionName] ?? 0;

  ActiveWorkoutSession copyWith({
    Map<String, int>? actionProgress,
    String? feedback,
  }) {
    return ActiveWorkoutSession(
      id: id,
      planId: planId,
      planName: planName,
      startedAt: startedAt,
      actionProgress: actionProgress ?? this.actionProgress,
      feedback: feedback ?? this.feedback,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planName': planName,
      'startedAt': startedAt.toIso8601String(),
      'actionProgress': actionProgress,
      'feedback': feedback,
    };
  }

  static ActiveWorkoutSession fromJson(Map<String, dynamic> json) {
    return ActiveWorkoutSession(
      id: json['id'] as String?,
      planId: json['planId'] as String? ?? '',
      planName: json['planName'] as String? ?? '训练计划',
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      actionProgress: _intMapFromJson(json['actionProgress']),
      feedback: json['feedback'] as String? ?? '适中',
    );
  }
}

class WorkoutActionResult {
  const WorkoutActionResult({
    required this.actionName,
    required this.bodyPart,
    required this.targetGroups,
    required this.finishedGroups,
    required this.reps,
    this.weight,
  });

  final String actionName;
  final String bodyPart;
  final int targetGroups;
  final int finishedGroups;
  final String reps;
  final String? weight;

  Map<String, Object?> toJson() {
    return {
      'actionName': actionName,
      'bodyPart': bodyPart,
      'targetGroups': targetGroups,
      'finishedGroups': finishedGroups,
      'reps': reps,
      'weight': weight,
    };
  }

  static WorkoutActionResult fromJson(Map<String, dynamic> json) {
    return WorkoutActionResult(
      actionName: json['actionName'] as String? ?? '',
      bodyPart: json['bodyPart'] as String? ?? '',
      targetGroups: (json['targetGroups'] as num?)?.toInt() ?? 0,
      finishedGroups: (json['finishedGroups'] as num?)?.toInt() ?? 0,
      reps: json['reps'] as String? ?? '',
      weight: json['weight'] as String?,
    );
  }
}

class WorkoutHistoryEntry {
  WorkoutHistoryEntry({
    String? id,
    required this.planId,
    required this.planName,
    required this.startedAt,
    required this.finishedAt,
    required this.durationMinutes,
    required this.totalGroups,
    required this.estimatedCalories,
    required List<WorkoutActionResult> actionResults,
    this.feedback = '适中',
  })  : id = id ?? _newLocalId(),
        actionResults = List.of(actionResults);

  final String id;
  final String planId;
  final String planName;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationMinutes;
  final int totalGroups;
  final int estimatedCalories;
  final List<WorkoutActionResult> actionResults;
  final String feedback;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'planId': planId,
      'planName': planName,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'totalGroups': totalGroups,
      'estimatedCalories': estimatedCalories,
      'actionResults': actionResults.map((item) => item.toJson()).toList(),
      'feedback': feedback,
    };
  }

  static WorkoutHistoryEntry fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryEntry(
      id: json['id'] as String?,
      planId: json['planId'] as String? ?? '',
      planName: json['planName'] as String? ?? '训练记录',
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? '') ??
          DateTime.now(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      totalGroups: (json['totalGroups'] as num?)?.toInt() ?? 0,
      estimatedCalories: (json['estimatedCalories'] as num?)?.toInt() ?? 0,
      actionResults: _actionResultsFromJson(json['actionResults']),
      feedback: json['feedback'] as String? ?? '适中',
    );
  }
}

List<String> _stringListFromJson(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}

Map<String, int> _intMapFromJson(Object? value) {
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), (item as num?)?.toInt() ?? 0),
    );
  }
  return const {};
}

List<WorkoutActionResult> _actionResultsFromJson(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => WorkoutActionResult.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .toList();
  }
  return const [];
}
```

- [ ] **步骤 4：把模型文件挂到主库**

在 `lib/main.dart` 的 workout part 附近加入：

```dart
part 'modules/workout/workout_models.dart';
```

- [ ] **步骤 5：扩展 LifeSummarySnapshot**

在 `lib/models/life_data.dart` 的 `LifeSummarySnapshot` 增加字段：

```dart
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
```

- [ ] **步骤 6：运行模型测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout models serialize and restore training history"
```

预期：`All tests passed!`

- [ ] **步骤 7：Commit**

```powershell
git add lib/main.dart lib/models/life_data.dart lib/modules/workout/workout_models.dart test/widget_test.dart
git commit -m "feat: add workout training models"
```

---

## 任务 2：持久化训练计划、当前训练和历史

**文件：**
- 修改：`lib/storage/app_data_store.dart`
- 修改：`lib/home/life_home_page.dart`
- 修改：`lib/home/life_home_persistence.dart`
- 修改：`lib/home/life_home_mutations.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的持久化恢复测试**

在 `test/widget_test.dart` 添加：

```dart
  test('life summary snapshot carries workout training state', () {
    final plan = WorkoutPlan(
      id: 'plan-chest',
      name: '胸背强化',
      target: '胸背训练',
      bodyParts: const ['胸背'],
      actionNames: const ['蝴蝶机夹胸'],
      estimatedMinutes: 28,
      createdAt: DateTime(2026, 6, 29),
      updatedAt: DateTime(2026, 6, 29),
    );
    final session = ActiveWorkoutSession(
      id: 'session-1',
      planId: 'plan-chest',
      planName: '胸背强化',
      startedAt: DateTime(2026, 6, 29, 8),
      actionProgress: const {'蝴蝶机夹胸': 2},
    );
    final history = WorkoutHistoryEntry(
      id: 'history-1',
      planId: 'plan-chest',
      planName: '胸背强化',
      startedAt: DateTime(2026, 6, 29, 8),
      finishedAt: DateTime(2026, 6, 29, 8, 30),
      durationMinutes: 30,
      totalGroups: 4,
      estimatedCalories: 128,
      actionResults: const [
        WorkoutActionResult(
          actionName: '蝴蝶机夹胸',
          bodyPart: '胸背',
          targetGroups: 4,
          finishedGroups: 4,
          reps: '8次',
          weight: '30kg',
        ),
      ],
    );

    final snapshot = LifeSummarySnapshot(
      foodCalories: 0,
      workoutGroupsByAction: const {'蝴蝶机夹胸': 4},
      todos: const [],
      financeRecords: const [],
      workoutPlans: [plan],
      activeWorkoutSession: session,
      workoutHistory: [history],
    );

    expect(snapshot.workoutPlans?.single.name, '胸背强化');
    expect(snapshot.activeWorkoutSession?.groupsFor('蝴蝶机夹胸'), 2);
    expect(snapshot.workoutHistory?.single.totalGroups, 4);
  });
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "life summary snapshot carries workout training state"
```

预期：如果任务 1 已完成，此测试可能直接通过；若字段未完全接入，应出现字段或构造参数错误。继续执行本任务把状态接入实际持久化。

- [ ] **步骤 3：扩展 LifeHomePage 状态**

在 `lib/home/life_home_page.dart` 的 `_LifeHomePageState` 中加入：

```dart
  final List<WorkoutPlan> _workoutPlans = _createDefaultWorkoutPlans();
  ActiveWorkoutSession? _activeWorkoutSession;
  final List<WorkoutHistoryEntry> _workoutHistory = [];
```

- [ ] **步骤 4：新增默认训练计划工厂**

在 `lib/modules/workout/workout_models.dart` 底部添加：

```dart
List<WorkoutPlan> _createDefaultWorkoutPlans() {
  final now = DateTime.now();
  return [
    WorkoutPlan(
      id: 'plan-chest-back',
      name: '胸背强化',
      target: '胸背力量和体态稳定',
      bodyParts: const ['胸背'],
      actionNames: const [
        '蝴蝶机夹胸',
        '宽握高位下拉',
        '器械推胸',
        '坐姿绳索划船',
        '上斜哑铃卧推',
      ],
      estimatedMinutes: 38,
      createdAt: now,
      updatedAt: now,
    ),
    WorkoutPlan(
      id: 'plan-leg-stability',
      name: '腿部稳定',
      target: '下肢力量和髋膝稳定',
      bodyParts: const ['腿部'],
      actionNames: const [
        '杠铃深蹲',
        '腿举',
        '罗马尼亚硬拉',
        '保加利亚分腿蹲',
      ],
      estimatedMinutes: 34,
      createdAt: now,
      updatedAt: now,
    ),
    WorkoutPlan(
      id: 'plan-core-recovery',
      name: '核心恢复',
      target: '核心控制和轻恢复',
      bodyParts: const ['核心', '拉伸'],
      actionNames: const [
        '平板支撑',
        '死虫式',
        '猫牛式',
        '婴儿式',
      ],
      estimatedMinutes: 24,
      createdAt: now,
      updatedAt: now,
    ),
    WorkoutPlan(
      id: 'plan-quick-ten',
      name: '快练 10 分钟',
      target: '碎片时间快速激活',
      bodyParts: const ['核心', '有氧'],
      actionNames: const [
        '登山跑',
        '俄罗斯转体',
        '波比跳',
      ],
      estimatedMinutes: 10,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
```

如果现有动作名称和上方名称不一致，以 `lib/modules/workout/workout_module.dart` 中 `_actions` 的实际 `name` 为准修改计划里的 `actionNames`。

- [ ] **步骤 5：升级 AppDataStore 数据库版本和表**

在 `lib/storage/app_data_store.dart` 修改：

```dart
  static const _databaseVersion = 4;
```

在 `onCreate` 中追加：

```dart
        await _createWorkoutTrainingTables(db);
```

在 `_AppDataStore` 中添加：

```dart
  Future<void> _createWorkoutTrainingTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE workout_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        position INTEGER NOT NULL,
        planId TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        target TEXT NOT NULL,
        bodyPartsJson TEXT NOT NULL,
        actionNamesJson TEXT NOT NULL,
        estimatedMinutes INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE active_workout_session (
        id INTEGER PRIMARY KEY,
        sessionId TEXT NOT NULL,
        planId TEXT NOT NULL,
        planName TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        actionProgressJson TEXT NOT NULL,
        feedback TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        position INTEGER NOT NULL,
        entryId TEXT NOT NULL UNIQUE,
        planId TEXT NOT NULL,
        planName TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        finishedAt TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        totalGroups INTEGER NOT NULL,
        estimatedCalories INTEGER NOT NULL,
        actionResultsJson TEXT NOT NULL,
        feedback TEXT NOT NULL
      )
    ''');
  }
```

`DatabaseExecutor` 可由 `sqflite` 提供；如果 analyzer 提示不可用，则把参数类型改为 `Database` 并在 `onUpgrade` 里分别执行建表 SQL。

- [ ] **步骤 6：添加升级逻辑**

在 `onUpgrade` 中追加：

```dart
        if (oldVersion < 4) {
          await _createWorkoutTrainingTables(db);
        }
```

- [ ] **步骤 7：扩展 save 参数和写入逻辑**

把 `save()` 和 `_saveNow()` 增加参数：

```dart
    required List<WorkoutPlan> workoutPlans,
    required ActiveWorkoutSession? activeWorkoutSession,
    required List<WorkoutHistoryEntry> workoutHistory,
```

在事务删除处追加：

```dart
        await txn.delete('workout_plans');
        await txn.delete('active_workout_session');
        await txn.delete('workout_history');
```

在写入 `workout_groups` 后追加：

```dart
        for (var index = 0; index < workoutPlans.length; index++) {
          final plan = workoutPlans[index];
          await txn.insert('workout_plans', {
            'position': index,
            'planId': plan.id,
            'name': plan.name,
            'target': plan.target,
            'bodyPartsJson': jsonEncode(plan.bodyParts),
            'actionNamesJson': jsonEncode(plan.actionNames),
            'estimatedMinutes': plan.estimatedMinutes,
            'createdAt': plan.createdAt.toIso8601String(),
            'updatedAt': plan.updatedAt.toIso8601String(),
          });
        }

        final session = activeWorkoutSession;
        if (session != null) {
          await txn.insert('active_workout_session', {
            'id': 1,
            'sessionId': session.id,
            'planId': session.planId,
            'planName': session.planName,
            'startedAt': session.startedAt.toIso8601String(),
            'actionProgressJson': jsonEncode(session.actionProgress),
            'feedback': session.feedback,
          });
        }

        for (var index = 0; index < workoutHistory.length; index++) {
          final entry = workoutHistory[index];
          await txn.insert('workout_history', {
            'position': index,
            'entryId': entry.id,
            'planId': entry.planId,
            'planName': entry.planName,
            'startedAt': entry.startedAt.toIso8601String(),
            'finishedAt': entry.finishedAt.toIso8601String(),
            'durationMinutes': entry.durationMinutes,
            'totalGroups': entry.totalGroups,
            'estimatedCalories': entry.estimatedCalories,
            'actionResultsJson': jsonEncode(
              entry.actionResults.map((item) => item.toJson()).toList(),
            ),
            'feedback': entry.feedback,
          });
        }
```

- [ ] **步骤 8：扩展 load 读取逻辑**

在 `load()` 中读取表：

```dart
      final workoutPlanRows = await db.query(
        'workout_plans',
        orderBy: 'position ASC, id ASC',
      );
      final activeSessionRows = await db.query(
        'active_workout_session',
        limit: 1,
      );
      final workoutHistoryRows = await db.query(
        'workout_history',
        orderBy: 'position ASC, id ASC',
      );
```

构造 `LifeSummarySnapshot` 时增加：

```dart
        workoutPlans: workoutPlanRows.map(_workoutPlanFromRow).toList(),
        activeWorkoutSession: activeSessionRows.isEmpty
            ? null
            : _activeWorkoutSessionFromRow(activeSessionRows.first),
        workoutHistory:
            workoutHistoryRows.map(_workoutHistoryFromRow).toList(),
```

新增 row mapper：

```dart
  WorkoutPlan _workoutPlanFromRow(Map<String, Object?> row) {
    return WorkoutPlan.fromJson({
      'id': row['planId'],
      'name': row['name'],
      'target': row['target'],
      'bodyParts': _decodeJsonList(row['bodyPartsJson']),
      'actionNames': _decodeJsonList(row['actionNamesJson']),
      'estimatedMinutes': row['estimatedMinutes'],
      'createdAt': row['createdAt'],
      'updatedAt': row['updatedAt'],
    });
  }

  ActiveWorkoutSession _activeWorkoutSessionFromRow(
    Map<String, Object?> row,
  ) {
    return ActiveWorkoutSession.fromJson({
      'id': row['sessionId'],
      'planId': row['planId'],
      'planName': row['planName'],
      'startedAt': row['startedAt'],
      'actionProgress': _decodeJsonMap(row['actionProgressJson']),
      'feedback': row['feedback'],
    });
  }

  WorkoutHistoryEntry _workoutHistoryFromRow(Map<String, Object?> row) {
    return WorkoutHistoryEntry.fromJson({
      'id': row['entryId'],
      'planId': row['planId'],
      'planName': row['planName'],
      'startedAt': row['startedAt'],
      'finishedAt': row['finishedAt'],
      'durationMinutes': row['durationMinutes'],
      'totalGroups': row['totalGroups'],
      'estimatedCalories': row['estimatedCalories'],
      'actionResults': _decodeJsonList(row['actionResultsJson']),
      'feedback': row['feedback'],
    });
  }

  List<Object?> _decodeJsonList(Object? source) {
    final text = source as String? ?? '[]';
    final decoded = jsonDecode(text);
    return decoded is List ? decoded : const [];
  }

  Map<String, Object?> _decodeJsonMap(Object? source) {
    final text = source as String? ?? '{}';
    final decoded = jsonDecode(text);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }
```

- [ ] **步骤 9：接入首页恢复和保存**

在 `lib/home/life_home_persistence.dart` 的 `_applyLifeSummarySnapshot()` 添加：

```dart
    final restoredWorkoutPlans = snapshot.workoutPlans;
    if (restoredWorkoutPlans != null && restoredWorkoutPlans.isNotEmpty) {
      _workoutPlans
        ..clear()
        ..addAll(restoredWorkoutPlans);
    }
    _activeWorkoutSession = snapshot.activeWorkoutSession;
    final restoredWorkoutHistory = snapshot.workoutHistory;
    if (restoredWorkoutHistory != null) {
      _workoutHistory
        ..clear()
        ..addAll(restoredWorkoutHistory);
    }
```

在 `_syncLinkedSummaryToWidget()` 调用 `_appDataStore.save()` 时添加：

```dart
        workoutPlans: _workoutPlans,
        activeWorkoutSession: _activeWorkoutSession,
        workoutHistory: _workoutHistory,
```

- [ ] **步骤 10：运行验证**

运行：

```powershell
flutter analyze
flutter test test/widget_test.dart --plain-name "life summary snapshot carries workout training state"
```

预期：analyze 无错误；测试 `All tests passed!`

- [ ] **步骤 11：Commit**

```powershell
git add lib/storage/app_data_store.dart lib/home/life_home_page.dart lib/home/life_home_persistence.dart lib/modules/workout/workout_models.dart test/widget_test.dart
git commit -m "feat: persist workout training state"
```

---

## 任务 3：计划页可点并能开始计划训练

**文件：**
- 修改：`lib/home/life_home_page.dart`
- 修改：`lib/home/life_home_mutations.dart`
- 修改：`lib/home/home_module_page_builder.dart`
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的计划详情测试**

在 `test/widget_test.dart` 添加：

```dart
  testWidgets('workout plan opens detail and starts plan training',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_plan_plan-chest-back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_plan_detail_sheet')), findsOneWidget);
    expect(find.text('胸背强化'), findsWidgets);
    expect(find.text('开始训练'), findsOneWidget);

    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_active_plan_banner')), findsOneWidget);
    expect(find.textContaining('胸背强化'), findsWidgets);
    expect(find.text('蝴蝶机夹胸'), findsWidgets);
  });
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan opens detail and starts plan training"
```

预期：失败，找不到 `workout_plan_plan-chest-back` 或计划详情 sheet。

- [ ] **步骤 3：扩展 WorkoutModulePage 构造参数**

在 `WorkoutModulePage` 添加：

```dart
    required this.workoutPlans,
    required this.activeWorkoutSession,
    required this.workoutHistory,
    required this.onStartWorkoutSession,
    required this.onUpdateWorkoutSession,
    required this.onFinishWorkoutSession,
```

字段：

```dart
  final List<WorkoutPlan> workoutPlans;
  final ActiveWorkoutSession? activeWorkoutSession;
  final List<WorkoutHistoryEntry> workoutHistory;
  final ValueChanged<ActiveWorkoutSession> onStartWorkoutSession;
  final ValueChanged<ActiveWorkoutSession> onUpdateWorkoutSession;
  final ValueChanged<WorkoutHistoryEntry> onFinishWorkoutSession;
```

- [ ] **步骤 4：把参数从首页传入锻炼模块**

在 `_buildLifeHomeModulePage()` 增加参数：

```dart
  required List<WorkoutPlan> workoutPlans,
  required ActiveWorkoutSession? activeWorkoutSession,
  required List<WorkoutHistoryEntry> workoutHistory,
  required ValueChanged<ActiveWorkoutSession> onStartWorkoutSession,
  required ValueChanged<ActiveWorkoutSession> onUpdateWorkoutSession,
  required ValueChanged<WorkoutHistoryEntry> onFinishWorkoutSession,
```

传给 `WorkoutModulePage`：

```dart
        workoutPlans: workoutPlans,
        activeWorkoutSession: activeWorkoutSession,
        workoutHistory: workoutHistory,
        onStartWorkoutSession: onStartWorkoutSession,
        onUpdateWorkoutSession: onUpdateWorkoutSession,
        onFinishWorkoutSession: onFinishWorkoutSession,
```

在 `LifeHomePage.build()` 调用 `_buildLifeHomeModulePage()` 时传：

```dart
      workoutPlans: _workoutPlans,
      activeWorkoutSession: _activeWorkoutSession,
      workoutHistory: _workoutHistory,
      onStartWorkoutSession: _startWorkoutSession,
      onUpdateWorkoutSession: _updateWorkoutSession,
      onFinishWorkoutSession: _finishWorkoutSession,
```

- [ ] **步骤 5：在首页 mutation 中添加训练会话方法**

在 `lib/home/life_home_mutations.dart` 添加：

```dart
  void _startWorkoutSession(ActiveWorkoutSession session) {
    _updateState(() {
      _activeWorkoutSession = session;
      _pushLifeEvent(
        LifeEvent(
          title: '开始训练',
          detail: session.planName,
          icon: Icons.fitness_center_rounded,
          color: AppColors.primary,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }

  void _updateWorkoutSession(ActiveWorkoutSession session) {
    _updateState(() => _activeWorkoutSession = session);
    _syncLinkedSummaryToWidget();
  }

  void _finishWorkoutSession(WorkoutHistoryEntry entry) {
    _updateState(() {
      _workoutHistory.insert(0, entry);
      _activeWorkoutSession = null;
      for (final result in entry.actionResults) {
        _workoutGroupsByAction[result.actionName] = result.finishedGroups;
      }
      _pushLifeEvent(
        LifeEvent(
          title: '完成训练',
          detail: '${entry.planName} · ${entry.totalGroups} 组',
          icon: Icons.fitness_center_rounded,
          color: AppColors.primary,
        ),
      );
    });
    _syncLinkedSummaryToWidget();
  }
```

- [ ] **步骤 6：让计划页使用真实计划并打开详情**

把 `_WorkoutPlanView` 改为接收计划：

```dart
class _WorkoutPlanView extends StatelessWidget {
  const _WorkoutPlanView({
    required this.plans,
    required this.actions,
    required this.onOpenPlan,
  });

  final List<WorkoutPlan> plans;
  final List<WorkoutAction> actions;
  final ValueChanged<WorkoutPlan> onOpenPlan;
```

在 `_buildWorkoutContent()` 中：

```dart
    if (_selectedTopTab == 1) {
      return _WorkoutPlanView(
        plans: widget.workoutPlans,
        actions: _actions,
        onOpenPlan: _openPlanDetail,
      );
    }
```

计划卡片 key：

```dart
key: ValueKey('workout_plan_${plan.id}')
```

- [ ] **步骤 7：添加计划详情 Sheet**

在 `workout_module.dart` 添加 `_openPlanDetail()`：

```dart
  void _openPlanDetail(WorkoutPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutPlanDetailSheet(
          plan: plan,
          actions: _actions
              .where((action) => plan.actionNames.contains(action.name))
              .toList(),
          onStart: () {
            Navigator.of(context).pop();
            _startPlanTraining(plan);
          },
        );
      },
    );
  }
```

添加 `_WorkoutPlanDetailSheet`，根节点 key 为：

```dart
key: const ValueKey('workout_plan_detail_sheet')
```

按钮文字固定为：

```dart
FilledButton(
  onPressed: actions.isEmpty ? null : onStart,
  child: const Text('开始训练'),
)
```

- [ ] **步骤 8：实现开始计划训练**

在 `_WorkoutModulePageState` 添加：

```dart
  void _startPlanTraining(WorkoutPlan plan) {
    final progress = {
      for (final actionName in plan.actionNames) actionName: 0,
    };
    final session = ActiveWorkoutSession(
      planId: plan.id,
      planName: plan.name,
      startedAt: DateTime.now(),
      actionProgress: progress,
    );
    widget.onStartWorkoutSession(session);
    setState(() {
      _selectedTopTab = 0;
      _activeBodyPart = plan.bodyParts.isEmpty
          ? '全部'
          : _bodyPartLabel(plan.bodyParts.first);
      _activeAction = _actions.firstWhere(
        (action) => plan.actionNames.contains(action.name),
        orElse: () => _nextAction,
      );
    });
  }
```

- [ ] **步骤 9：训练页显示当前计划 Banner 并筛选动作**

在 `_buildWorkoutContent()` 的训练列表开头加入：

```dart
        if (widget.activeWorkoutSession != null) ...[
          _ActiveWorkoutPlanBanner(session: widget.activeWorkoutSession!),
          const SizedBox(height: 12),
        ],
```

计算 `visibleActions` 时优先使用当前训练：

```dart
    final session = widget.activeWorkoutSession;
    final plannedActions = session == null
        ? _actions
        : _actions
            .where((action) => session.actionProgress.containsKey(action.name))
            .toList();
    final visibleActions = _activeBodyPart == '全部'
        ? plannedActions
        : plannedActions
            .where(
                (action) => _bodyPartLabel(action.bodyPart) == _activeBodyPart)
            .toList();
```

`_ActiveWorkoutPlanBanner` 根节点 key：

```dart
key: const ValueKey('workout_active_plan_banner')
```

- [ ] **步骤 10：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan opens detail and starts plan training"
flutter analyze
```

预期：测试通过；analyze 无错误。

- [ ] **步骤 11：Commit**

```powershell
git add lib/home/life_home_page.dart lib/home/life_home_mutations.dart lib/home/home_module_page_builder.dart lib/modules/workout/workout_module.dart test/widget_test.dart
git commit -m "feat: start workouts from plans"
```

---

## 任务 4：训练会话记录组数并生成历史

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 修改：`lib/home/life_home_mutations.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的训练完成测试**

在 `test/widget_test.dart` 添加：

```dart
  testWidgets('finishing planned workout creates history entry',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_plan_plan-quick-ten')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    while (find.text('完成一组').evaluate().isNotEmpty) {
      await tester.tap(find.text('完成一组'));
      await tester.pumpAndSettle();
      if (find.text('完成训练').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('完成训练'), findsOneWidget);
    await tester.tap(find.text('完成训练'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_3')));
    await tester.pumpAndSettle();

    expect(find.text('快练 10 分钟'), findsWidgets);
    expect(find.byKey(const ValueKey('workout_history_real_list')), findsOneWidget);
  });
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "finishing planned workout creates history entry"
```

预期：失败，原因是完成训练按钮或真实历史列表不存在。

- [ ] **步骤 3：让完成组数优先写入当前会话**

修改 `_finishNextGroup()`：

```dart
  void _finishNextGroup() {
    final action = _activeAction;
    if (action == null) {
      return;
    }
    final currentGroups = _finishedGroupsFor(action);
    final nextCount = math.min(action.groups, currentGroups + 1);
    final session = widget.activeWorkoutSession;
    if (session != null && session.actionProgress.containsKey(action.name)) {
      final nextProgress = Map<String, int>.of(session.actionProgress);
      nextProgress[action.name] = nextCount;
      widget.onUpdateWorkoutSession(
        session.copyWith(
          actionProgress: nextProgress,
          feedback: _lastFeedback,
        ),
      );
    }
    widget.onUpdateActionGroups(action.name, nextCount);
    setState(() => _restSecondsLeft = nextCount >= action.groups ? 0 : 120);
  }
```

- [ ] **步骤 4：让 `_finishedGroupsFor` 读取当前训练会话**

修改：

```dart
  int _finishedGroupsFor(WorkoutAction action) {
    final session = widget.activeWorkoutSession;
    if (session != null && session.actionProgress.containsKey(action.name)) {
      return session.groupsFor(action.name);
    }
    return widget.finishedGroupsByAction[action.name] ?? 0;
  }
```

- [ ] **步骤 5：添加计划完成判断和完成按钮**

新增：

```dart
  bool get _activePlanCompleted {
    final session = widget.activeWorkoutSession;
    if (session == null) {
      return false;
    }
    final plannedActions = _actions.where(
      (action) => session.actionProgress.containsKey(action.name),
    );
    return plannedActions.every(
      (action) => session.groupsFor(action.name) >= action.groups,
    );
  }
```

在训练列表 banner 下添加：

```dart
          if (_activePlanCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _finishActivePlan,
                  child: const Text('完成训练'),
                ),
              ),
            ),
```

- [ ] **步骤 6：生成 WorkoutHistoryEntry**

添加：

```dart
  void _finishActivePlan() {
    final session = widget.activeWorkoutSession;
    if (session == null) {
      return;
    }
    final now = DateTime.now();
    final results = _actions
        .where((action) => session.actionProgress.containsKey(action.name))
        .map(
          (action) => WorkoutActionResult(
            actionName: action.name,
            bodyPart: action.bodyPart,
            targetGroups: action.groups,
            finishedGroups: session.groupsFor(action.name),
            reps: action.reps,
            weight: action.weight,
          ),
        )
        .toList();
    final totalGroups = results.fold(
      0,
      (total, result) => total + result.finishedGroups,
    );
    final duration = math.max(1, now.difference(session.startedAt).inMinutes);
    widget.onFinishWorkoutSession(
      WorkoutHistoryEntry(
        planId: session.planId,
        planName: session.planName,
        startedAt: session.startedAt,
        finishedAt: now,
        durationMinutes: duration,
        totalGroups: totalGroups,
        estimatedCalories: 80 + totalGroups * 18,
        actionResults: results,
        feedback: _lastFeedback,
      ),
    );
    setState(() {
      _selectedTopTab = 3;
      _activeAction = null;
      _restSecondsLeft = 0;
    });
  }
```

- [ ] **步骤 7：历史页接入真实历史列表**

把 `_WorkoutHistoryView` 改为接收：

```dart
  const _WorkoutHistoryView({
    required this.history,
    required this.onOpenHistory,
  });

  final List<WorkoutHistoryEntry> history;
  final ValueChanged<WorkoutHistoryEntry> onOpenHistory;
```

在列表中真实历史容器 key：

```dart
key: const ValueKey('workout_history_real_list')
```

渲染每条历史：

```dart
...history.map(
  (entry) => _WorkoutHistoryTile(
    title: entry.planName,
    subtitle:
        '${entry.actionResults.length} 个动作 · ${entry.totalGroups} 组 · ${entry.durationMinutes} min',
    status: _historyStatusLabel(entry.finishedAt),
    color: AppColors.primary,
    onTap: () => onOpenHistory(entry),
  ),
),
```

如果 `history.isEmpty`，显示空状态文字 `暂无训练记录`。

- [ ] **步骤 8：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "finishing planned workout creates history entry"
flutter analyze
```

预期：测试通过；analyze 无错误。

- [ ] **步骤 9：Commit**

```powershell
git add lib/modules/workout/workout_module.dart lib/home/life_home_mutations.dart test/widget_test.dart
git commit -m "feat: create workout history from sessions"
```

---

## 任务 5：数据页读取真实训练统计并支持明细

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的数据统计测试**

在 `test/widget_test.dart` 添加：

```dart
  testWidgets('workout data cards open real metric detail', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_plan_plan-quick-ten')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    while (find.text('完成一组').evaluate().isNotEmpty) {
      await tester.tap(find.text('完成一组'));
      await tester.pumpAndSettle();
      if (find.text('完成训练').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.tap(find.text('完成训练'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_metric_today_groups')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_metric_detail_sheet')), findsOneWidget);
    expect(find.text('今日完成组数'), findsWidgets);
    expect(find.textContaining('快练 10 分钟'), findsWidgets);
  });
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout data cards open real metric detail"
```

预期：失败，找不到 `workout_metric_today_groups`。

- [ ] **步骤 3：新增统计模型**

在 `lib/modules/workout/workout_models.dart` 添加：

```dart
enum WorkoutMetricKind {
  todayGroups('今日完成组数'),
  todayMinutes('今日训练时长'),
  todayCalories('今日预估消耗'),
  maxWeight('今日最高重量'),
  recentSessions('最近训练次数'),
  recentGroups('最近完成组数');

  const WorkoutMetricKind(this.label);

  final String label;
}

class WorkoutMetricDetail {
  const WorkoutMetricDetail({
    required this.kind,
    required this.value,
    required this.records,
  });

  final WorkoutMetricKind kind;
  final String value;
  final List<WorkoutHistoryEntry> records;
}
```

- [ ] **步骤 4：让数据页接收历史并计算统计**

修改 `_WorkoutDataView`：

```dart
  const _WorkoutDataView({
    required this.history,
    required this.onOpenMetric,
  });

  final List<WorkoutHistoryEntry> history;
  final ValueChanged<WorkoutMetricDetail> onOpenMetric;
```

计算：

```dart
    final today = DateUtils.dateOnly(DateTime.now());
    final todayRecords = history
        .where((entry) => DateUtils.isSameDay(entry.finishedAt, today))
        .toList();
    final recentStart = today.subtract(const Duration(days: 6));
    final recentRecords = history
        .where((entry) => !entry.finishedAt.isBefore(recentStart))
        .toList();
    final todayGroups = todayRecords.fold(
      0,
      (total, entry) => total + entry.totalGroups,
    );
    final todayMinutes = todayRecords.fold(
      0,
      (total, entry) => total + entry.durationMinutes,
    );
    final todayCalories = todayRecords.fold(
      0,
      (total, entry) => total + entry.estimatedCalories,
    );
```

数据卡 key：

```dart
key: const ValueKey('workout_metric_today_groups')
```

点击：

```dart
onTap: () => onOpenMetric(
  WorkoutMetricDetail(
    kind: WorkoutMetricKind.todayGroups,
    value: '$todayGroups 组',
    records: todayRecords,
  ),
),
```

- [ ] **步骤 5：添加数据明细 Sheet**

在 `_WorkoutModulePageState` 添加：

```dart
  void _openMetricDetail(WorkoutMetricDetail detail) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutMetricDetailSheet(detail: detail);
      },
    );
  }
```

`_WorkoutMetricDetailSheet` 根节点：

```dart
key: const ValueKey('workout_metric_detail_sheet')
```

内容显示 `detail.kind.label`、`detail.value`、`detail.records` 的计划名称列表。

- [ ] **步骤 6：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout data cards open real metric detail"
flutter analyze
```

预期：测试通过；analyze 无错误。

- [ ] **步骤 7：Commit**

```powershell
git add lib/modules/workout/workout_module.dart lib/modules/workout/workout_models.dart test/widget_test.dart
git commit -m "feat: show workout metrics from history"
```

---

## 任务 6：历史详情和再次训练同计划

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的历史详情测试**

在 `test/widget_test.dart` 添加：

```dart
  testWidgets('workout history detail can restart same plan', (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_plan_plan-quick-ten')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    while (find.text('完成一组').evaluate().isNotEmpty) {
      await tester.tap(find.text('完成一组'));
      await tester.pumpAndSettle();
      if (find.text('完成训练').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.tap(find.text('完成训练'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('快练 10 分钟').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_history_detail_sheet')), findsOneWidget);
    expect(find.text('再次训练'), findsOneWidget);

    await tester.tap(find.text('再次训练'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_active_plan_banner')), findsOneWidget);
    expect(find.textContaining('快练 10 分钟'), findsWidgets);
  });
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout history detail can restart same plan"
```

预期：失败，找不到历史详情 sheet。

- [ ] **步骤 3：添加历史详情 Sheet**

在 `_WorkoutModulePageState` 添加：

```dart
  void _openHistoryDetail(WorkoutHistoryEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutHistoryDetailSheet(
          entry: entry,
          onRestart: () {
            Navigator.of(context).pop();
            _restartPlanFromHistory(entry);
          },
        );
      },
    );
  }
```

`_WorkoutHistoryDetailSheet` 根节点：

```dart
key: const ValueKey('workout_history_detail_sheet')
```

展示内容：

```dart
Text(entry.planName)
Text('${entry.totalGroups} 组 · ${entry.durationMinutes} min')
...entry.actionResults.map((result) => Text(
  '${result.actionName} ${result.finishedGroups}/${result.targetGroups} 组',
))
FilledButton(
  onPressed: onRestart,
  child: const Text('再次训练'),
)
```

- [ ] **步骤 4：实现再次训练同计划**

添加：

```dart
  void _restartPlanFromHistory(WorkoutHistoryEntry entry) {
    final plan = widget.workoutPlans.firstWhere(
      (plan) => plan.id == entry.planId,
      orElse: () => WorkoutPlan(
        id: entry.planId,
        name: entry.planName,
        target: '再次训练',
        bodyParts: entry.actionResults
            .map((result) => _bodyPartLabel(result.bodyPart))
            .toSet()
            .toList(),
        actionNames:
            entry.actionResults.map((result) => result.actionName).toList(),
        estimatedMinutes: entry.durationMinutes,
      ),
    );
    _startPlanTraining(plan);
  }
```

在 `_WorkoutHistoryView` 中把 `onOpenHistory: _openHistoryDetail` 传下去。

- [ ] **步骤 5：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout history detail can restart same plan"
flutter analyze
```

预期：测试通过；analyze 无错误。

- [ ] **步骤 6：Commit**

```powershell
git add lib/modules/workout/workout_module.dart test/widget_test.dart
git commit -m "feat: add workout history detail"
```

---

## 任务 7：计划轻量编辑

**文件：**
- 修改：`lib/home/life_home_mutations.dart`
- 修改：`lib/home/home_module_page_builder.dart`
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的计划编辑测试**

在 `test/widget_test.dart` 添加：

```dart
  testWidgets('workout plan detail can remove and add existing action',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout_plan_plan-chest-back')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('编辑计划'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_plan_edit_sheet')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout_plan_remove_蝴蝶机夹胸')));
    await tester.pumpAndSettle();

    expect(find.text('蝴蝶机夹胸'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('workout_plan_add_蝴蝶机夹胸')));
    await tester.pumpAndSettle();

    expect(find.text('蝴蝶机夹胸'), findsOneWidget);
  });
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan detail can remove and add existing action"
```

预期：失败，找不到编辑计划入口或编辑 sheet。

- [ ] **步骤 3：新增更新计划回调**

在 `LifeHomeMutations` 添加：

```dart
  void _updateWorkoutPlan(WorkoutPlan plan) {
    final index = _workoutPlans.indexWhere((item) => item.id == plan.id);
    if (index == -1) {
      return;
    }
    _updateState(() => _workoutPlans[index] = plan);
    _syncLinkedSummaryToWidget();
  }
```

在 `home_module_page_builder.dart` 和 `WorkoutModulePage` 传入：

```dart
required ValueChanged<WorkoutPlan> onUpdateWorkoutPlan,
```

- [ ] **步骤 4：计划详情添加编辑入口**

在 `_WorkoutPlanDetailSheet` 添加：

```dart
OutlinedButton(
  onPressed: onEdit,
  child: const Text('编辑计划'),
)
```

`onEdit` 打开 `_WorkoutPlanEditSheet`，根 key：

```dart
key: const ValueKey('workout_plan_edit_sheet')
```

- [ ] **步骤 5：实现移除和添加已有动作**

`_WorkoutPlanEditSheet` 接收：

```dart
final WorkoutPlan plan;
final List<WorkoutAction> allActions;
final ValueChanged<WorkoutPlan> onChanged;
```

移除按钮 key：

```dart
ValueKey('workout_plan_remove_${action.name}')
```

添加按钮 key：

```dart
ValueKey('workout_plan_add_${action.name}')
```

移除实现：

```dart
final nextActionNames = plan.actionNames
    .where((actionName) => actionName != action.name)
    .toList();
onChanged(plan.copyWith(actionNames: nextActionNames));
```

添加实现：

```dart
final nextActionNames = [...plan.actionNames, action.name];
onChanged(plan.copyWith(actionNames: nextActionNames));
```

- [ ] **步骤 6：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan detail can remove and add existing action"
flutter analyze
```

预期：测试通过；analyze 无错误。

- [ ] **步骤 7：Commit**

```powershell
git add lib/home/life_home_mutations.dart lib/home/home_module_page_builder.dart lib/modules/workout/workout_module.dart test/widget_test.dart
git commit -m "feat: edit workout plans"
```

---

## 任务 8：全量验证和发布前检查

**文件：**
- 修改：按前面任务产生的实际变更。
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：运行锻炼相关测试**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout models serialize and restore training history"
flutter test test/widget_test.dart --plain-name "life summary snapshot carries workout training state"
flutter test test/widget_test.dart --plain-name "workout plan opens detail and starts plan training"
flutter test test/widget_test.dart --plain-name "finishing planned workout creates history entry"
flutter test test/widget_test.dart --plain-name "workout data cards open real metric detail"
flutter test test/widget_test.dart --plain-name "workout history detail can restart same plan"
flutter test test/widget_test.dart --plain-name "workout plan detail can remove and add existing action"
```

预期：每条命令都输出 `All tests passed!`

- [ ] **步骤 2：运行既有关键回归测试**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout top tabs show plan data and history"
flutter test test/widget_test.dart --plain-name "workout history shows calendar and progress trends"
flutter test test/widget_test.dart --plain-name "module link strip jumps between every main module"
flutter test test/widget_test.dart --plain-name "module sheet switches to finance overview"
```

预期：每条命令都输出 `All tests passed!`

- [ ] **步骤 3：运行静态分析**

运行：

```powershell
flutter analyze
```

预期：`No issues found!`

- [ ] **步骤 4：查看工作区 diff**

运行：

```powershell
git status --short --branch
git diff --stat
```

预期：只出现本功能相关文件。

- [ ] **步骤 5：最终提交**

如果任务 1-7 每个任务都已独立提交，此步骤只需确认无未提交变更：

```powershell
git status --short
```

预期：没有输出。

如果仍有格式化或测试补丁，提交：

```powershell
git add lib test
git commit -m "test: cover workout training system"
```

---

## 覆盖度自检

规格要求与任务对应关系：

- 计划页可点击并打开详情：任务 3。
- 计划详情展示动作、总组数、预计时长、目标部位：任务 3。
- 从计划详情开始训练：任务 3。
- 训练页只显示该计划动作：任务 3。
- 训练组数写入当前会话：任务 4。
- 完成训练生成历史记录：任务 4。
- 数据页读取训练记录统计：任务 5。
- 数据卡点击查看明细：任务 5。
- 历史页打开训练详情：任务 6。
- 历史详情再次训练同计划：任务 6。
- 计划轻量编辑：任务 7。
- SQLite 持久化：任务 2。
- 回归验证：任务 8。

计划约束：

- 不引入云端同步。
- 不创建全新动作编辑器。
- 不重构整个 Flutter 架构。
- 不改变现有认证、更新、饮食、财务和健康模块接口。
