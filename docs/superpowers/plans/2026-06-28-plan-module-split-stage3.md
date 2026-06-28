# 计划模块结构拆分（第三阶段）实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 把 `PlanModulePage` 里剩余的状态编排、筛选逻辑和动作入口继续拆薄，让 `plan_module.dart` 只保留页面骨架、少量状态和高层路由。

**架构：** 这一阶段继续沿用现有 `part` 组织，不触碰全局 import 化。通过新增 `modules/plan/plan_state.dart`、`modules/plan/plan_actions.dart` 和一个更薄的 body widget，把 tab 切换、筛选、快捷动作、收件箱录入等职责从页面类中分离出去，同时保持现有测试语义不变。

**技术栈：** Flutter、Dart `part` library、现有 widget 测试

---

### 任务 1：拆出计划模块状态与派生计算

**文件：**
- 创建：`lib/modules/plan/plan_state.dart`
- 修改：`lib/modules/plan/plan_module.dart`
- 修改：`lib/main.dart`

- [ ] **步骤 1：把 `_selectedDate`、`_selectedTab`、`_categoryFilter`、`_handledQuickActionToken` 和派生 getter 移到独立扩展文件**

```dart
mixin _PlanModuleState on State<PlanModulePage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  int _selectedTab = 0;
  String _categoryFilter = '全部';
  int _handledQuickActionToken = 0;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());
  List<TodoItem> get _activeTodos => ...;
  List<TodoItem> get _todayTodos => ...;
  List<TodoItem> get _inboxTodos => ...;
  List<TodoItem> get _completedTodos => ...;
  List<TodoItem> get _archivedTodos => ...;
  List<TodoItem> get _filteredTodayTodos => ...;
  int _sortTodos(TodoItem a, TodoItem b) => ...;
}
```

- [ ] **步骤 2：更新 `plan_module.dart` 仅保留 widget 生命周期和 build 编排**

运行：`flutter analyze`
预期：`No issues found!`

### 任务 2：拆出计划模块动作与弹层入口

**文件：**
- 创建：`lib/modules/plan/plan_actions.dart`
- 修改：`lib/modules/plan/plan_module.dart`
- 修改：`lib/main.dart`

- [ ] **步骤 1：把 `_maybeHandleQuickAction`、`_addInboxTodo`、`_openMoreSheet`、`_showAddTodoSheet` 与 `_toggleTodo` 的转发逻辑移到独立扩展文件**

```dart
mixin _PlanModuleActions on State<PlanModulePage> {
  void _maybeHandleQuickAction() { ... }
  void _toggleTodo(TodoItem todo) => widget.onToggleTodo(todo);
  void _addInboxTodo(String title) { ... }
  void _openMoreSheet() { ... }
  void _showAddTodoSheet() { ... }
}
```

- [ ] **步骤 2：把 `PlanModulePage` 的 `initState`、`didUpdateWidget` 和 `build` 调用改为使用新的扩展文件**

运行：`flutter analyze`
预期：`No issues found!`

### 任务 3：把主内容区拆成更小的壳

**文件：**
- 创建：`lib/modules/plan/widgets/plan_body.dart`
- 修改：`lib/modules/plan/plan_module.dart`

- [ ] **步骤 1：把 `_buildTabContent` 和 `Scaffold` body 布局移到独立 widget 文件**

```dart
class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.selectedTab,
    required this.selectedDate,
    required this.activeFilter,
    required this.todos,
    required this.events,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todayExpense,
    required this.healthStatusText,
    required this.onSelectDate,
    required this.onToggleTodo,
    required this.onPostponeTodo,
    required this.onArchiveTodo,
    required this.onDeleteTodo,
    required this.onQuickCapture,
    required this.onAddTodo,
    required this.onClearCompletedTodos,
  });
}
```

- [ ] **步骤 2：让 `_PlanModulePageState.build` 只负责把参数传给 `_PlanBody`**

运行：`flutter analyze`
预期：`No issues found!`

### 任务 4：完整验证第三阶段拆分

**文件：**
- 验证：`lib/modules/plan/plan_module.dart`
- 验证：`lib/modules/plan/plan_state.dart`
- 验证：`lib/modules/plan/plan_actions.dart`
- 验证：`lib/modules/plan/widgets/plan_body.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：运行静态分析**

运行：`flutter analyze`
预期：`No issues found!`

- [ ] **步骤 2：运行 Flutter 测试**

运行：`flutter test`
预期：现有测试全部通过，尤其是计划页新增待办、收件箱录入、更多菜单筛选与周视图切换场景
