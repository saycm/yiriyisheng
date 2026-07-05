# 计划模块工作台优化实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 把计划模块从四个简单列表升级为“收集、整理、排周、执行、复盘”的轻量工作台。

**架构：** 不新增底层数据模型，继续复用 `TodoItem` 的日期、状态、优先级、分类、联动模块和延后次数。改动集中在计划模块 widgets 与 `test/plan_widget_test.dart`，通过现有 `onUpdateTodo/onToggleTodo/onPostponeTodo/onArchiveTodo` 回调完成状态流转。

**技术栈：** Flutter、Dart、现有 `part of '../plan.dart'` 计划模块结构、Flutter widget tests。

---

## 文件结构

- 修改：`test/plan_widget_test.dart`
  - 增加计划工作台交互验收：待办箱整理分组、周计划增强操作、今日执行分区、真实复盘建议。
- 修改：`lib/modules/plan/widgets/plan_body.dart`
  - 为今日页拆分今日三件事、逾期待处理、稍后处理。
- 修改：`lib/modules/plan/widgets/inbox_view.dart`
  - 把待办箱改为收集整理中心，显示无日期、无分类、已过期、低优先级分组和快捷整理动作。
- 修改：`lib/modules/plan/widgets/week_plan_view.dart`
  - 增加平衡本周、低优先级移到下周、清理逾期等周计划操作。
- 修改：`lib/modules/plan/widgets/plan_stats_view.dart`
  - 删掉硬编码复盘数字，改为真实周复盘和下周建议。
- 修改：`lib/modules/plan/widgets/todo_list.dart`
  - 支持今日执行页面的分区 header。
- 修改：`lib/modules/plan/plan_shared.dart`
  - 增加本周日期、负载、复盘文本等小型纯函数。

## 任务 1：测试锁定新工作流

- [ ] 在 `test/plan_widget_test.dart` 添加测试：今日页显示 `今日三件事`、`逾期待处理`、`稍后处理`。
- [ ] 在 `test/plan_widget_test.dart` 添加测试：待办箱显示 `收集整理中心`、`无日期`、`低优先级`，并能点击 `排明天`。
- [ ] 在 `test/plan_widget_test.dart` 添加测试：周计划显示 `平衡本周`、`低优先级移到下周`，点击后有 SnackBar。
- [ ] 在 `test/plan_widget_test.dart` 添加测试：复盘页显示 `下周建议`，且不再显示硬编码 `20,885步`、`499.96元`。
- [ ] 运行 `flutter test test\plan_widget_test.dart`，预期失败，失败原因是新 UI 尚未实现。

## 任务 2：今日执行

- [ ] 修改 `lib/modules/plan/widgets/plan_body.dart`，把今日页待办拆成今日三件事、逾期、稍后三组。
- [ ] 修改 `lib/modules/plan/widgets/todo_list.dart` 或新增私有组件，显示分区标题和说明。
- [ ] 运行 `flutter test test\plan_widget_test.dart`，确认今日执行相关测试通过。

## 任务 3：待办箱整理中心

- [ ] 修改 `lib/modules/plan/widgets/inbox_view.dart`，顶部文案改为 `收集整理中心`。
- [ ] 增加整理分组：无日期、无分类、已过期、低优先级。
- [ ] 为待办箱卡片增加快捷按钮：排今天、排明天、排本周、稍后、归档。
- [ ] 运行 `flutter test test\plan_widget_test.dart`，确认待办箱相关测试通过。

## 任务 4：周计划增强

- [ ] 修改 `lib/modules/plan/widgets/week_plan_view.dart`，在工作台按钮区增加 `平衡本周`、`低优先级移到下周`、`清理逾期`。
- [ ] `平衡本周` 复用一键排周逻辑，按负载最小日期分配待安排任务。
- [ ] `低优先级移到下周` 把本周 `canDelay` 且未完成任务移动到下周同一天。
- [ ] `清理逾期` 把过期未完成任务排到本周最空闲日期。
- [ ] 所有批量操作保留撤销 SnackBar。
- [ ] 运行 `flutter test test\plan_widget_test.dart`，确认周计划相关测试通过。

## 任务 5：真实周复盘

- [ ] 修改 `lib/modules/plan/widgets/plan_stats_view.dart`，删除硬编码步数和最大单笔。
- [ ] 复盘显示真实指标：完成率、未完成、延后任务、过期任务、联动记录。
- [ ] 增加 `下周建议` 卡片：根据未完成、延后、负载偏满生成 2-3 条建议。
- [ ] 运行 `flutter test test\plan_widget_test.dart`，确认复盘相关测试通过。

## 任务 6：全量验证

- [ ] 运行 `flutter test test\plan_widget_test.dart`。
- [ ] 运行 `flutter test test\widget_test.dart`。
- [ ] 运行 `flutter analyze`。
- [ ] 检查 `git diff`，确认只修改计划模块、测试和本计划文档。
