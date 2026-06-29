# 功能模块中心内容重做 实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 将“功能模块”弹窗从热力图和杂项入口改成紧凑的全局模块中心，展示今日状态、模块状态宫格、最近 3 条动态和低权重辅助入口。

**架构：** 保持左上角入口按钮、弹窗打开方式和模块跳转逻辑不变。只修改 `_ModuleSheet` 的内容结构，并在首页弹窗调用处额外传入 `todayExpense` 用于财务摘要。新增私有 UI 小组件集中放在 `lib/shared/module_shell.dart`，避免扩散到各业务模块。

**技术栈：** Flutter、Dart、现有 `PingShengApp` widget 测试、Material Icons、现有 `AppColors` 和 `_airyCardDecoration` 视觉工具。

---

## 文件结构

- 修改：`lib/home/life_home_overlays.dart`
  - 职责：打开功能模块弹窗时，把首页已有的 `_todayExpense` 传给 `_ModuleSheet`。
- 修改：`lib/shared/module_shell.dart`
  - 职责：重做 `_ModuleSheet` 内容结构；新增今日摘要、模块状态宫格、最近动态卡片；删除功能模块内完整热力图相关的私有孤儿组件。
- 修改：`test/widget_test.dart`
  - 职责：用新模块中心测试替换旧热力图测试，保留模块跳转、设置、使用指导等现有行为测试。

## 任务 1：先更新功能模块测试

**文件：**
- 修改：`test/widget_test.dart`

- [ ] **步骤 1：删除旧热力图测试**

删除以下 3 个完整测试块。每个块都从对应的 `testWidgets` 调用开始，到该测试自己的闭合 `});` 结束：

- 名称为 `module heat map day opens linked detail sheet` 的测试
- 名称为 `module sheet switches heat map month and uses sane stats` 的测试
- 名称为 `module heat map day sheet follows selected month` 的测试

- [ ] **步骤 2：新增空动态状态测试**

在原热力图测试附近加入：

```dart
testWidgets('module sheet presents compact module center content',
    (tester) async {
  await tester.pumpWidget(const PingShengApp());

  await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
  await tester.pumpAndSettle();

  expect(find.text('功能模块'), findsWidgets);
  expect(find.byKey(const ValueKey('module_today_summary')), findsOneWidget);
  expect(find.text('今日状态'), findsOneWidget);
  expect(find.text('待办 6 项'), findsOneWidget);
  expect(find.text('饮食 0 kcal'), findsOneWidget);
  expect(find.text('锻炼 0 组'), findsOneWidget);

  expect(find.byKey(const ValueKey('module_sheet_plan')), findsOneWidget);
  expect(find.byKey(const ValueKey('module_sheet_finance')), findsOneWidget);
  expect(find.byKey(const ValueKey('module_sheet_food')), findsOneWidget);
  expect(find.byKey(const ValueKey('module_sheet_workout')), findsOneWidget);
  expect(find.byKey(const ValueKey('module_sheet_health')), findsOneWidget);
  expect(find.byKey(const ValueKey('module_sheet_settings')), findsOneWidget);

  expect(
    find.descendant(
      of: find.byKey(const ValueKey('module_sheet_finance')),
      matching: find.text('今日支出 ¥524'),
    ),
    findsOneWidget,
  );
  expect(find.text('最近动态'), findsOneWidget);
  expect(find.text('今天还没有新记录'), findsOneWidget);
  expect(find.byKey(const ValueKey('module_heat_prev_month')), findsNothing);
});
```

- [ ] **步骤 3：新增非空动态状态测试**

在步骤 2 的测试后加入：

```dart
testWidgets('module sheet shows recent activity after app actions',
    (tester) async {
  await tester.pumpWidget(const PingShengApp());

  await tester.tap(find.text('遛狗'));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
  await tester.pumpAndSettle();

  expect(find.text('最近动态'), findsOneWidget);
  expect(find.text('完成待办'), findsOneWidget);
  expect(find.text('遛狗'), findsWidgets);
  expect(find.text('待办 5 项'), findsOneWidget);
});
```

- [ ] **步骤 4：运行测试确认失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "module sheet presents compact module center content"
flutter test test/widget_test.dart --plain-name "module sheet shows recent activity after app actions"
```

预期：两个测试失败。第一个失败原因包含找不到 `module_today_summary` 或 `今日状态`；第二个失败原因包含找不到 `最近动态` 或 `待办 5 项`。

- [ ] **步骤 5：Commit 测试变更**

```powershell
git add test/widget_test.dart
git commit -m "test: cover module center content"
```

## 任务 2：把今日支出传入功能模块弹窗

**文件：**
- 修改：`lib/home/life_home_overlays.dart`
- 修改：`lib/shared/module_shell.dart`

- [ ] **步骤 1：更新 `_ModuleSheet` 构造参数**

在 `lib/shared/module_shell.dart` 的 `_ModuleSheet` 构造器中加入 `todayExpense`：

```dart
class _ModuleSheet extends StatelessWidget {
  const _ModuleSheet({
    required this.selected,
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todayExpense,
    required this.events,
    required this.onSelect,
    this.onSignOut,
  });

  final LifeModule selected;
  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;
  final double todayExpense;
  final List<LifeEvent> events;
  final ValueChanged<LifeModule> onSelect;
  final Future<void> Function()? onSignOut;
```

- [ ] **步骤 2：更新弹窗调用**

在 `lib/home/life_home_overlays.dart` 的 `_openModuleSheet()` 里传入首页已有 getter：

```dart
return _ModuleSheet(
  selected: _module,
  pendingTodos: _pendingTodoCount,
  foodCalories: _recordedFoodCalories,
  workoutGroups: _workoutFinishedGroups,
  todayExpense: _todayExpense,
  events: _events,
  onSelect: (module) {
    Navigator.of(context).pop();
    _setModule(module);
  },
  onSignOut: widget.onSignOut,
);
```

- [ ] **步骤 3：运行测试确认仍失败但构造错误消失**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "module sheet presents compact module center content"
```

预期：编译通过；测试仍因 UI 内容未实现而失败。

- [ ] **步骤 4：Commit 参数传递**

```powershell
git add lib/home/life_home_overlays.dart lib/shared/module_shell.dart
git commit -m "refactor: pass finance summary into module sheet"
```

## 任务 3：实现新的模块中心内容

**文件：**
- 修改：`lib/shared/module_shell.dart`

- [ ] **步骤 1：替换 `_ModuleSheet` 的 ListView 内容**

将 `_ModuleSheet.build()` 里 `ListView` 的 `children` 替换为：

```dart
children: [
  _ModuleTodaySummaryBar(
    pendingTodos: pendingTodos,
    foodCalories: foodCalories,
    workoutGroups: workoutGroups,
  ),
  const SizedBox(height: 14),
  _ModuleCenterGrid(
    selected: selected,
    pendingTodos: pendingTodos,
    foodCalories: foodCalories,
    workoutGroups: workoutGroups,
    todayExpense: todayExpense,
    onSelect: onSelect,
    onOpenSettings: () => _showSettingsSheet(context),
  ),
  const SizedBox(height: 14),
  _ModuleRecentEventsCard(events: events.take(3).toList()),
  const SizedBox(height: 14),
  const _ModuleSectionTitle(
    icon: Icons.more_horiz_rounded,
    title: '更多',
  ),
  const SizedBox(height: 10),
  _ModuleListItem(
    icon: Icons.info_outline_rounded,
    title: '关于 App',
    onTap: () => _showAboutSheet(context),
  ),
  _ModuleListItem(
    icon: Icons.article_outlined,
    title: '使用指导',
    onTap: () => _showGuideSheet(context),
  ),
  _ModuleListItem(
    icon: Icons.edit_rounded,
    title: '问题反馈',
    onTap: () => _showFeedbackSheet(context),
  ),
  if (onSignOut != null)
    _ModuleListItem(
      icon: Icons.logout_rounded,
      title: '退出登录',
      iconColor: AppColors.financeRed,
      titleColor: AppColors.financeRed,
      onTap: () {
        Navigator.of(context).pop();
        unawaited(onSignOut!());
      },
    ),
],
```

- [ ] **步骤 2：新增今日摘要组件**

在 `_ModuleSheet` 后、热力图旧代码删除位置前加入：

```dart
class _ModuleTodaySummaryBar extends StatelessWidget {
  const _ModuleTodaySummaryBar({
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
  });

  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('module_today_summary'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: _airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderColor: AppColors.line,
        shadows: [_airyShadow(AppColors.sky)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 7),
              Text(
                '今日状态',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModuleSummaryChip(text: '待办 $pendingTodos 项'),
              _ModuleSummaryChip(text: '饮食 $foodCalories kcal'),
              _ModuleSummaryChip(text: '锻炼 $workoutGroups 组'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleSummaryChip extends StatelessWidget {
  const _ModuleSummaryChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
```

- [ ] **步骤 3：新增模块状态宫格组件**

继续在 `lib/shared/module_shell.dart` 加入：

```dart
class _ModuleCenterGrid extends StatelessWidget {
  const _ModuleCenterGrid({
    required this.selected,
    required this.pendingTodos,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todayExpense,
    required this.onSelect,
    required this.onOpenSettings,
  });

  final LifeModule selected;
  final int pendingTodos;
  final int foodCalories;
  final int workoutGroups;
  final double todayExpense;
  final ValueChanged<LifeModule> onSelect;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final financeText = todayExpense > 0
        ? '今日支出 ¥${_formatModuleMoney(todayExpense)}'
        : '查看账本';
    final healthText =
        foodCalories > 0 || workoutGroups > 0 ? '今日有记录' : '未记录';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ModuleSectionTitle(
          icon: Icons.grid_view_rounded,
          title: '模块状态',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 10) / 2;
            Widget tile(Widget child) => SizedBox(
                  width: tileWidth,
                  child: child,
                );

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                tile(_ModuleCenterTile(
                  tileKey: const ValueKey('module_sheet_plan'),
                  icon: Icons.event_available_rounded,
                  title: '计划',
                  status: '$pendingTodos 项待办',
                  selected: selected == LifeModule.plan,
                  onTap: () => onSelect(LifeModule.plan),
                )),
                tile(_ModuleCenterTile(
                  tileKey: const ValueKey('module_sheet_finance'),
                  icon: Icons.account_balance_wallet_rounded,
                  title: '财务',
                  status: financeText,
                  selected: selected == LifeModule.finance,
                  onTap: () => onSelect(LifeModule.finance),
                )),
                tile(_ModuleCenterTile(
                  tileKey: const ValueKey('module_sheet_food'),
                  icon: Icons.restaurant_rounded,
                  title: '饮食',
                  status: '$foodCalories kcal',
                  selected: selected == LifeModule.food,
                  onTap: () => onSelect(LifeModule.food),
                )),
                tile(_ModuleCenterTile(
                  tileKey: const ValueKey('module_sheet_workout'),
                  icon: Icons.fitness_center_rounded,
                  title: '锻炼',
                  status: '$workoutGroups 组训练',
                  selected: selected == LifeModule.workout,
                  onTap: () => onSelect(LifeModule.workout),
                )),
                tile(_ModuleCenterTile(
                  tileKey: const ValueKey('module_sheet_health'),
                  icon: Icons.monitor_heart_rounded,
                  title: '健康',
                  status: healthText,
                  selected: selected == LifeModule.health,
                  onTap: () => onSelect(LifeModule.health),
                )),
                tile(_ModuleCenterTile(
                  tileKey: const ValueKey('module_sheet_settings'),
                  icon: Icons.settings_rounded,
                  title: '设置',
                  status: '账号与偏好',
                  selected: false,
                  onTap: onOpenSettings,
                )),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ModuleCenterTile extends StatelessWidget {
  const _ModuleCenterTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: tileKey,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: _airyCardDecoration(
          color: selected
              ? AppColors.primarySoft.withValues(alpha: 0.9)
              : AppColors.surface.withValues(alpha: 0.96),
          borderColor: selected
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.line,
          shadows: [_airyShadow(selected ? AppColors.primary : AppColors.sky)],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.muted,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **步骤 4：新增最近动态组件和金额格式化函数**

继续加入：

```dart
class _ModuleRecentEventsCard extends StatelessWidget {
  const _ModuleRecentEventsCard({required this.events});

  final List<LifeEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 19),
              SizedBox(width: 8),
              Text(
                '最近动态',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (events.isEmpty)
            const Text(
              '今天还没有新记录',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (var index = 0; index < events.length; index++)
              _ModuleRecentEventRow(
                event: events[index],
                showDivider: index != events.length - 1,
              ),
        ],
      ),
    );
  }
}

class _ModuleRecentEventRow extends StatelessWidget {
  const _ModuleRecentEventRow({
    required this.event,
    required this.showDivider,
  });

  final LifeEvent event;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      margin: EdgeInsets.only(bottom: showDivider ? 10 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(event.icon, color: event.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatModuleMoney(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toStringAsFixed(0);
  }
  return amount.toStringAsFixed(2);
}
```

- [ ] **步骤 5：运行新测试确认通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "module sheet presents compact module center content"
flutter test test/widget_test.dart --plain-name "module sheet shows recent activity after app actions"
```

预期：两个测试 PASS。

- [ ] **步骤 6：Commit 新 UI 内容**

```powershell
git add lib/shared/module_shell.dart test/widget_test.dart
git commit -m "feat: redesign module sheet content"
```

## 任务 4：删除功能模块热力图孤儿代码

**文件：**
- 修改：`lib/shared/module_shell.dart`

- [ ] **步骤 1：删除不再使用的热力图入口方法**

删除 `_ModuleSheet` 内的方法：

```dart
void _showHeatMapDaySheet(BuildContext context, DateTime date) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _HeatMapDaySheet(date: date),
  );
}
```

- [ ] **步骤 2：删除完整热力图相关私有组件和函数**

从 `lib/shared/module_shell.dart` 删除以下完整声明：

- `class _ModuleProfileCard extends StatefulWidget`
- `class _ModuleProfileCardState extends State<_ModuleProfileCard>`
- `class _ModuleHeatMap extends StatelessWidget`
- `int _heatValueForDay(DateTime month, int day)`
- `class _HeatMapDaySheet extends StatelessWidget`
- `class _HeatMapActionTile extends StatelessWidget`
- `class _ModuleStat extends StatelessWidget`

不要删除 `_AppIconMark`，它仍在其它位置使用。

- [ ] **步骤 3：搜索确认没有残留引用**

运行：

```powershell
rg -n "_ModuleProfileCard|_ModuleHeatMap|_heatValueForDay|_HeatMapDaySheet|_HeatMapActionTile|_ModuleStat|module_heat_" lib/shared/module_shell.dart test/widget_test.dart
```

预期：没有输出。

- [ ] **步骤 4：运行功能模块相关测试**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "module sheet"
flutter test test/widget_test.dart --plain-name "module guide reflects current navigation and linked modules"
```

预期：全部 PASS。

- [ ] **步骤 5：Commit 清理**

```powershell
git add lib/shared/module_shell.dart test/widget_test.dart
git commit -m "refactor: remove module heat map sheet"
```

## 任务 5：全量验证和收尾

**文件：**
- 修改：无预期新代码；只执行验证和可能的测试期望微调。

- [ ] **步骤 1：运行 widget 测试**

运行：

```powershell
flutter test test/widget_test.dart
```

预期：全部 PASS。

- [ ] **步骤 2：运行静态检查**

运行：

```powershell
flutter analyze
```

预期：没有新增 error；如果仓库已有 warning，确认与本次改动无关并在最终说明中列出。

- [ ] **步骤 3：查看工作区改动**

运行：

```powershell
git status --short
git log --oneline -5
```

预期：只有本计划中涉及的文件有改动；最近提交包含测试、参数传递、UI 内容、热力图清理。

- [ ] **步骤 4：最终提交未提交的验证修正**

如果步骤 1 或步骤 2 需要微调测试期望或样式，提交：

```powershell
git add lib/shared/module_shell.dart lib/home/life_home_overlays.dart test/widget_test.dart
git commit -m "test: verify module center redesign"
```

如果没有额外改动，跳过本步骤。
