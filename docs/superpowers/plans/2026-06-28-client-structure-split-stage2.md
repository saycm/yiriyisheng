# 客户端结构拆分（第二阶段）实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 在不改动现有行为的前提下，把 `LifeHomePage` 剩余的状态协调方法继续按职责拆开，让首页文件主要保留状态字段、生命周期和 `build` 入口。

**架构：** 这一阶段继续沿用当前 `part` 单库方案，不引入 `import` 化和状态管理框架。通过新增 `home/` 下的职责文件，把首页的持久化恢复、弹层入口、业务变更方法迁移到同库扩展中，降低 `life_home_page.dart` 的阅读和修改成本，同时保持现有 private API 和测试覆盖不变。

**技术栈：** Flutter、Dart `part` library、现有 widget 测试

---

### 任务 1：拆出首页持久化与快捷入口协调

**文件：**
- 创建：`lib/home/life_home_persistence.dart`
- 创建：`lib/home/life_home_overlays.dart`
- 修改：`lib/home/life_home_page.dart`
- 修改：`lib/main.dart`

- [ ] **步骤 1：把本地恢复和小组件同步逻辑移到独立扩展文件**

```dart
extension _LifeHomePersistence on _LifeHomePageState {
  Future<void> _restoreAppData() async { ... }
  void _applyLifeSummarySnapshot(LifeSummarySnapshot snapshot) { ... }
  void _syncLinkedSummaryToWidget() { ... }
}
```

- [ ] **步骤 2：把模块弹层、快捷记录弹层和联动跳转逻辑移到独立扩展文件**

```dart
extension _LifeHomeOverlays on _LifeHomePageState {
  void _openModuleSheet() { ... }
  void _openQuickRecordSheet() { ... }
  void _dispatchQuickRecordAction(WidgetQuickAction action) { ... }
  void _openTodoLinkedActionSheet(TodoItem todo) { ... }
  void _openLinkedModuleAction(TodoLinkedModule linkedModule) { ... }
}
```

- [ ] **步骤 3：更新 `main.dart` 的 `part` 清单并确认首页仍能通过分析**

运行：`flutter analyze`
预期：`No issues found!`

### 任务 2：拆出首页业务变更方法

**文件：**
- 创建：`lib/home/life_home_mutations.dart`
- 修改：`lib/home/life_home_page.dart`

- [ ] **步骤 1：把待办、财务、饮食、锻炼相关的状态写入方法迁移到独立扩展文件**

```dart
extension _LifeHomeMutations on _LifeHomePageState {
  void _recordFoodCalories(int calories) { ... }
  void _updateWorkoutGroups(String actionName, int finishedGroups) { ... }
  void _toggleTodo(TodoItem todo) { ... }
  void _updateTodo(TodoItem todo) { ... }
  void _postponeTodo(TodoItem todo) { ... }
  void _archiveTodo(TodoItem todo) { ... }
  void _deleteTodo(TodoItem todo) { ... }
  void _addTodo(TodoItem todo) { ... }
  void _clearCompletedTodos() { ... }
  void _addFinanceRecord(FinanceRecord record) { ... }
  void _editFinanceRecord(FinanceRecord oldRecord, FinanceRecord newRecord) { ... }
  void _updateAiFinanceConfig({ ... }) { ... }
}
```

- [ ] **步骤 2：把首页事件辅助方法一起迁移，保持 `build` 传参不变**

```dart
void _pushLinkedTodoEvent(TodoItem todo) { ... }
String _todoCompletionDetail(TodoItem todo) { ... }
void _pushLifeEvent(LifeEvent event) { ... }
```

- [ ] **步骤 3：重新运行静态分析**

运行：`flutter analyze`
预期：`No issues found!`

### 任务 3：收紧首页主文件，只保留页面骨架

**文件：**
- 修改：`lib/home/life_home_page.dart`

- [ ] **步骤 1：让 `life_home_page.dart` 只保留以下内容**

```dart
class LifeHomePage extends StatefulWidget { ... }
class _LifeHomePageState extends State<LifeHomePage> {
  // 字段
  // initState / didChangeDependencies / dispose
  // 轻量 getter
  // build
}
```

- [ ] **步骤 2：确认字段、getter 和扩展方法之间没有新的跨文件循环依赖**

运行：`flutter analyze`
预期：`No issues found!`

### 任务 4：完整验证第二阶段拆分

**文件：**
- 验证：`lib/home/life_home_page.dart`
- 验证：`lib/home/life_home_persistence.dart`
- 验证：`lib/home/life_home_overlays.dart`
- 验证：`lib/home/life_home_mutations.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：运行静态分析**

运行：`flutter analyze`
预期：`No issues found!`

- [ ] **步骤 2：运行 Flutter 测试**

运行：`flutter test`
预期：现有测试全部通过，至少覆盖首页模块切换、快捷动作、联动数据恢复和计划页新增待办场景
