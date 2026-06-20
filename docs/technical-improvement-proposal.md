# 平生 Life App 技术改进方案

> 版本：v1.0
> 日期：2026-06-19
> 范围：架构重构、数据层加固、代码质量修复、功能补全

---

## 目录

1. [现状评估](#1-现状评估)
2. [改进项详述](#2-改进项详述)
3. [实施路线图](#3-实施路线图)
4. [风险评估](#4-风险评估)
5. [附录](#5-附录)

---

## 1. 现状评估

### 1.1 架构现状

当前项目采用「单文件 + `part` 指令」的组织方式，`main.dart` 通过 `part` 引入所有子模块，导致：

- 整个 App 实际上编译为一个编译单元，无封装性
- 任何文件的修改都可能触发全量重建
- IDE 的「查找引用」「安全重构」能力失效

状态管理采用「父子 Widget 传参」模式，`_LifeHomePageState` 持有几乎所有业务数据，通过构造函数逐层下传（prop drilling），涉及 10+ 个参数。

### 1.2 数据层现状

`SQLite` 存储通过 `_AppDataStore` 实现，但 save 策略为**删除全表再逐条插入**，存在：

- 崩溃/断电时数据全丢的风险
- I/O 开销随数据量线性增长
- 无事务保护

### 1.3 代码质量现状

- 存在拼写错误（`didUpdateWidget` → `idUpdateWidget`，`bottom` → `bottom`）
- 无单元测试覆盖业务逻辑
- `analysis_options.yaml` 规则较松，未开启常用 lint

---

## 2. 改进项详述

### P0 — 紧急修复（影响功能正确性）

#### 2.1 修复 `didUpdateWidget` 拼写错误

**文件**: `lib/modules/plan/plan_module.dart`（两处）

**现状**:
```dart
// ❌ 错误 — 框架不会调用这个方法
@override
void idUpdateWidget(covariant PlanModulePage oldWidget) {
  super.idUpdateWidget(oldWidget);  // 同样拼错
  _maybeHandleQuickAction();
}
```

**修复**:
```dart
// ✅ 正确
@override
void didUpdateWidget(covariant PlanModulePage oldWidget) {
  super.didUpdateWidget(oldWidget);
  _maybeHandleQuickAction();
}
```

**影响**: 此 bug 导致 Flutter 框架在 Widget 配置更新时不会调用该方法，快捷动作（quickAction）在路由返回、模块切换等场景下可能无法触发。

**验证方式**: 在计划页面触发 quickAction，观察是否正常响应；搜索全项目确认无同类拼写错误。

---

#### 2.2 修复 `EdgeInsets.only(bottom` 拼写错误

**文件**: `lib/home/life_home_page.dart` 第 735 行、`lib/modules/plan/plan_module.dart` 多处

**现状**:
```dart
padding: const EdgeInsets.only(bottom: 10),  // ❌ bottom 拼成 bottom
```

**修复**: 全局搜索 `bottom` 并替换为 `bottom`（注意仅替换 `EdgeInsets` 上下文中的错误拼写）。

**注意**: 若此为 AI 渲染 artifact 而非真实代码，需在本地确认。

---

### P1 — 架构重构（影响长期可维护性）

#### 2.3 废除 `part` 指令，改为正常 `import`

**背景**: 所有模块文件均使用 `part of '../main.dart'`，这是 Dart 的「库拆分」机制，适用于极小的工具类库，不适用于 Flutter App。

**目标结构**:
```
lib/
  main.dart                  → 仅保留 runApp()、MyApp、路由入口
  life_home_page.dart        → 独立文件，import 各模块
  modules/
    plan/plan_module.dart    → 独立文件，export PlanModulePage
    plan/widgets/           → 拆分 _PlanHeader、_PlanBottomNav 等内部 Widget
    finance/finance_module.dart
    food/food_module.dart
    workout/workout_module.dart
    health/health_module.dart
  shared/                   → 跨模块共享组件
  models/                   → 数据模型（已独立，保持）
  storage/                  → 存储层（已独立，保持）
  api/                      → API 客户端（已独立，保持）
```

**实施步骤**:

1. 将 `part of '../main.dart'` 改为 `import 'package:pingsheng_life/...'`
2. 将各文件中的私有 Widget（`_PlanHeader` 等）改为 public（去掉下划线），或拆分到独立文件后保留 private
3. `main.dart` 中删除所有 `part '...'` 指令
4. 更新 `pubspec.yaml` 确保 `flutter:` 下无多余声明

**风险提示**: 改完后需全量测试，因 `part` 文件中的私有符号对 `main.dart` 可见，改为 `import` 后将不可见，需相应调整访问级别。

---

#### 2.4 引入 Riverpod 状态管理

**选型理由**:
- Riverpod 2.x 与 Flutter 3.x 完全兼容，无 `BuildContext` 依赖
- 编译期安全检查（provider 未声明则编译失败）
- 支持 `AsyncValue`，天然适合异步状态（API、数据库）
- 与 `part` 拆除后的模块化结构天然契合

**重构目标**: 将 `_LifeHomePageState` 中持有的数据改为 Provider 管理：

```dart
// 重构前：prop drilling
PlanModulePage(
  todos: _todos,
  onToggleTodo: _toggleTodo,
  onAddTodo: _addTodo,
  // ...10+ 个回调
)

// 重构后：各模块自行消费 Provider
class PlanModulePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    return ...;
  }
}
```

**Provider 划分建议**:

| Provider | 类型 | 作用域 |
|----------|------|--------|
| `todoListProvider` | `StateNotifierProvider` | 全局 |
| `financeRecordsProvider` | `StateNotifierProvider` | 全局 |
| `foodCaloriesProvider` | `StateProvider` | 全局 |
| `workoutGroupsProvider` | `StateProvider` | 全局 |
| `lifeEventsProvider` | `StateNotifierProvider` | 全局 |
| `selectedModuleProvider` | `StateProvider<LifeModule>` | 全局 |

**实施步骤**:

1. 添加依赖：`flutter_riverpod: ^2.5.0`（锁定到最新稳定版）
2. 将 `MyApp` 包裹在 `ProviderScope` 中
3. 先从一个模块（建议「计划」）开始迁移，验证无误后再迁移其余模块
4. 迁移完成后删除 `_LifeHomePageState` 中的 prop drilling 回调

---

#### 2.5 拆分超大文件

**目标文件及建议拆分方式**:

**`plan_module.dart`（当前 ~2200 行）**:

```
lib/modules/plan/
  plan_module.dart          → PlanModulePage + _PlanModulePageState（主页面）
  plan_widgets.dart        → _PlanHeader、_PlanBottomNav、_TabView 等
  plan_todo_sheet.dart     → 待办新增/编辑 Sheet
  plan_todo_card.dart      → TodoItem 展示 Card
  plan_inbox_view.dart     → _InboxView
  plan_week_view.dart      → _WeekPlanView
  plan_review_sheet.dart   → 复盘 Sheet
```

**`life_home_page.dart`（当前 ~950 行）**:

```
lib/
  life_home_page.dart      → LifeHomePage + _LifeHomePageState（保留核心逻辑）
  widgets/module_sheet.dart → _ModuleSheet
  widgets/quick_record_sheet.dart → _QuickRecordSheet、_QuickRecordTile
  widgets/todo_linked_sheet.dart → _TodoLinkedActionSheet
  widgets/life_event.dart  → LifeEvent、_LifeEventCard
```

**拆分原则**:
- 单个文件不超过 500 行（自动生成代码除外）
- 每个文件只导出 1 个主要 Widget，相关私有 Widget 可共存
- Sheet（底部弹层）优先拆到独立文件

---

### P2 — 数据层加固

#### 2.6 修复 SQLite save 策略（删除全表问题）

**现状分析**（`lib/storage/app_data_store.dart` 第 196-261 行）:

```dart
// ❌ 当前逻辑：删除全表 → 逐条插入
Future<void> _saveNow() async {
  final db = await _db;
  final snapshot = _snapshot;
  await db.transaction((txn) async {
    // 每次都删除全表！
    await txn.delete(_todoTableName);
    for (final todo in snapshot.todos) {
      await txn.insert(_todoTableName, todo.toJson());
    }
    // 同理处理 financeRecords、foodCalories 等
  });
}
```

**问题**:
1. 事务提交前崩溃 → 数据全丢（表已清空，新数据未写入）
2. 数据量大时 I/O 开销高
3. 无增量更新能力

**改进方案 — 增量 upsert**:

```dart
// ✅ 改进后：基于 id 的 upsert
Future<void> _saveNow() async {
  final db = await _db;
  final snapshot = _snapshot;
  await db.transaction((txn) async {
    // 1. 构建当前数据 id 集合
    final currentIds = snapshot.todos.map((t) => t.id).toSet();
    
    // 2. 删除数据库中不存在于当前集合的记录
    if (currentIds.isNotEmpty) {
      await txn.delete(
        _todoTableName,
        where: 'id NOT IN (${currentIds.map((_) => '?').join(',')})',
        whereArgs: currentIds.toList(),
      );
    } else {
      await txn.delete(_todoTableName);
    }
    
    // 3. upsert 当前数据（INSERT OR REPLACE）
    for (final todo in snapshot.todos) {
      await txn.insert(
        _todoTableName,
        todo.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  });
}
```

**更进一步的方案 — 操作日志（推荐长期采用）**:

引入 `_pendingOperations` 表，记录每次增删改操作，save 时只刷盘操作日志，启动时重放。这样即使崩溃也只丢失最后一次操作，不会丢失全部数据。

```sql
CREATE TABLE _pending_operations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL,  -- 'insert' | 'update' | 'delete'
  payload TEXT,             -- JSON，仅 insert/update 时有值
  created_at INTEGER NOT NULL
);
```

---

#### 2.7 补全 Repository 层

**目标**: 在 UI 和 `_AppDataStore` 之间插入 Repository 层，隔离存储实现细节。

```dart
// 抽象接口
abstract class TodoRepository {
  Future<List<TodoItem>> getAll();
  Future<void> save(TodoItem todo);
  Future<void> delete(String id);
  Stream<List<TodoItem>> watchAll();  // 响应式
}

// SQLite 实现
class SqliteTodoRepository implements TodoRepository {
  final _AppDataStore _store;
  // ...
}

// 后续可加：IsarTodoRepository、DriftTodoRepository
```

Riverpod 迁移后，Repository 以 `Provider` 形式注入，切换存储实现只需改 Provider 定义。

---

#### 2.8 `FinanceRecord` icon 持久化

**现状**: `FinanceRecord.fromJson` 通过 `_financeIconForTitle(title)` 推断 icon，标题变更后 icon 丢失。

**修复**:

```dart
// models/finance_record.dart
class FinanceRecord {
  final int iconCodePoint;  // 新增字段

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() => {
    ...,
    'iconCodePoint': iconCodePoint,  // 持久化
  };

  factory FinanceRecord.fromJson(Map<String, dynamic> json) {
    return FinanceRecord(
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      ...,
    );
  }
}
```

需同步迁移数据库中已有记录的 schema（新增 `iconCodePoint` 列，默认值通过 `_financeIconForTitle` 回填）。

---

### P3 — 功能补全

#### 2.9 数据导出 / 备份

**方案**: JSON 文件导出 + 导入

```dart
// 导出
Future<File> exportData() async {
  final data = {
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'todos': _todos.map((t) => t.toJson()).toList(),
    'financeRecords': _financeRecords.map((r) => r.toJson()).toList(),
    'foodCalories': _recordedFoodCalories,
    'workoutGroups': _workoutGroupsByAction,
  };
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/pingsheng_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.json');
  await file.writeAsString(jsonEncode(data));
  return file;
}

// 导入（带冲突解决 UI）
Future<void> importData(File file) async {
  final data = jsonDecode(await file.readAsString());
  // 展示预览，让用户选择「合并」或「覆盖」
}
```

**建议入口**: 设置页面 → 「数据管理」→ 导出 / 导入

---

#### 2.10 AI 记账配置持久化

**现状**: `_aiEndpoint` 和 `_aiModel` 硬编码在 `FinanceModulePage` 的 State 中，重进页面即丢失。

**修复**: 存入 `SharedPreferences`：

```dart
const _kAiEndpointKey = 'ai_endpoint';
const _kAiModelKey = 'ai_model';

Future<void> _loadAiConfig() async {
  final prefs = await SharedPreferences.getInstance();
  _aiEndpoint = prefs.getString(_kAiEndpointKey) ?? _defaultEndpoint;
  _aiModel = prefs.getString(_kAiModelKey) ?? _defaultModel;
}

Future<void> _saveAiConfig() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kAiEndpointKey, _aiEndpoint);
  await prefs.setString(_kAiModelKey, _aiModel);
}
```

---

#### 2.11 健康模块数据持久化

**现状**: Health Connect 读取的数据展示在 `HealthModulePage`，但未写入 SQLite，冷启动后丢失。

**修复**: 在 `_HealthDataStore` 中增加 save/load 方法，每次从 Health Connect 读取后写入本地数据库，启动时先读本地缓存再异步刷新。

---

#### 2.12 重复任务自动生成

**现状**: `TodoRepeatRule` 定义了 `daily/weekly/monthly`，但无自动生成逻辑。

**方案**: 在 App 启动时（或每日首次打开时）检查并生成：

```dart
Future<void> _generateRepeatedTodos() async {
  final prefs = await SharedPreferences.getInstance();
  final lastGenerateDate = prefs.getString('_lastRepeatGenerateDate');
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  if (lastGenerateDate == today) return;  // 今天已生成过
  
  final todos = await todoRepository.getAll();
  for (final todo in todos.where((t) => t.repeatRule != null && t.done)) {
    // 已完成且有重复规则的待办，生成下一条
    final newDueDate = _nextDate(todo.dueDate!, todo.repeatRule!);
    final newTodo = TodoItem(
      title: todo.title,
      category: todo.category,
      priority: todo.priority,
      dueDate: newDueDate,
      repeatRule: todo.repeatRule,
      linkedModules: todo.linkedModules,
    );
    await todoRepository.save(newTodo);
  }
  
  await prefs.setString('_lastRepeatGenerateDate', today);
}
```

---

### P4 — 开发体验提升

#### 2.13 升级 Lint 规则

**当前**: `analysis_options.yaml` 使用 `flutter_lints`
**建议**: 升级到 `very_good_analysis` 或自定义严格规则

```yaml
# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml

linter:
  rules:
    - avoid_print
    - prefer_const_constructors
    - unnecessary_stateful_widget
    - unawaited_futures
    - deprecated_member_use_from_same_package
```

---

#### 2.14 补充单元测试

**优先级最高的测试场景**:

```
test/
  models/
    todo_item_test.dart         → 状态转移、repeatRule、dueDate 逻辑
    finance_record_test.dart    → fromJson/toJson、icon 持久化
  storage/
    app_data_store_test.dart    → save/load、增量更新、崩溃恢复
  modules/
    plan/
      quick_action_test.dart    → 路由解析、quickAction 触发
    finance/
      ai_booking_test.dart     → AI 记账解析逻辑
```

**测试工具建议**:
- `mocktail` — mock API、数据库
- `fake_async` — 测试时间相关逻辑（repeatRule）
- `flutter_test` — Widget 测试（快捷动作、Sheet 交互）

---

## 3. 实施路线图

### Phase 1 — 紧急修复（1-2 天）

| 任务 | 预计工作量 | 风险 |
|------|-----------|------|
| 修复 `didUpdateWidget` 拼写 | 0.5h | 低 |
| 修复 `bottom` 拼写 + 全局搜索同类问题 | 0.5h | 低 |
| 验证 quickAction 功能恢复正常 | 1h | 低 |

### Phase 2 — 架构重构（1-2 周）

| 任务 | 预计工作量 | 风险 |
|------|-----------|------|
| 废除 `part`，改为 `import` | 2-3 天 | 中（需处理访问级别） |
| 引入 Riverpod，迁移「计划」模块 | 2-3 天 | 中（学习成本） |
| 迁移其余 4 个模块 | 2-3 天 | 低 |
| 拆分 `plan_module.dart` 大文件 | 1-2 天 | 低 |

### Phase 3 — 数据层加固（3-5 天）

| 任务 | 预计工作量 | 风险 |
|------|-----------|------|
| 修复 SQLite save 策略（增量 upsert） | 1-2 天 | 中（需数据迁移） |
| 补全 Repository 层 | 1-2 天 | 低 |
| `FinanceRecord` icon 持久化 | 0.5 天 | 低（需数据库迁移） |

### Phase 4 — 功能补全（1-2 周，可并行）

| 任务 | 预计工作量 | 风险 |
|------|-----------|------|
| 数据导出/导入 | 2-3 天 | 低 |
| AI 记账配置持久化 | 0.5 天 | 低 |
| 健康模块数据持久化 | 1-2 天 | 中（Health Connect API 变更） |
| 重复任务自动生成 | 1-2 天 | 低 |
| 补充单元测试 | 3-5 天 | 低 |

---

## 4. 风险评估

| 风险 | 等级 | 应对措施 |
|------|------|---------|
| `part` → `import` 重构引入访问级别问题 | 中 | 先在一个模块试点，确认无误后推广 |
| SQLite save 策略修改导致数据丢失 | 高 | 先备份数据库，增量更新逻辑加充足测试 |
| Riverpod 学习成本导致进度延迟 | 低 | 先迁移一个模块作为试点 |
| Health Connect API 变更 | 中 | 封装接口层，隔离第三方 API 变更 |
| 数据库 schema 迁移失败 | 中 | 写迁移测试，覆盖空数据库和旧版本升级场景 |

---

## 5. 附录

### 5.1 相关文件索引

| 改进项 | 主要涉及文件 |
|--------|-------------|
| 2.1 `didUpdateWidget` 拼写 | `lib/modules/plan/plan_module.dart` |
| 2.2 `bottom` 拼写 | `lib/home/life_home_page.dart`、`lib/modules/plan/plan_module.dart` |
| 2.3 废除 `part` | 几乎所有 `lib/` 下的 Dart 文件 |
| 2.4 Riverpod 引入 | `pubspec.yaml`、`lib/main.dart`、各模块 Page |
| 2.6 SQLite save 策略 | `lib/storage/app_data_store.dart` |
| 2.8 FinanceRecord icon | `lib/models/life_data.dart` |

### 5.2 推荐阅读

- [Riverpod 官方文档](https://riverpod.dev/docs)
- [Flutter 官方：State Management](https://docs.flutter.dev/data-and-backend/state-mgmt)
- [Drift 数据库（可选替代 raw sqlite）](https://drift.simonbinder.eu/)
- [very_good_analysis](https://pub.dev/packages/very_good_analysis)

---

*文档结束*
