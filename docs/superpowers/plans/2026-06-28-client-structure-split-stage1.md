# 客户端结构拆分（第一阶段）实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 在不改动业务行为的前提下，完成当前 `home/` 与 `modules/plan/` 的第一阶段结构拆分，让 `LifeHomePage` 保留应用协调职责，`PlanModulePage` 保留页面编排职责，其余表单、列表与辅助函数下沉到专用文件。

**架构：** 这一阶段继续沿用现有的 `part` 单库组织，避免把“文件拆分”和“import 化”混在同一轮里。通过新增 `home/*` 与 `modules/plan/{sheets,widgets}` 文件，把低层 UI 片段和纯辅助逻辑从页面状态类中抽离出来，先把职责边界拉清楚，再为下一阶段的 import 化和 repository 化做准备。

**技术栈：** Flutter、Dart `part` library、现有 `module_shell` 共享组件

---

### 任务 1：抽离计划模块共享辅助函数与列表视图

**文件：**
- 创建：`lib/modules/plan/plan_shared.dart`
- 创建：`lib/modules/plan/widgets/todo_list.dart`
- 修改：`lib/modules/plan/plan_module.dart`
- 修改：`lib/modules/plan/widgets/plan_header.dart`
- 修改：`lib/modules/plan/widgets/todo_card.dart`
- 修改：`lib/modules/plan/widgets/week_plan_view.dart`
- 修改：`lib/modules/plan/sheets/inbox_quick_capture_sheet.dart`
- 修改：`lib/modules/plan/sheets/plan_more_sheet.dart`
- 修改：`lib/main.dart`

- [ ] **步骤 1：把计划模块通用 helper 收拢到独立文件**

```dart
String _formatPlanDate(DateTime? date) { ... }
String _formatPlanMonth(DateTime date) { ... }
String _weekdayLabel(DateTime date) { ... }
String _pendingLinkedHint(TodoItem todo) { ... }
InputDecoration _planInputDecoration(String hint) { ... }
List<(String, Color)> _todoCategoryOptions() { ... }
```

- [ ] **步骤 2：把 `_TodoList` 从 `plan_module.dart` 搬到独立 widget 文件**

```dart
class _TodoList extends StatelessWidget {
  const _TodoList({
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.todos,
    required this.activeFilter,
    this.header,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });
}
```

- [ ] **步骤 3：更新 `main.dart` 的 `part` 清单并让相关 plan 文件统一改用共享 helper**

运行：`flutter analyze`
预期：`No issues found!`

### 任务 2：抽离新增待办表单 Sheet

**文件：**
- 创建：`lib/modules/plan/sheets/todo_editor_sheet.dart`
- 修改：`lib/modules/plan/plan_module.dart`
- 修改：`lib/main.dart`

- [ ] **步骤 1：把 `_showAddTodoSheet` 的 UI 和表单状态移到独立 Sheet 文件**

```dart
void _showPlanTodoEditorSheet({
  required BuildContext context,
  required DateTime today,
  required ValueChanged<TodoItem> onSave,
}) { ... }
```

- [ ] **步骤 2：让 `PlanModulePage` 只保留触发逻辑，改为调用新的 Sheet 入口**

```dart
void _showAddTodoSheet() {
  _showPlanTodoEditorSheet(
    context: context,
    today: _today,
    onSave: widget.onAddTodo,
  );
}
```

- [ ] **步骤 3：重新运行验证**

运行：`flutter analyze`
预期：`No issues found!`

### 任务 3：收紧首页文件职责

**文件：**
- 创建：`lib/home/life_home_seed_data.dart`
- 创建：`lib/home/life_home_routing.dart`
- 修改：`lib/home/life_home_page.dart`
- 修改：`lib/main.dart`

- [ ] **步骤 1：把首页默认示例数据移到独立文件**

```dart
List<TodoItem> _createSeedTodos() => [ ... ];
List<FinanceRecord> _createSeedFinanceRecords() => [ ... ];
```

- [ ] **步骤 2：把路由到模块/快捷动作的纯解析逻辑移到独立文件**

```dart
LifeModule _lifeModuleFromRoute(String route) { ... }
WidgetQuickAction? _widgetQuickActionFromRoute(String route) { ... }
WidgetQuickAction? _widgetQuickActionFromName(String? action) { ... }
```

- [ ] **步骤 3：让 `LifeHomePage` 只保留状态协调和模块联动逻辑**

运行：`flutter analyze`
预期：`No issues found!`

### 任务 4：做一次完整验证

**文件：**
- 测试：`test/widget_test.dart`
- 验证：`lib/home/life_home_page.dart`
- 验证：`lib/modules/plan/plan_module.dart`

- [ ] **步骤 1：运行静态分析**

运行：`flutter analyze`
预期：`No issues found!`

- [ ] **步骤 2：运行基础 Flutter 测试**

运行：`flutter test`
预期：现有测试全部通过；如果存在与本次改动无关的历史失败，记录具体失败用例与原因
