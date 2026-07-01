# 锻炼完整训练系统实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 把锻炼模块升级为从计划开始、训练中记录、完成后生成历史、数据页和历史页读取真实记录的本地训练闭环。

**架构：** 继续遵循当前项目的 `part of '../main.dart'` 单库结构，把锻炼领域模型放入 `lib/models/life_data.dart`，把应用级状态放在 `LifeHomePage`，由 `WorkoutModulePage` 负责锻炼 UI 和交互。第一版不引入新状态框架，不拆大规模目录，只增加清晰的数据模型、持久化表和模块回调。

**技术栈：** Flutter、Dart、sqflite、现有 widget test、现有 App 本地优先状态架构。

---

## 文件结构

计划修改和创建的文件如下：

- 修改：`lib/models/life_data.dart`
  - 增加 `WorkoutPlan`、`ActiveWorkoutSession`、`WorkoutActionResult`、`WorkoutHistoryEntry`。
  - 扩展 `LifeSummarySnapshot`，让本地恢复能带回训练计划、当前训练和历史记录。

- 修改：`lib/home/life_home_page.dart`
  - 增加 `_workoutPlans`、`_activeWorkoutSession`、`_workoutHistory` 应用级状态。
  - 把新状态和回调传给 `WorkoutModulePage`。

- 修改：`lib/home/life_home_seed_data.dart`
  - 增加 `_createDefaultWorkoutPlans()`。

- 修改：`lib/home/life_home_mutations.dart`
  - 增加开始计划训练、更新训练进度、完成训练、编辑训练计划的状态变更函数。

- 修改：`lib/home/life_home_persistence.dart`
  - 从 `LifeSummarySnapshot` 恢复训练计划、当前训练和历史记录。
  - 保存时把训练数据传入 `_AppDataStore.save()`。

- 修改：`lib/storage/app_data_store.dart`
  - 数据库版本升级到 4。
  - 增加 `workout_plans`、`active_workout_session`、`workout_history` 表。
  - 读写训练计划、当前训练、训练历史。

- 修改：`lib/home/home_module_page_builder.dart`
  - 给 `WorkoutModulePage` 追加训练系统参数和回调。

- 修改：`lib/modules/workout/workout_module.dart`
  - 计划页可点击并打开计划详情。
  - 从计划详情开始训练。
  - 训练页进入计划训练模式。
  - 完成计划后生成历史。
  - 数据页读取训练历史统计。
  - 历史页展示真实记录、详情、再次训练。
  - 计划详情支持轻量编辑。

- 修改：`test/widget_test.dart`
  - 增加训练计划、会话、历史、数据统计、轻量编辑相关 widget test。

---

### 任务 1：添加锻炼领域模型

**文件：**
- 修改：`lib/models/life_data.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的模型序列化测试**

在 `test/widget_test.dart` 中靠近其他模型/存储相关测试的位置增加测试：

```dart
test('workout training models serialize and restore', () {
  final plan = WorkoutPlan(
    id: 'plan_chest',
    name: '胸背强化',
    target: '胸背力量',
    bodyParts: const ['胸背'],
    actionNames: const ['蝴蝶机夹胸', '宽握高位下拉'],
    estimatedMinutes: 36,
    createdAt: DateTime(2026, 6, 28, 9),
    updatedAt: DateTime(2026, 6, 28, 9),
  );
  final session = ActiveWorkoutSession(
    id: 'session_1',
    planId: plan.id,
    planName: plan.name,
    startedAt: DateTime(2026, 6, 28, 10),
    actionProgress: const {'蝴蝶机夹胸': 2},
    feedback: '适中',
  );
  final entry = WorkoutHistoryEntry(
    id: 'history_1',
    planId: plan.id,
    planName: plan.name,
    startedAt: DateTime(2026, 6, 28, 10),
    finishedAt: DateTime(2026, 6, 28, 10, 36),
    durationMinutes: 36,
    totalGroups: 8,
    estimatedCalories: 188,
    feedback: '适中',
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
  );

  expect(WorkoutPlan.fromJson(plan.toJson()).actionNames, plan.actionNames);
  expect(
    ActiveWorkoutSession.fromJson(session.toJson()).actionProgress['蝴蝶机夹胸'],
    2,
  );
  expect(
    WorkoutHistoryEntry.fromJson(entry.toJson()).actionResults.first.weight,
    '30kg',
  );
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout training models serialize and restore"
```

预期：FAIL，报错包含 `WorkoutPlan` 或 `ActiveWorkoutSession` 未定义。

- [ ] **步骤 3：实现模型代码**

在 `lib/models/life_data.dart` 中 `LifeSummarySnapshot` 后、`TodoItem` 前加入以下模型。实际实现可以保持字段顺序一致：

```dart
class WorkoutPlan {
  WorkoutPlan({
    String? id,
    required this.name,
    required this.target,
    required this.bodyParts,
    required this.actionNames,
    required this.estimatedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? _newLocalId(prefix: 'workout_plan'),
        bodyParts = List.of(bodyParts),
        actionNames = List.of(actionNames),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final String target;
  final List<String> bodyParts;
  final List<String> actionNames;
  final int estimatedMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

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
      target: json['target'] as String? ?? '综合训练',
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
```

继续添加 `ActiveWorkoutSession`、`WorkoutActionResult`、`WorkoutHistoryEntry`。`toJson()` 和 `fromJson()` 必须使用字段名：

```dart
'id', 'planId', 'planName', 'startedAt', 'actionProgress', 'feedback'
'actionName', 'bodyPart', 'targetGroups', 'finishedGroups', 'reps', 'weight'
'finishedAt', 'durationMinutes', 'totalGroups', 'estimatedCalories', 'actionResults'
```

同时把 `_newLocalId()` 改成可传前缀：

```dart
String _newLocalId({String prefix = 'todo'}) {
  final micros = DateTime.now().microsecondsSinceEpoch;
  final salt = math.Random().nextInt(1 << 20).toRadixString(16);
  return '${prefix}_${micros}_$salt';
}
```

增加列表解析工具：

```dart
List<String> _stringListFromJson(Object? value) {
  if (value is List<dynamic>) {
    return value.whereType<String>().toList();
  }
  return [];
}
```

- [ ] **步骤 4：扩展 `LifeSummarySnapshot`**

在 `LifeSummarySnapshot` 构造函数增加可选字段：

```dart
this.workoutPlans,
this.activeWorkoutSession,
this.workoutHistory,
```

并增加字段：

```dart
final List<WorkoutPlan>? workoutPlans;
final ActiveWorkoutSession? activeWorkoutSession;
final List<WorkoutHistoryEntry>? workoutHistory;
```

- [ ] **步骤 5：运行模型测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout training models serialize and restore"
```

预期：PASS，输出包含 `All tests passed!`。

- [ ] **步骤 6：格式化并提交**

运行：

```powershell
dart format lib\models\life_data.dart test\widget_test.dart
git add lib\models\life_data.dart test\widget_test.dart
git commit -m "feat(workout): add training data models"
```

---

### 任务 2：接入首页状态和本地持久化

**文件：**
- 修改：`lib/home/life_home_page.dart`
- 修改：`lib/home/life_home_seed_data.dart`
- 修改：`lib/home/life_home_mutations.dart`
- 修改：`lib/home/life_home_persistence.dart`
- 修改：`lib/storage/app_data_store.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的默认计划测试**

在 `test/widget_test.dart` 增加：

```dart
test('default workout plans cover executable actions', () {
  final plans = _createDefaultWorkoutPlans();
  expect(plans.map((plan) => plan.name), contains('胸背强化'));
  expect(plans.map((plan) => plan.name), contains('快练 10 分钟'));
  expect(plans.first.actionNames, isNotEmpty);
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "default workout plans cover executable actions"
```

预期：FAIL，报错包含 `_createDefaultWorkoutPlans` 未定义。

- [ ] **步骤 3：添加默认训练计划**

在 `lib/home/life_home_seed_data.dart` 添加：

```dart
List<WorkoutPlan> _createDefaultWorkoutPlans() {
  final now = DateTime.now();
  return [
    WorkoutPlan(
      id: 'plan_chest_back',
      name: '胸背强化',
      target: '胸背力量',
      bodyParts: const ['胸背'],
      actionNames: const ['蝴蝶机夹胸', '宽握高位下拉', '器械推胸', '坐姿绳索划船', '上斜哑铃卧推'],
      estimatedMinutes: 45,
      createdAt: now,
      updatedAt: now,
    ),
    WorkoutPlan(
      id: 'plan_legs_stability',
      name: '腿部稳定',
      target: '下肢力量和稳定',
      bodyParts: const ['腿部'],
      actionNames: const ['杠铃深蹲', '腿举', '罗马尼亚硬拉', '保加利亚分腿蹲'],
      estimatedMinutes: 42,
      createdAt: now,
      updatedAt: now,
    ),
    WorkoutPlan(
      id: 'plan_core_recovery',
      name: '核心恢复',
      target: '核心控制和恢复',
      bodyParts: const ['核心', '拉伸'],
      actionNames: const ['平板支撑', '死虫', '猫牛式', '儿童式'],
      estimatedMinutes: 28,
      createdAt: now,
      updatedAt: now,
    ),
    WorkoutPlan(
      id: 'plan_quick_10',
      name: '快练 10 分钟',
      target: '碎片时间激活',
      bodyParts: const ['核心', '有氧'],
      actionNames: const ['平板支撑', '登山跑'],
      estimatedMinutes: 10,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
```

如果某个动作名在 `_WorkoutModulePageState._actions` 不存在，执行实现时必须选择已经存在的动作名替换，不能让计划引用空动作。

- [ ] **步骤 4：扩展首页状态**

在 `lib/home/life_home_page.dart` 的 `_LifeHomePageState` 字段中加入：

```dart
final List<WorkoutPlan> _workoutPlans = _createDefaultWorkoutPlans();
ActiveWorkoutSession? _activeWorkoutSession;
final List<WorkoutHistoryEntry> _workoutHistory = [];
```

- [ ] **步骤 5：添加首页状态变更方法**

在 `lib/home/life_home_mutations.dart` 添加：

```dart
void _startWorkoutPlan(WorkoutPlan plan) {
  _updateState(() {
    _activeWorkoutSession = ActiveWorkoutSession(
      planId: plan.id,
      planName: plan.name,
      startedAt: DateTime.now(),
      actionProgress: const {},
      feedback: _activeWorkoutSession?.feedback ?? '适中',
    );
    _pushLifeEvent(
      LifeEvent(
        title: '开始训练',
        detail: plan.name,
        icon: Icons.fitness_center_rounded,
        color: AppColors.primary,
      ),
    );
  });
  _syncLinkedSummaryToWidget();
}
```

同文件继续添加：

```dart
void _updateActiveWorkoutProgress(String actionName, int finishedGroups) {
  final session = _activeWorkoutSession;
  if (session == null) {
    _updateWorkoutGroups(actionName, finishedGroups);
    return;
  }
  final nextProgress = Map<String, int>.of(session.actionProgress);
  nextProgress[actionName] = finishedGroups;
  _updateState(() {
    _activeWorkoutSession = session.copyWith(actionProgress: nextProgress);
    _workoutGroupsByAction[actionName] = finishedGroups;
  });
  _syncLinkedSummaryToWidget();
}
```

添加完成训练和编辑计划方法：

```dart
void _finishWorkoutSession(WorkoutHistoryEntry entry) {
  _updateState(() {
    _workoutHistory.insert(0, entry);
    _activeWorkoutSession = null;
    for (final result in entry.actionResults) {
      _workoutGroupsByAction[result.actionName] = result.finishedGroups;
    }
    _pushLifeEvent(
      LifeEvent(
        title: '完成锻炼',
        detail: '${entry.planName} · ${entry.totalGroups} 组',
        icon: Icons.fitness_center_rounded,
        color: AppColors.primary,
      ),
    );
  });
  _syncLinkedSummaryToWidget();
}

void _updateWorkoutPlan(WorkoutPlan plan) {
  final index = _workoutPlans.indexWhere((item) => item.id == plan.id);
  if (index == -1) {
    return;
  }
  _updateState(() => _workoutPlans[index] = plan);
  _syncLinkedSummaryToWidget();
}
```

- [ ] **步骤 6：持久化恢复新状态**

在 `lib/home/life_home_persistence.dart` 的 `_applyLifeSummarySnapshot()` 中加入：

```dart
final restoredPlans = snapshot.workoutPlans;
if (restoredPlans != null && restoredPlans.isNotEmpty) {
  _workoutPlans
    ..clear()
    ..addAll(restoredPlans);
}
_activeWorkoutSession = snapshot.activeWorkoutSession;
final restoredHistory = snapshot.workoutHistory;
if (restoredHistory != null) {
  _workoutHistory
    ..clear()
    ..addAll(restoredHistory);
}
```

在 `_syncLinkedSummaryToWidget()` 调用 `_appDataStore.save()` 时传入：

```dart
workoutPlans: _workoutPlans,
activeWorkoutSession: _activeWorkoutSession,
workoutHistory: _workoutHistory,
```

- [ ] **步骤 7：升级 SQLite 表**

在 `lib/storage/app_data_store.dart`：

1. `_databaseVersion` 改为 `4`。
2. `save()` 和 `_saveNow()` 参数增加：

```dart
required List<WorkoutPlan> workoutPlans,
required ActiveWorkoutSession? activeWorkoutSession,
required List<WorkoutHistoryEntry> workoutHistory,
```

3. `load()` 查询新增表，并返回到 `LifeSummarySnapshot`。
4. `_saveNow()` 事务内清空并写入新增表。

新增建表 SQL：

```dart
await db.execute('''
  CREATE TABLE workout_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    position INTEGER NOT NULL,
    planId TEXT NOT NULL,
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
    id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    entryId TEXT NOT NULL,
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
```

在 `onUpgrade` 中如果 `oldVersion < 4`，执行同样三段 `CREATE TABLE IF NOT EXISTS` SQL。

- [ ] **步骤 8：运行测试验证默认计划通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "default workout plans cover executable actions"
```

预期：PASS。

- [ ] **步骤 9：运行静态检查并提交**

运行：

```powershell
dart format lib\models\life_data.dart lib\home\life_home_page.dart lib\home\life_home_seed_data.dart lib\home\life_home_mutations.dart lib\home\life_home_persistence.dart lib\storage\app_data_store.dart test\widget_test.dart
flutter analyze
git add lib\models\life_data.dart lib\home\life_home_page.dart lib\home\life_home_seed_data.dart lib\home\life_home_mutations.dart lib\home\life_home_persistence.dart lib\storage\app_data_store.dart test\widget_test.dart
git commit -m "feat(workout): persist training plans and sessions"
```

预期：`flutter analyze` 输出 `No issues found!`。

---

### 任务 3：把训练系统状态传入锻炼模块

**文件：**
- 修改：`lib/home/home_module_page_builder.dart`
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的传参烟雾测试**

在 `test/widget_test.dart` 增加：

```dart
testWidgets('workout module receives default training plans', (tester) async {
  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('module_link_3')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
  await tester.pumpAndSettle();

  expect(find.text('胸背强化'), findsOneWidget);
  expect(find.text('快练 10 分钟'), findsOneWidget);
});
```

- [ ] **步骤 2：运行测试验证失败或保持旧状态**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout module receives default training plans"
```

预期：如果计划页仍然写死旧静态卡片，测试可能 PASS；如果 PASS，继续执行步骤 3，因为本任务的目标是完成真实传参，不以这个测试失败作为唯一门槛。

- [ ] **步骤 3：扩展 `WorkoutModulePage` 构造函数**

在 `lib/modules/workout/workout_module.dart` 的 `WorkoutModulePage` 中加入字段：

```dart
required this.workoutPlans,
required this.activeWorkoutSession,
required this.workoutHistory,
required this.onStartWorkoutPlan,
required this.onUpdateActiveWorkoutProgress,
required this.onFinishWorkoutSession,
required this.onUpdateWorkoutPlan,
```

字段定义：

```dart
final List<WorkoutPlan> workoutPlans;
final ActiveWorkoutSession? activeWorkoutSession;
final List<WorkoutHistoryEntry> workoutHistory;
final ValueChanged<WorkoutPlan> onStartWorkoutPlan;
final void Function(String actionName, int finishedGroups)
    onUpdateActiveWorkoutProgress;
final ValueChanged<WorkoutHistoryEntry> onFinishWorkoutSession;
final ValueChanged<WorkoutPlan> onUpdateWorkoutPlan;
```

- [ ] **步骤 4：在 home builder 传入状态**

在 `lib/home/home_module_page_builder.dart` 中找到创建 `WorkoutModulePage` 的分支，增加参数：

```dart
workoutPlans: workoutPlans,
activeWorkoutSession: activeWorkoutSession,
workoutHistory: workoutHistory,
onStartWorkoutPlan: onStartWorkoutPlan,
onUpdateActiveWorkoutProgress: onUpdateActiveWorkoutProgress,
onFinishWorkoutSession: onFinishWorkoutSession,
onUpdateWorkoutPlan: onUpdateWorkoutPlan,
```

如果 `_buildLifeHomeModulePage()` 当前参数列表没有这些值，在函数参数中同步加入。

- [ ] **步骤 5：从 `LifeHomePage` 传到 builder**

在 `lib/home/life_home_page.dart` 调用 `_buildLifeHomeModulePage()` 时加入：

```dart
workoutPlans: _workoutPlans,
activeWorkoutSession: _activeWorkoutSession,
workoutHistory: _workoutHistory,
onStartWorkoutPlan: _startWorkoutPlan,
onUpdateActiveWorkoutProgress: _updateActiveWorkoutProgress,
onFinishWorkoutSession: _finishWorkoutSession,
onUpdateWorkoutPlan: _updateWorkoutPlan,
```

- [ ] **步骤 6：运行测试和分析**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout module receives default training plans"
flutter analyze
```

预期：测试 PASS，分析输出 `No issues found!`。

- [ ] **步骤 7：提交**

运行：

```powershell
git add lib\home\home_module_page_builder.dart lib\home\life_home_page.dart lib\modules\workout\workout_module.dart test\widget_test.dart
git commit -m "feat(workout): pass training state into module"
```

---

### 任务 4：计划页详情和开始训练

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的计划详情测试**

在 `test/widget_test.dart` 增加：

```dart
testWidgets('workout plan detail starts a planned workout', (tester) async {
  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('module_link_3')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('workout_plan_card_plan_chest_back')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('workout_plan_detail_sheet')), findsOneWidget);
  expect(find.text('胸背强化'), findsWidgets);
  expect(find.text('开始训练'), findsOneWidget);

  await tester.tap(find.text('开始训练'));
  await tester.pumpAndSettle();

  expect(find.text('当前计划'), findsOneWidget);
  expect(find.text('胸背强化'), findsWidgets);
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan detail starts a planned workout"
```

预期：FAIL，找不到 `workout_plan_card_plan_chest_back` 或 `workout_plan_detail_sheet`。

- [ ] **步骤 3：改造计划视图**

把 `_WorkoutPlanView` 构造函数改为：

```dart
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
    onOpenPlan: _openWorkoutPlanDetail,
  );
}
```

- [ ] **步骤 4：实现计划卡 key 和点击**

在 `_WorkoutPlanCard` 增加：

```dart
final String planId;
final VoidCallback onTap;
```

外层改为：

```dart
return Material(
  color: Colors.transparent,
  child: InkWell(
    key: ValueKey('workout_plan_card_$planId'),
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Container(
      ...
    ),
  ),
);
```

- [ ] **步骤 5：添加计划详情弹层**

在 `_WorkoutModulePageState` 增加：

```dart
void _openWorkoutPlanDetail(WorkoutPlan plan) {
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
          widget.onStartWorkoutPlan(plan);
          setState(() {
            _selectedTopTab = 0;
            _activeBodyPart = plan.bodyParts.firstOrNull ?? '全部';
            _activeAction = null;
          });
        },
        onEdit: () => _openWorkoutPlanEditor(plan),
      );
    },
  );
}
```

如果当前 Dart SDK 不支持 `firstOrNull`，使用：

```dart
_activeBodyPart = plan.bodyParts.isEmpty ? '全部' : plan.bodyParts.first;
```

添加 `_WorkoutPlanDetailSheet` 组件，根容器 key 为：

```dart
key: const ValueKey('workout_plan_detail_sheet')
```

底部按钮文本必须是 `开始训练`。

- [ ] **步骤 6：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan detail starts a planned workout"
```

预期：PASS。

- [ ] **步骤 7：提交**

运行：

```powershell
dart format lib\modules\workout\workout_module.dart test\widget_test.dart
flutter analyze
git add lib\modules\workout\workout_module.dart test\widget_test.dart
git commit -m "feat(workout): start training from plan detail"
```

---

### 任务 5：计划训练模式和进度记录

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的计划筛选测试**

在 `test/widget_test.dart` 增加：

```dart
testWidgets('planned workout filters actions and records progress',
    (tester) async {
  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('module_link_3')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_plan_card_plan_quick_10')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('开始训练'));
  await tester.pumpAndSettle();

  expect(find.text('当前计划'), findsOneWidget);
  expect(find.text('快练 10 分钟'), findsWidgets);
  expect(find.text('蝴蝶机夹胸'), findsNothing);
  expect(find.text('平板支撑'), findsWidgets);

  await tester.tap(find.text('平板支撑').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('完成一组'));
  await tester.pumpAndSettle();

  expect(find.textContaining('1/'), findsWidgets);
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "planned workout filters actions and records progress"
```

预期：FAIL，计划训练模式尚未筛选动作或进度未写入会话。

- [ ] **步骤 3：添加计划动作计算**

在 `_WorkoutModulePageState` 增加：

```dart
WorkoutPlan? get _activePlan {
  final session = widget.activeWorkoutSession;
  if (session == null) {
    return null;
  }
  for (final plan in widget.workoutPlans) {
    if (plan.id == session.planId) {
      return plan;
    }
  }
  return null;
}

List<WorkoutAction> get _plannedActions {
  final plan = _activePlan;
  if (plan == null) {
    return const [];
  }
  return _actions
      .where((action) => plan.actionNames.contains(action.name))
      .toList();
}
```

- [ ] **步骤 4：筛选训练列表**

在 `_buildWorkoutContent()` 里计算 `visibleActions` 时优先使用计划动作：

```dart
final activePlan = _activePlan;
final sourceActions = activePlan == null ? _actions : _plannedActions;
final visibleActions = activePlan != null || _activeBodyPart == '全部'
    ? sourceActions
    : sourceActions
        .where((action) => _bodyPartLabel(action.bodyPart) == _activeBodyPart)
        .toList();
```

在摘要区域加入 `当前计划` 小卡或在 `_WorkoutSummaryCard` 下方显示：

```dart
if (activePlan != null)
  _ActiveWorkoutPlanCard(
    planName: activePlan.name,
    finishedGroups: _finishedGroupsTotal,
    totalGroups: _totalGroupsFor(sourceActions),
  ),
```

- [ ] **步骤 5：让完成组数写入会话**

修改 `_finishNextGroup()`：

```dart
final nextCount = math.min(action.groups, _finishedGroupsFor(action) + 1);
if (widget.activeWorkoutSession == null) {
  widget.onUpdateActionGroups(action.name, nextCount);
} else {
  widget.onUpdateActiveWorkoutProgress(action.name, nextCount);
}
setState(() => _restSecondsLeft = nextCount >= action.groups ? 0 : 120);
_maybeFinishActivePlan();
```

修改 `_finishedGroupsFor()`，优先读取当前会话：

```dart
int _finishedGroupsFor(WorkoutAction action) {
  final sessionGroups = widget.activeWorkoutSession?.actionProgress[action.name];
  return sessionGroups ?? widget.finishedGroupsByAction[action.name] ?? 0;
}
```

- [ ] **步骤 6：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "planned workout filters actions and records progress"
```

预期：PASS。

- [ ] **步骤 7：提交**

运行：

```powershell
dart format lib\modules\workout\workout_module.dart test\widget_test.dart
flutter analyze
git add lib\modules\workout\workout_module.dart test\widget_test.dart
git commit -m "feat(workout): track planned workout progress"
```

---

### 任务 6：完成训练并生成历史记录

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的完成训练测试**

在 `test/widget_test.dart` 增加：

```dart
testWidgets('completing planned workout creates history entry',
    (tester) async {
  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('module_link_3')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_plan_card_plan_quick_10')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('开始训练'));
  await tester.pumpAndSettle();

  for (var i = 0; i < 3; i++) {
    await tester.tap(find.text('平板支撑').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成一组'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
  }

  expect(find.byKey(const ValueKey('workout_complete_sheet')), findsOneWidget);
  await tester.tap(find.text('查看历史'));
  await tester.pumpAndSettle();

  expect(find.text('训练历史'), findsWidgets);
  expect(find.text('快练 10 分钟'), findsWidgets);
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "completing planned workout creates history entry"
```

预期：FAIL，完成训练弹层或历史记录不存在。

- [ ] **步骤 3：实现完成判断**

在 `_WorkoutModulePageState` 增加：

```dart
void _maybeFinishActivePlan() {
  final session = widget.activeWorkoutSession;
  final plan = _activePlan;
  if (session == null || plan == null) {
    return;
  }
  final actions = _plannedActions;
  if (actions.isEmpty) {
    return;
  }
  final isDone = actions.every(
    (action) => _finishedGroupsFor(action) >= action.groups,
  );
  if (!isDone) {
    return;
  }
  final entry = _buildWorkoutHistoryEntry(plan, actions);
  widget.onFinishWorkoutSession(entry);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _openWorkoutCompleteSheet(entry);
    }
  });
}
```

- [ ] **步骤 4：构造历史记录**

加入：

```dart
WorkoutHistoryEntry _buildWorkoutHistoryEntry(
  WorkoutPlan plan,
  List<WorkoutAction> actions,
) {
  final session = widget.activeWorkoutSession;
  final startedAt = session?.startedAt ?? DateTime.now();
  final finishedAt = DateTime.now();
  final results = actions
      .map(
        (action) => WorkoutActionResult(
          actionName: action.name,
          bodyPart: action.bodyPart,
          targetGroups: action.groups,
          finishedGroups: _finishedGroupsFor(action),
          reps: action.reps,
          weight: action.weight,
        ),
      )
      .toList();
  final totalGroups =
      results.fold(0, (total, result) => total + result.finishedGroups);
  final duration = math.max(
    1,
    finishedAt.difference(startedAt).inMinutes,
  );
  return WorkoutHistoryEntry(
    planId: plan.id,
    planName: plan.name,
    startedAt: startedAt,
    finishedAt: finishedAt,
    durationMinutes: duration,
    totalGroups: totalGroups,
    estimatedCalories: 80 + totalGroups * 12,
    feedback: session?.feedback ?? _lastFeedback,
    actionResults: results,
  );
}
```

- [ ] **步骤 5：添加完成弹层**

添加 `_WorkoutCompleteSheet`，根 key：

```dart
key: const ValueKey('workout_complete_sheet')
```

按钮：

- `查看历史`：关闭弹层，`setState(() => _selectedTopTab = 3)`。
- `继续训练`：只关闭弹层。

- [ ] **步骤 6：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "completing planned workout creates history entry"
```

预期：PASS。

- [ ] **步骤 7：提交**

运行：

```powershell
dart format lib\modules\workout\workout_module.dart test\widget_test.dart
flutter analyze
git add lib\modules\workout\workout_module.dart test\widget_test.dart
git commit -m "feat(workout): create history after planned workout"
```

---

### 任务 7：数据页和历史页读取真实训练记录

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的数据和历史详情测试**

在 `test/widget_test.dart` 增加：

```dart
testWidgets('workout data and history use completed sessions',
    (tester) async {
  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('module_link_3')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_plan_card_plan_quick_10')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('开始训练'));
  await tester.pumpAndSettle();

  for (var i = 0; i < 3; i++) {
    await tester.tap(find.text('平板支撑').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('完成一组'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
  }

  await tester.tap(find.text('查看历史'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_history_entry_0')));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('workout_history_detail_sheet')), findsOneWidget);
  expect(find.text('再次训练同计划'), findsOneWidget);

  await tester.tap(find.text('再次训练同计划'));
  await tester.pumpAndSettle();
  expect(find.text('当前计划'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('workout_top_tab_2')));
  await tester.pumpAndSettle();
  expect(find.text('今日训练时长'), findsOneWidget);
  expect(find.text('最近 7 天训练'), findsOneWidget);
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout data and history use completed sessions"
```

预期：FAIL，历史详情或数据统计尚未接入真实历史。

- [ ] **步骤 3：添加统计对象**

在 `workout_module.dart` 中添加私有统计类：

```dart
class _WorkoutStats {
  const _WorkoutStats({
    required this.todayGroups,
    required this.todayMinutes,
    required this.todayCalories,
    required this.highestWeight,
    required this.weekSessions,
    required this.weekGroups,
  });

  final int todayGroups;
  final int todayMinutes;
  final int todayCalories;
  final String highestWeight;
  final int weekSessions;
  final int weekGroups;
}
```

添加计算函数，今日使用 `DateUtils.isSameDay(entry.finishedAt, DateTime.now())`，最近 7 天使用 `entry.finishedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))`。

- [ ] **步骤 4：改造数据页**

把 `_WorkoutDataView` 构造参数改为：

```dart
const _WorkoutDataView({
  required this.stats,
  required this.onOpenMetric,
});

final _WorkoutStats stats;
final ValueChanged<String> onOpenMetric;
```

卡片文案改为：

- `今日完成组数`
- `今日训练时长`
- `今日消耗 kcal`
- `今日最高重量`
- `最近 7 天训练`
- `最近 7 天组数`

点击卡片打开 `_WorkoutMetricSheet`，展示指标和相关记录。

- [ ] **步骤 5：改造历史页**

把 `_WorkoutHistoryView` 构造参数改为：

```dart
const _WorkoutHistoryView({
  required this.history,
  required this.onOpenHistory,
});

final List<WorkoutHistoryEntry> history;
final ValueChanged<WorkoutHistoryEntry> onOpenHistory;
```

历史条目使用 key：

```dart
ValueKey('workout_history_entry_$index')
```

空状态显示：

```dart
const _EmptyCard(
  title: '还没有训练记录',
  subtitle: '从计划开始训练，完成后会出现在这里。',
)
```

- [ ] **步骤 6：添加历史详情和再次训练**

添加 `_WorkoutHistoryDetailSheet`，根 key：

```dart
key: const ValueKey('workout_history_detail_sheet')
```

按钮 `再次训练同计划` 调用：

```dart
final plan = widget.workoutPlans.firstWhere(
  (plan) => plan.id == entry.planId,
  orElse: () => WorkoutPlan(
    id: entry.planId,
    name: entry.planName,
    target: '历史训练',
    bodyParts: entry.actionResults.map((result) => result.bodyPart).toSet().toList(),
    actionNames: entry.actionResults.map((result) => result.actionName).toList(),
    estimatedMinutes: entry.durationMinutes,
  ),
);
widget.onStartWorkoutPlan(plan);
setState(() => _selectedTopTab = 0);
```

- [ ] **步骤 7：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout data and history use completed sessions"
```

预期：PASS。

- [ ] **步骤 8：提交**

运行：

```powershell
dart format lib\modules\workout\workout_module.dart test\widget_test.dart
flutter analyze
git add lib\modules\workout\workout_module.dart test\widget_test.dart
git commit -m "feat(workout): show stats and history from sessions"
```

---

### 任务 8：计划详情轻量编辑

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的计划编辑测试**

在 `test/widget_test.dart` 增加：

```dart
testWidgets('workout plan editor removes action before starting',
    (tester) async {
  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('module_link_3')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('workout_plan_card_plan_chest_back')));
  await tester.pumpAndSettle();

  await tester.tap(find.text('编辑计划'));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('workout_plan_editor_sheet')), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('workout_plan_remove_蝴蝶机夹胸')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('开始训练'));
  await tester.pumpAndSettle();

  expect(find.text('蝴蝶机夹胸'), findsNothing);
  expect(find.text('宽握高位下拉'), findsWidgets);
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan editor removes action before starting"
```

预期：FAIL，找不到编辑弹层。

- [ ] **步骤 3：添加编辑弹层**

实现 `_WorkoutPlanEditorSheet`：

- 根 key：`workout_plan_editor_sheet`
- 每个已选动作显示移除按钮 key：`workout_plan_remove_$actionName`
- 未选动作显示添加按钮 key：`workout_plan_add_$actionName`
- 保存按钮文本：`保存`

保存时：

```dart
widget.onUpdateWorkoutPlan(
  plan.copyWith(
    actionNames: selectedActionNames,
    bodyParts: selectedActions.map((action) => action.bodyPart).toSet().toList(),
    estimatedMinutes: math.max(8, selectedActions.length * 7),
  ),
);
```

- [ ] **步骤 4：把编辑入口接到计划详情**

在 `_WorkoutPlanDetailSheet` 的 `编辑计划` 按钮中：

```dart
onPressed: onEdit,
```

`_openWorkoutPlanEditor(plan)` 打开编辑弹层，保存后关闭编辑层并刷新计划详情中的数据。

- [ ] **步骤 5：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan editor removes action before starting"
```

预期：PASS。

- [ ] **步骤 6：提交**

运行：

```powershell
dart format lib\modules\workout\workout_module.dart test\widget_test.dart
flutter analyze
git add lib\modules\workout\workout_module.dart test\widget_test.dart
git commit -m "feat(workout): edit plan actions"
```

---

### 任务 9：整体验证与回归

**文件：**
- 修改：无固定代码文件，按验证结果修复相关文件。
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：运行锻炼相关测试**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout top tabs show plan data and history"
flutter test test/widget_test.dart --plain-name "workout history shows calendar and progress trends"
flutter test test/widget_test.dart --plain-name "workout body part filters expose expanded exercise library"
flutter test test/widget_test.dart --plain-name "workout finished set updates list summary and data"
flutter test test/widget_test.dart --plain-name "workout feedback rest timer and food link are interactive"
flutter test test/widget_test.dart --plain-name "workout plan detail starts a planned workout"
flutter test test/widget_test.dart --plain-name "planned workout filters actions and records progress"
flutter test test/widget_test.dart --plain-name "completing planned workout creates history entry"
flutter test test/widget_test.dart --plain-name "workout data and history use completed sessions"
flutter test test/widget_test.dart --plain-name "workout plan editor removes action before starting"
```

预期：全部 PASS。

- [ ] **步骤 2：运行跨模块入口测试**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "module link strip jumps between every main module"
flutter test test/widget_test.dart --plain-name "food and workout records update health linked summary"
flutter test test/widget_test.dart --plain-name "finance workout and health bottom navs use compact capsules"
```

预期：全部 PASS。

- [ ] **步骤 3：运行静态检查**

运行：

```powershell
flutter analyze
```

预期：输出 `No issues found!`。

- [ ] **步骤 4：构建 APK 验证编译**

运行：

```powershell
flutter build apk --release
```

预期：exit 0，输出包含 `Built build\app\outputs\flutter-apk\app-release.apk`。

- [ ] **步骤 5：提交最终验证修复**

如果步骤 1 到步骤 4 过程中产生修复，运行：

```powershell
git add lib test
git commit -m "fix(workout): stabilize training system flow"
```

如果没有产生修复，跳过提交。

## 自检清单

- 规格目标“计划可点击并打开详情”由任务 4 覆盖。
- 规格目标“从计划详情开始训练”由任务 4 覆盖。
- 规格目标“计划训练模式只显示计划动作”由任务 5 覆盖。
- 规格目标“完成后生成历史记录”由任务 6 覆盖。
- 规格目标“数据页基于训练记录统计”由任务 7 覆盖。
- 规格目标“历史详情和再次训练”由任务 7 覆盖。
- 规格目标“轻量编辑计划”由任务 8 覆盖。
- 规格目标“本地持久化”由任务 2 覆盖。
- 回归验证由任务 9 覆盖。
