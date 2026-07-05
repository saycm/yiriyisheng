# 平生 Life 架构整理第一阶段设计

## 背景

当前项目已经覆盖计划、财务、饮食、锻炼、健康、小组件、Android 原生桥接和 Go 服务端。近期主要问题集中在小组件交互、模块 UI 一致性、计划面板溢出和发布更新链路。继续修这些问题之前，需要先降低大文件和跨层耦合带来的维护风险。

本阶段选择“页面 / 逻辑 / 数据分层整理”路线，但只做第一阶段：先整理计划周视图和本地存储边界。目标是让后续小组件交互和 UI 一致性优化更稳，不在本阶段改变用户可见行为。

## 成功标准

- `lib/modules/plan/widgets/week_plan_view.dart` 不再承担所有周视图 UI、排程动作和反馈逻辑。
- `lib/storage/app_data_store.dart` 保持 `LifeSummaryStore` 对外接口不变，但模型行映射和表操作帮助函数边界更清楚。
- 现有页面行为、数据恢复、小组件摘要同步和测试预期不改变。
- `flutter analyze`、`flutter test`、`go test ./...`、`python tools/check_widget_redesign.py` 通过。

## 非目标

- 不重做小组件交互。
- 不调整模块视觉风格、导航位置或卡片密度。
- 不重写所有模块架构。
- 不改变 SQLite schema，除非测试发现现有结构阻碍拆分。
- 不改服务端发布流程。

## 第一阶段范围

### 计划周视图拆分

`week_plan_view.dart` 目前同时包含：

- 周视图入口和数据分组。
- 顶部命令中心。
- 7 天任务面板。
- 未安排任务区。
- 选中日期任务面板。
- 自动安排、均衡本周、清理过期、撤销反馈等动作。

拆分后建议结构：

```text
lib/modules/plan/widgets/week/
  week_plan_view.dart              周视图入口，只组装数据和子组件
  week_plan_actions.dart           自动安排、均衡、清理、撤销等动作
  week_command_center.dart         顶部统计和快捷命令
  week_day_board.dart              7 天任务看板
  week_backlog_section.dart        未安排/过期待整理任务
  week_selected_tasks_panel.dart   选中日期任务列表
  week_feedback.dart               snack bar / overlay 反馈
```

对外仍通过 `part of '../plan.dart'` 或现有模块组织方式接入，避免一次性改大量 import。每个新文件只承担一个显示或动作职责。

### 本地存储边界整理

`AppDataStore` 当前承担 SQLite 打开、升级、读写队列、模型行映射和表同步。第一阶段不改 `LifeSummaryStore` 接口，只把内部职责拆清楚。

建议结构：

```text
lib/storage/
  app_data_store.dart              LifeSummaryStore 实现、保存队列、事务编排
  app_data_rows.dart               Todo / Finance / Workout 行映射
  app_data_tables.dart             建表、升级、upsert、delete missing helpers
```

如果继续使用 `part`，仍由 `storage.dart` 统一导入，避免调用方变化。

## 数据流

整理前后数据流保持一致：

```text
LifeHomePage
  -> PlanModulePage / FinanceModulePage / WorkoutModulePage
  -> LifeSummaryStore.save/load
  -> AppDataStore
  -> SQLite
  -> LifeWidgetStore
  -> Android SharedPreferences
  -> Home Widget
```

计划周视图只接收 `todos` 和回调，不直接持久化。所有待办变更仍回到首页状态层，再由 `_syncLinkedSummaryToWidget()` 触发 App 数据和小组件摘要同步。

## 错误处理

- 周视图拆分不新增错误分支；自动安排和撤销反馈保持原行为。
- 存储拆分保留现有保存队列 `_pendingSave`，避免并发保存互相覆盖。
- 保存失败仍通过首页保存失败横幅提示，不在本阶段改交互。
- 旧库升级逻辑保持幂等，重复字段仍跳过。

## 测试策略

需要重点跑现有测试：

- `flutter analyze`
- `flutter test`
- `go test ./...`
- `python tools/check_widget_redesign.py`

特别关注：

- `plan_widget_test.dart` 中周计划、自动安排、撤销、溢出相关预期。
- `storage_app_data_store_test.dart` 中保存失败和恢复逻辑。
- `widget_test.dart` 中模块导航和小组件快捷入口。

如果拆分过程中发现某个动作缺少覆盖，再补最小回归测试。

## 风险与缓解

- 风险：拆分 `part` 文件时遗漏私有函数引用。
  缓解：优先保持 `part of` 组织，不做 public API 大迁移。

- 风险：周视图动作拆出去后，闭包依赖变多。
  缓解：先抽纯 helper 和小组件，再抽动作；每一步跑相关测试。

- 风险：存储拆分影响 SQLite 读写。
  缓解：不改 schema，不改 `LifeSummaryStore`，只移动 row mapper 和 helper。

## 执行顺序

1. 拆 `week_plan_view.dart` 的纯 UI 子组件。
2. 拆周视图动作和反馈 helper。
3. 跑计划相关测试，确认行为不变。
4. 拆 `AppDataStoreRows` 和表 helper。
5. 跑存储相关测试。
6. 跑完整验证。

## 审查点

本设计通过后，下一步才进入实现计划。实现计划需要把每个文件拆分步骤拆成可验证的小提交或小阶段，避免一次性大改。
