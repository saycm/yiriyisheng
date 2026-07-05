# 架构整理第一阶段实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 在不改变用户可见行为的前提下，拆分计划周视图和本地存储大文件，让小组件交互和 UI 一致性优化更稳。

**架构：** 保持现有 `part` 组织和对外接口，先按职责拆内部文件。计划周视图拆成入口、动作、反馈和面板组件；本地存储保持 `LifeSummaryStore` 不变，把 row mapper 和表 helper 从 `AppDataStore` 中分离。

**技术栈：** Flutter / Dart `part` library、sqflite、Flutter widget tests、Go 服务端测试、Python 小组件静态检查脚本。

---

## 文件结构

### 创建文件

- `lib/modules/plan/widgets/week/week_plan_view.dart`：周视图入口，负责计算周日期、分组数据并组装子组件。
- `lib/modules/plan/widgets/week/week_plan_actions.dart`：周视图排程动作，包括自动排周、平衡本周、移到下周、清理过期、安排待办。
- `lib/modules/plan/widgets/week/week_feedback.dart`：周视图浮层反馈、撤销反馈和 fallback snack bar。
- `lib/modules/plan/widgets/week/week_command_center.dart`：一周安排工作台、统计指标和命令按钮。
- `lib/modules/plan/widgets/week/week_day_board.dart`：7 天任务看板、日期卡和负载标识。
- `lib/modules/plan/widgets/week/week_backlog_section.dart`：未安排/过期待整理任务区。
- `lib/modules/plan/widgets/week/week_selected_tasks_panel.dart`：选中日期任务面板和空状态。
- `lib/storage/app_data_rows.dart`：SQLite row 与模型之间的转换，包括 `AppDataStoreRows` 和 `AppDataStore` 的私有 row mapper extension。
- `lib/storage/app_data_tables.dart`：SQLite 建表、升级、meta 读写、upsert/delete helper。

### 修改文件

- `lib/modules/plan/plan.dart`：将 `part 'widgets/week_plan_view.dart';` 替换为新的 `widgets/week/*.dart` part 列表。
- `lib/modules/plan/widgets/week_plan_view.dart`：删除，内容移动到 `widgets/week/` 下的多个文件。
- `lib/storage/storage.dart`：加入 `part 'app_data_rows.dart';` 和 `part 'app_data_tables.dart';`。
- `lib/storage/app_data_store.dart`：保留 `LifeSummaryStore`、`AppDataStore` 保存队列和事务编排，移出 row mapper 与表 helper。
- `test/source_structure_test.dart`：新增结构护栏测试，验证新文件存在且入口文件行数下降。

### 测试文件

- `test/source_structure_test.dart`
- `test/plan_widget_test.dart`
- `test/storage_app_data_store_test.dart`
- `test/widget_test.dart`

---

## 任务 1：添加结构护栏测试

**文件：**
- 修改：`test/source_structure_test.dart`

- [ ] **步骤 1：编写失败的结构测试**

在 `test/source_structure_test.dart` 的 `main()` 内追加两个测试：

```dart
  test('week plan is split into focused part files', () {
    final plan = File('lib/modules/plan/plan.dart').readAsStringSync();
    final weekFiles = [
      'lib/modules/plan/widgets/week/week_plan_view.dart',
      'lib/modules/plan/widgets/week/week_plan_actions.dart',
      'lib/modules/plan/widgets/week/week_feedback.dart',
      'lib/modules/plan/widgets/week/week_command_center.dart',
      'lib/modules/plan/widgets/week/week_day_board.dart',
      'lib/modules/plan/widgets/week/week_backlog_section.dart',
      'lib/modules/plan/widgets/week/week_selected_tasks_panel.dart',
    ];

    for (final path in weekFiles) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(
        File(path).readAsStringSync(),
        contains("part of '../../plan.dart';"),
        reason: path,
      );
    }

    expect(plan, isNot(contains("part 'widgets/week_plan_view.dart';")));
    expect(
      plan,
      contains("part 'widgets/week/week_plan_view.dart';"),
    );
    expect(_lineCount('lib/modules/plan/widgets/week/week_plan_view.dart'),
        lessThan(260));
  });

  test('app data store is split into rows and table helpers', () {
    final storage = File('lib/storage/storage.dart').readAsStringSync();
    final rows = File('lib/storage/app_data_rows.dart');
    final tables = File('lib/storage/app_data_tables.dart');
    final store = File('lib/storage/app_data_store.dart');

    expect(rows.existsSync(), isTrue);
    expect(tables.existsSync(), isTrue);
    expect(rows.readAsStringSync(), contains("part of 'storage.dart';"));
    expect(tables.readAsStringSync(), contains("part of 'storage.dart';"));
    expect(storage, contains("part 'app_data_rows.dart';"));
    expect(storage, contains("part 'app_data_tables.dart';"));
    expect(_lineCount(store.path), lessThan(420));
  });
```

- [ ] **步骤 2：运行结构测试验证失败**

运行：

```powershell
flutter test test/source_structure_test.dart
```

预期：新增两个测试失败，失败原因是新文件不存在、旧 `part 'widgets/week_plan_view.dart';` 仍存在，或 `app_data_rows.dart` / `app_data_tables.dart` 尚不存在。

- [ ] **步骤 3：Commit 红灯测试**

```powershell
git add test/source_structure_test.dart
git commit -m "test: add architecture split guards"
```

---

## 任务 2：拆分计划周视图入口和动作

**文件：**
- 创建：`lib/modules/plan/widgets/week/week_plan_view.dart`
- 创建：`lib/modules/plan/widgets/week/week_plan_actions.dart`
- 修改：`lib/modules/plan/plan.dart`
- 删除：`lib/modules/plan/widgets/week_plan_view.dart`
- 测试：`test/source_structure_test.dart`
- 测试：`test/plan_widget_test.dart`

- [ ] **步骤 1：更新 part 列表**

把 `lib/modules/plan/plan.dart` 末尾的：

```dart
part 'widgets/week_plan_view.dart';
```

替换为：

```dart
part 'widgets/week/week_plan_view.dart';
part 'widgets/week/week_plan_actions.dart';
part 'widgets/week/week_feedback.dart';
part 'widgets/week/week_command_center.dart';
part 'widgets/week/week_day_board.dart';
part 'widgets/week/week_backlog_section.dart';
part 'widgets/week/week_selected_tasks_panel.dart';
```

- [ ] **步骤 2：创建周视图入口文件**

创建 `lib/modules/plan/widgets/week/week_plan_view.dart`，文件头使用：

```dart
// 中文注释：计划周视图入口，负责周日期计算、任务分组和子面板组装。

part of '../../plan.dart';
```

将旧 `week_plan_view.dart` 中以下内容移动进新入口文件：

- `const int _maxScheduleToSelectedDay = 6;`
- `class _WeekPlanView extends StatelessWidget`
- `_weekTodos`
- `_unscheduledTodos`
- `_completedInWeek`
- `_weekInsight`

入口文件中的 `_WeekPlanView.build()` 保持原 UI 组装顺序，不改 key、文字或回调。

- [ ] **步骤 3：创建周视图动作文件**

创建 `lib/modules/plan/widgets/week/week_plan_actions.dart`，文件头使用：

```dart
// 中文注释：计划周视图动作，负责自动排周、均衡、清理和安排任务。

part of '../../plan.dart';
```

将旧文件中的以下 `_WeekPlanView` 实例方法移动到 `extension _WeekPlanActions on _WeekPlanView`，函数签名和实现保持当前行为：

- `_autoScheduleWeek(BuildContext context, DateTime today, List<DateTime> days, List<TodoItem> unscheduledTodos)`
- `_balanceWeek(BuildContext context, DateTime today, List<DateTime> days)`
- `_moveLowPriorityToNextWeek(BuildContext context, List<DateTime> days)`
- `_cleanOverdueTodos(BuildContext context, DateTime today, List<DateTime> days)`
- `_scheduleTodo(BuildContext context, TodoItem todo, DateTime targetDay)`
- `_scheduleBacklogToSelectedDay(BuildContext context, List<TodoItem> backlogTodos, DateTime selectedDate)`
- `_scheduleAllBacklogToSelectedDay(BuildContext context, List<TodoItem> backlogTodos, DateTime selectedDate)`

同一文件保留纯 helper `_scheduledCopy` 和 `_bestScheduleDay`。移动完成后用 `rg -n "_autoScheduleWeek|_bestScheduleDay" lib/modules/plan/widgets/week` 确认这些符号只出现在新目录中。

- [ ] **步骤 4：运行格式化和目标测试**

```powershell
dart format lib/modules/plan/plan.dart lib/modules/plan/widgets/week test/source_structure_test.dart
flutter test test/source_structure_test.dart
flutter test test/plan_widget_test.dart
```

预期：结构测试仍可能因为其他 week 子文件未创建而失败；`plan_widget_test.dart` 必须通过。若 `plan_widget_test.dart` 失败，先修移动遗漏，再继续。

- [ ] **步骤 5：Commit 周视图入口和动作拆分**

```powershell
git add lib/modules/plan/plan.dart lib/modules/plan/widgets/week lib/modules/plan/widgets/week_plan_view.dart
git commit -m "refactor: split week plan entry and actions"
```

---

## 任务 3：拆分周视图反馈和 UI 面板

**文件：**
- 创建：`lib/modules/plan/widgets/week/week_feedback.dart`
- 创建：`lib/modules/plan/widgets/week/week_command_center.dart`
- 创建：`lib/modules/plan/widgets/week/week_day_board.dart`
- 创建：`lib/modules/plan/widgets/week/week_backlog_section.dart`
- 创建：`lib/modules/plan/widgets/week/week_selected_tasks_panel.dart`
- 修改：`lib/modules/plan/widgets/week/week_plan_view.dart`
- 修改：`lib/modules/plan/widgets/week/week_plan_actions.dart`
- 测试：`test/source_structure_test.dart`
- 测试：`test/plan_widget_test.dart`

- [ ] **步骤 1：创建反馈文件**

创建 `lib/modules/plan/widgets/week/week_feedback.dart`：

```dart
// 中文注释：计划周视图反馈，负责底部浮层、撤销按钮和 snack bar 兜底。

part of '../../plan.dart';

OverlayEntry? _weekPlanFeedbackEntry;
```

将旧文件中的以下内容移动到这里：

- `_showUndoableScheduleSnackBar`
- `_showPlainWeekSnackBar`
- `_showWeekPlanFeedback`
- `_showFallbackWeekSnackBar`
- `class _WeekPlanFeedbackToast`
- `class _WeekPlanFeedbackToastState`

如果这些函数原来是 `_WeekPlanView` 实例方法，放入 `extension _WeekPlanFeedbackActions on _WeekPlanView`。移动完成后运行 `rg -n "_showUndoableScheduleSnackBar|_WeekPlanFeedbackToast" lib/modules/plan/widgets/week`，确认反馈符号只位于 `week_feedback.dart`。

- [ ] **步骤 2：创建命令中心文件**

创建 `lib/modules/plan/widgets/week/week_command_center.dart`：

```dart
// 中文注释：计划周视图命令中心，负责一周统计、洞察和快捷排程按钮。

part of '../../plan.dart';
```

移动以下类：

- `_WeekCommandCenter`
- `_WeekCommandButton`
- `_WeekMetricTile`

- [ ] **步骤 3：创建 7 天看板文件**

创建 `lib/modules/plan/widgets/week/week_day_board.dart`：

```dart
// 中文注释：计划周视图 7 天看板，负责日期卡、负载标签和每日任务摘要。

part of '../../plan.dart';
```

移动以下内容：

- `_WeekDayBoard`
- `_WeekDayCard`
- `_loadInfo`
- `_dayTodos`
- `_weekCardDecoration`

- [ ] **步骤 4：创建待安排任务区文件**

创建 `lib/modules/plan/widgets/week/week_backlog_section.dart`：

```dart
// 中文注释：计划周视图待安排区，负责无日期、过期和延期待整理任务。

part of '../../plan.dart';
```

移动以下类：

- `_WeekUnscheduledSection`

- [ ] **步骤 5：创建选中日期面板文件**

创建 `lib/modules/plan/widgets/week/week_selected_tasks_panel.dart`：

```dart
// 中文注释：计划周视图选中日期面板，负责展示当天任务和批量排入入口。

part of '../../plan.dart';
```

移动以下类：

- `_WeekSelectedTasksPanel`
- `_WeekEmptyHint`

- [ ] **步骤 6：删除旧文件并运行目标测试**

删除 `lib/modules/plan/widgets/week_plan_view.dart`，运行：

```powershell
dart format lib/modules/plan/plan.dart lib/modules/plan/widgets/week
flutter test test/source_structure_test.dart
flutter test test/plan_widget_test.dart
```

预期：`test/source_structure_test.dart` 中周视图拆分测试通过；`test/plan_widget_test.dart` 全部通过。

- [ ] **步骤 7：Commit 周视图 UI 面板拆分**

```powershell
git add lib/modules/plan/plan.dart lib/modules/plan/widgets/week lib/modules/plan/widgets/week_plan_view.dart test/source_structure_test.dart
git commit -m "refactor: split week plan panels"
```

---

## 任务 4：拆分本地存储 row mapper

**文件：**
- 创建：`lib/storage/app_data_rows.dart`
- 修改：`lib/storage/storage.dart`
- 修改：`lib/storage/app_data_store.dart`
- 测试：`test/source_structure_test.dart`
- 测试：`test/storage_app_data_store_test.dart`

- [ ] **步骤 1：更新 storage part 列表**

把 `lib/storage/storage.dart` 的 part 列表改成：

```dart
part 'app_data_rows.dart';
part 'app_data_store.dart';
part 'app_data_tables.dart';
part 'widget_store.dart';
```

- [ ] **步骤 2：创建 row mapper 文件**

创建 `lib/storage/app_data_rows.dart`：

```dart
// 中文注释：App 数据行映射，负责 SQLite row 与业务模型之间的转换。

part of 'storage.dart';
```

从 `app_data_store.dart` 移动：

- `class AppDataStoreRows`
- `_todoFromRow`
- `_financeRecordFromRow`
- `_workoutPlanFromRow`
- `_activeWorkoutSessionFromRow`
- `_workoutHistoryFromRow`
- `_decodeJsonList`
- `_decodeJsonMap`
- `_decodeJson`

实例方法使用 `extension _AppDataStoreRowMapping on AppDataStore` 承接，移动这些方法并保持签名：

- `_todoFromRow(Map<String, Object?> row)`
- `_financeRecordFromRow(Map<String, Object?> row)`
- `_workoutPlanFromRow(Map<String, Object?> row)`
- `_activeWorkoutSessionFromRow(Map<String, Object?> row)`
- `_workoutHistoryFromRow(Map<String, Object?> row)`
- `_decodeJsonList(Object? source)`
- `_decodeJsonMap(Object? source)`
- `_decodeJson(Object? source)`

移动完成后运行 `rg -n "class AppDataStoreRows|_todoFromRow|_decodeJson" lib/storage`，确认 `class AppDataStoreRows` 和 row mapper 方法位于 `app_data_rows.dart`。

- [ ] **步骤 3：运行 row mapper 测试**

```powershell
dart format lib/storage test/source_structure_test.dart test/storage_app_data_store_test.dart
flutter test test/storage_app_data_store_test.dart
```

预期：`storage rows preserve finance account tags and date` 通过，保存失败测试通过。

- [ ] **步骤 4：Commit row mapper 拆分**

```powershell
git add lib/storage/storage.dart lib/storage/app_data_store.dart lib/storage/app_data_rows.dart test/source_structure_test.dart
git commit -m "refactor: split app data row mapping"
```

---

## 任务 5：拆分本地存储表 helper

**文件：**
- 创建：`lib/storage/app_data_tables.dart`
- 修改：`lib/storage/app_data_store.dart`
- 修改：`lib/storage/storage.dart`
- 测试：`test/source_structure_test.dart`
- 测试：`test/storage_app_data_store_test.dart`

- [ ] **步骤 1：创建表 helper 文件**

创建 `lib/storage/app_data_tables.dart`：

```dart
// 中文注释：App 数据表 helper，负责 SQLite 建表、升级、meta 和通用 upsert。

part of 'storage.dart';
```

从 `app_data_store.dart` 移动以下方法到 `extension _AppDataStoreTables on AppDataStore`，保持签名和行为：

- `_saveMeta(Transaction txn, Map<String, String> values)`
- `_upsertByTextKey(Transaction txn, String table, String keyColumn, String key, Map<String, Object?> row)`
- `_upsertByPosition(Transaction txn, String table, int position, Map<String, Object?> row)`
- `_deleteMissingTextKeys(Transaction txn, String table, String keyColumn, List<String> keys)`
- `_open()`
- `_createWorkoutTrainingTables(DatabaseExecutor db)`
- `_addColumnIfMissing(Database db, String table, String columnDefinition)`
- `_readIntMeta(Database db, String key)`
- `_readStringMeta(Database db, String key, String fallback)`
- `_readAiFinanceParseStrategy(Database db)`

移动完成后运行 `rg -n "_saveMeta|_open\\(|_readAiFinanceParseStrategy" lib/storage`，确认这些表 helper 位于 `app_data_tables.dart`。

- [ ] **步骤 2：保留 AppDataStore 核心职责**

确认 `lib/storage/app_data_store.dart` 只保留：

- `abstract class LifeSummaryStore`
- `class AppDataStore implements LifeSummaryStore`
- `_databaseName`
- `_databaseVersion`
- `_pendingSave`
- `load`
- `save`
- `_saveNow`
- `_isSupportedPlatform`

- [ ] **步骤 3：运行结构和存储测试**

```powershell
dart format lib/storage test/source_structure_test.dart
flutter test test/source_structure_test.dart
flutter test test/storage_app_data_store_test.dart
```

预期：结构测试中 `app data store is split into rows and table helpers` 通过；存储测试通过。

- [ ] **步骤 4：Commit 表 helper 拆分**

```powershell
git add lib/storage/storage.dart lib/storage/app_data_store.dart lib/storage/app_data_tables.dart test/source_structure_test.dart
git commit -m "refactor: split app data table helpers"
```

---

## 任务 6：完整验证和收尾

**文件：**
- 修改：`README.md`，仅当文件结构说明需要同步时修改。
- 检查：所有任务改过的 Dart 文件。

- [ ] **步骤 1：运行格式化**

```powershell
dart format lib test tools
```

预期：命令 exit 0。

- [ ] **步骤 2：运行完整 Flutter 静态分析**

```powershell
flutter analyze
```

预期：`No issues found!`

- [ ] **步骤 3：运行完整 Flutter 测试**

```powershell
flutter test
```

预期：所有测试通过，输出结尾包含 `All tests passed!`。

- [ ] **步骤 4：运行 Go 服务端测试**

```powershell
go test ./...
```

工作目录：`server`

预期：`ok   pingsheng-life-server`

- [ ] **步骤 5：运行小组件结构检查**

```powershell
python tools\check_widget_redesign.py
```

预期：`Widget redesign structure check passed.`

- [ ] **步骤 6：检查 diff 范围**

```powershell
git status --short --branch
git diff --stat
git diff --check
```

预期：只包含本计划涉及的计划周视图、存储拆分、结构测试和必要文档更新；`git diff --check` 没有空白错误。

- [ ] **步骤 7：最终 commit**

如果任务 6 修改了 README 或格式化调整，提交：

```powershell
git add README.md lib test tools
git commit -m "docs: update architecture split notes"
```

如果没有新增改动，跳过此提交并记录当前分支已经由前面任务提交完毕。
