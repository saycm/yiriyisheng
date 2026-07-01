# 锻炼训练计划闭环阶段 1 实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 让锻炼模块的“计划”页从静态展示升级为可点击计划详情，并能从计划详情开始一次计划训练。

**架构：** 本阶段只实现训练计划闭环的入口层：新增轻量 `WorkoutPlan` 模型、默认计划列表、计划详情弹层、开始训练状态，并让训练页按当前计划过滤动作。暂不实现历史记录、数据统计、SQLite 持久化和计划编辑。

**技术栈：** Flutter/Dart，现有 `part of '../../main.dart'` 单库结构，Widget Test，现有 `WorkoutModulePage` 状态管理。

---

## 文件结构

本阶段只修改两个现有文件：

- `lib/modules/workout/workout_module.dart`
  - 新增 `WorkoutPlan` 模型。
  - 新增默认计划列表。
  - 让计划页模板和计划卡可点击。
  - 新增计划详情 bottom sheet。
  - 新增当前计划训练状态。
  - 训练页按当前计划过滤动作。
- `test/widget_test.dart`
  - 新增阶段 1 回归测试。
  - 覆盖计划详情打开、开始训练、计划动作过滤。

本阶段不修改：

- `lib/storage/app_data_store.dart`
- `lib/models/life_data.dart`
- `lib/home/life_home_page.dart`

这些文件留给后续“训练历史和持久化”阶段。

---

### 任务 1：写计划闭环失败测试

**文件：**
- 修改：`test/widget_test.dart`

- [ ] **步骤 1：新增 widget test**

在 `workout top tabs show plan data and history` 测试之后，加入下面测试：

```dart
  testWidgets('workout plan opens detail and starts scoped workout',
      (tester) async {
    await tester.pumpWidget(const PingShengApp());

    await tester.tap(find.byKey(const ValueKey('module_link_3')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_top_tab_1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout_plan_card_chest_power')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workout_plan_detail_sheet')), findsOneWidget);
    expect(find.text('胸背强化'), findsWidgets);
    expect(find.text('5 个动作'), findsOneWidget);
    expect(find.text('19 组'), findsOneWidget);
    expect(find.text('开始训练'), findsOneWidget);

    await tester.tap(find.text('开始训练'));
    await tester.pumpAndSettle();

    expect(find.text('当前计划'), findsOneWidget);
    expect(find.text('胸背强化'), findsWidgets);
    expect(find.text('5 个动作'), findsWidgets);
    expect(find.text('蝴蝶机夹胸'), findsWidgets);
    expect(find.text('宽握高位下拉'), findsWidgets);
    expect(find.text('平板支撑'), findsNothing);
  });
```

- [ ] **步骤 2：运行测试确认失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan opens detail and starts scoped workout"
```

预期：

- 测试失败。
- 失败原因包含找不到 `workout_plan_card_chest_power` 或 `workout_plan_detail_sheet`。

- [ ] **步骤 3：Commit 失败测试**

```powershell
git add test/widget_test.dart
git commit -m "test: cover workout plan start flow"
```

---

### 任务 2：新增训练计划模型和默认计划

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`

- [ ] **步骤 1：新增 `WorkoutPlan` 模型**

在 `WorkoutAction` 类后面新增：

```dart
class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.target,
    required this.bodyParts,
    required this.actionNames,
    required this.estimatedMinutes,
  });

  final String id;
  final String name;
  final String target;
  final List<String> bodyParts;
  final List<String> actionNames;
  final int estimatedMinutes;
}
```

- [ ] **步骤 2：新增默认计划列表**

在 `_WorkoutModulePageState` 的 `_actions` 后面新增：

```dart
  static const _plans = [
    WorkoutPlan(
      id: 'chest_power',
      name: '胸背强化',
      target: '胸背力量与上肢稳定',
      bodyParts: ['胸背'],
      actionNames: [
        '蝴蝶机夹胸',
        '宽握高位下拉',
        '器械推胸',
        '坐姿绳索划船',
        '上斜哑铃卧推',
      ],
      estimatedMinutes: 38,
    ),
    WorkoutPlan(
      id: 'legs_stability',
      name: '腿部稳定',
      target: '下肢力量与单腿稳定',
      bodyParts: ['腿部'],
      actionNames: [
        '杠铃深蹲',
        '保加利亚分腿蹲',
        '罗马尼亚硬拉',
        '臀桥',
      ],
      estimatedMinutes: 34,
    ),
    WorkoutPlan(
      id: 'core_recovery',
      name: '核心恢复',
      target: '核心控制与躯干恢复',
      bodyParts: ['核心'],
      actionNames: [
        '平板支撑',
        '死虫',
        '俄罗斯转体',
      ],
      estimatedMinutes: 18,
    ),
    WorkoutPlan(
      id: 'stretch_reset',
      name: '恢复日',
      target: '拉伸放松与活动度恢复',
      bodyParts: ['拉伸'],
      actionNames: [
        '站姿股四头肌拉伸',
        '坐姿腘绳肌拉伸',
        '猫牛式伸展',
        '儿童式放松',
      ],
      estimatedMinutes: 16,
    ),
    WorkoutPlan(
      id: 'quick_10',
      name: '快练 10 分钟',
      target: '碎片时间快速激活',
      bodyParts: ['核心', '有氧'],
      actionNames: [
        '平板支撑',
        '登山跑',
        '跳绳间歇',
      ],
      estimatedMinutes: 10,
    ),
  ];
```

- [ ] **步骤 3：新增按计划取动作的 helper**

在 `_finishedGroupsFor` 后面新增：

```dart
  List<WorkoutAction> _actionsForPlan(WorkoutPlan plan) {
    return plan.actionNames
        .map(
          (name) => _actions.firstWhere(
            (action) => action.name == name,
            orElse: () => _actions.first,
          ),
        )
        .where((action) => plan.actionNames.contains(action.name))
        .toList();
  }
```

- [ ] **步骤 4：运行分析**

运行：

```powershell
flutter analyze
```

预期：

- `No issues found!`

- [ ] **步骤 5：Commit 模型**

```powershell
git add lib/modules/workout/workout_module.dart
git commit -m "feat: add workout plan model"
```

---

### 任务 3：让计划页可点击并打开详情

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`

- [ ] **步骤 1：给状态类新增打开计划详情方法**

在 `_handleBottomNav` 前面新增：

```dart
  void _openPlanDetail(WorkoutPlan plan) {
    final actions = _actionsForPlan(plan);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutPlanDetailSheet(
          plan: plan,
          actions: actions,
          onStart: () {
            Navigator.of(context).pop();
            _startPlanWorkout(plan);
          },
        );
      },
    );
  }
```

- [ ] **步骤 2：新增空的 `_startPlanWorkout` 方法**

先添加最小方法，下一任务再实现状态逻辑：

```dart
  void _startPlanWorkout(WorkoutPlan plan) {
    setState(() => _selectedTopTab = 0);
  }
```

- [ ] **步骤 3：把计划页改为接收计划和点击回调**

把 `_buildWorkoutContent` 中计划页分支改为：

```dart
    if (_selectedTopTab == 1) {
      return _WorkoutPlanView(
        plans: _plans,
        onOpenPlan: _openPlanDetail,
      );
    }
```

把 `_WorkoutPlanView` 构造改为：

```dart
class _WorkoutPlanView extends StatelessWidget {
  const _WorkoutPlanView({
    required this.plans,
    required this.onOpenPlan,
  });

  final List<WorkoutPlan> plans;
  final ValueChanged<WorkoutPlan> onOpenPlan;
```

- [ ] **步骤 4：计划页使用默认计划渲染**

把 `_WorkoutPlanView.build` 的 `children` 改为：

```dart
      children: [
        _WorkoutTemplateRail(
          plans: plans,
          onOpenPlan: onOpenPlan,
        ),
        const SizedBox(height: 12),
        ...plans.take(3).map(
              (plan) => _WorkoutPlanCard(
                plan: plan,
                color: switch (plan.id) {
                  'chest_power' => AppColors.primary,
                  'legs_stability' => AppColors.success,
                  _ => const Color(0xFFFF9559),
                },
                onTap: () => onOpenPlan(plan),
              ),
            ),
      ],
```

- [ ] **步骤 5：改造 `_WorkoutPlanCard`**

把 `_WorkoutPlanCard` 改成：

```dart
class _WorkoutPlanCard extends StatelessWidget {
  const _WorkoutPlanCard({
    required this.plan,
    required this.color,
    required this.onTap,
  });

  final WorkoutPlan plan;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('workout_plan_card_${plan.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assignment_rounded, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${plan.target} · ${plan.estimatedMinutes} min',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${plan.actionNames.length} 动作',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **步骤 6：改造 `_WorkoutTemplateRail`**

把构造和字段改成：

```dart
  const _WorkoutTemplateRail({
    required this.plans,
    required this.onOpenPlan,
  });

  final List<WorkoutPlan> plans;
  final ValueChanged<WorkoutPlan> onOpenPlan;
```

把内部 `templates` 常量替换为：

```dart
    final templates = [
      (plans[0], Icons.accessibility_new_rounded, AppColors.primary),
      (plans[2], Icons.self_improvement_rounded, AppColors.success),
      (plans[3], Icons.spa_rounded, const Color(0xFFFF9559)),
      (plans[4], Icons.flash_on_rounded, const Color(0xFF43C6C8)),
    ];
```

把每个模板 row 包一层 `InkWell`：

```dart
              child: InkWell(
                key: ValueKey('workout_template_${item.$1.id}'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => onOpenPlan(item.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // 保留原图标容器，文本改为 item.$1.name 和 item.$1.target
                    ],
                  ),
                ),
              ),
```

文本内容使用：

```dart
Text(item.$1.name, ...)
Text('${item.$1.actionNames.length} 动作 · ${item.$1.estimatedMinutes} min', ...)
```

- [ ] **步骤 7：新增计划详情 sheet**

在 `_WorkoutTemplateRail` 后面新增：

```dart
class _WorkoutPlanDetailSheet extends StatelessWidget {
  const _WorkoutPlanDetailSheet({
    required this.plan,
    required this.actions,
    required this.onStart,
  });

  final WorkoutPlan plan;
  final List<WorkoutAction> actions;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final totalGroups =
        actions.fold(0, (total, action) => total + action.groups);
    return Container(
      key: const ValueKey('workout_plan_detail_sheet'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 14),
            Text(
              plan.name,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              plan.target,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _WorkoutPlanMetaPill(label: '${actions.length} 个动作'),
                const SizedBox(width: 8),
                _WorkoutPlanMetaPill(label: '$totalGroups 组'),
                const SizedBox(width: 8),
                _WorkoutPlanMetaPill(label: '${plan.estimatedMinutes} min'),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: actions
                      .map((action) => _WorkoutPlanActionPreview(action: action))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: actions.isEmpty ? null : onStart,
                child: const Text('开始训练'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

同时新增两个小组件：

```dart
class _WorkoutPlanMetaPill extends StatelessWidget {
  const _WorkoutPlanMetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorkoutPlanActionPreview extends StatelessWidget {
  const _WorkoutPlanActionPreview({required this.action});

  final WorkoutAction action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: _WorkoutActionArt(
              action: action,
              size: 40,
              radius: 8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action.detail,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
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
```

- [ ] **步骤 8：运行测试确认进入下一失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan opens detail and starts scoped workout"
```

预期：

- 测试仍失败。
- 现在应能找到 `workout_plan_detail_sheet`。
- 失败点应出现在点击“开始训练”后的“当前计划”或过滤动作断言。

- [ ] **步骤 9：Commit 计划详情**

```powershell
git add lib/modules/workout/workout_module.dart
git commit -m "feat: open workout plan details"
```

---

### 任务 4：实现计划训练模式

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`

- [ ] **步骤 1：新增当前计划状态**

在 `_activeBodyPart` 后面新增：

```dart
  WorkoutPlan? _activePlan;
```

- [ ] **步骤 2：新增当前训练动作列表 helper**

在 `_actionsForPlan` 后面新增：

```dart
  List<WorkoutAction> get _activeWorkoutActions {
    final plan = _activePlan;
    if (plan == null) {
      return _actions;
    }
    return _actionsForPlan(plan);
  }

  WorkoutAction _nextActionFor(List<WorkoutAction> actions) {
    return actions.firstWhere(
      (action) => _finishedGroupsFor(action) < action.groups,
      orElse: () => actions.isEmpty ? _actions.last : actions.last,
    );
  }
```

- [ ] **步骤 3：调整总组数和已完成数量计算**

保留现有 `_totalGroups`、`_finishedGroupsTotal`、`_finishedActionCount` 用于全量统计，新增计划范围统计：

```dart
  int _totalGroupsFor(List<WorkoutAction> actions) =>
      actions.fold(0, (total, action) => total + action.groups);

  int _finishedGroupsForActions(List<WorkoutAction> actions) => actions.fold(
        0,
        (total, action) => total + _finishedGroupsFor(action),
      );

  int _finishedActionCountFor(List<WorkoutAction> actions) => actions
      .where((action) => _finishedGroupsFor(action) >= action.groups)
      .length;
```

- [ ] **步骤 4：实现 `_startPlanWorkout`**

替换任务 3 的临时方法：

```dart
  void _startPlanWorkout(WorkoutPlan plan) {
    final actions = _actionsForPlan(plan);
    setState(() {
      _activePlan = plan;
      _selectedTopTab = 0;
      _activeBodyPart = '全部';
      _activeAction = actions.isEmpty ? null : _nextActionFor(actions);
    });
  }
```

- [ ] **步骤 5：动作详情返回后停留在计划训练模式**

在 `build` 中传给 `_WorkoutActionDetailPage` 的 `onBack` 保持：

```dart
onBack: () => setState(() => _activeAction = null),
```

不需要额外改动。

- [ ] **步骤 6：训练页使用当前计划动作**

在 `_buildWorkoutContent` 中，把 `visibleActions` 前增加：

```dart
    final scopedActions = _activeWorkoutActions;
```

把原来的 `visibleActions` 计算替换为：

```dart
    final visibleActions = _activePlan != null
        ? scopedActions
        : _activeBodyPart == '全部'
            ? scopedActions
            : scopedActions
                .where((action) =>
                    _bodyPartLabel(action.bodyPart) == _activeBodyPart)
                .toList();
```

- [ ] **步骤 7：摘要卡使用计划范围数据**

在 `_buildWorkoutContent` 中，`_WorkoutSummaryCard` 前新增：

```dart
    final totalGroups = _totalGroupsFor(scopedActions);
    final finishedGroups = _finishedGroupsForActions(scopedActions);
    final finishedActions = _finishedActionCountFor(scopedActions);
    final nextAction = _nextActionFor(scopedActions);
```

将 `_WorkoutSummaryCard` 参数改为：

```dart
          finishedActions: finishedActions,
          totalActions: scopedActions.length,
          finishedGroups: finishedGroups,
          totalGroups: totalGroups,
          nextActionName: nextAction.name,
          onStart: () => setState(() => _activeAction = nextAction),
```

- [ ] **步骤 8：在训练列表顶部显示当前计划条**

在 `_ModuleLinkedSummaryCard` 前插入：

```dart
        if (_activePlan != null) ...[
          _ActiveWorkoutPlanBanner(
            plan: _activePlan!,
            finishedGroups: finishedGroups,
            totalGroups: totalGroups,
            onClear: () => setState(() => _activePlan = null),
          ),
          const SizedBox(height: 12),
        ],
```

新增组件：

```dart
class _ActiveWorkoutPlanBanner extends StatelessWidget {
  const _ActiveWorkoutPlanBanner({
    required this.plan,
    required this.finishedGroups,
    required this.totalGroups,
    required this.onClear,
  });

  final WorkoutPlan plan;
  final int finishedGroups;
  final int totalGroups;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in_rounded,
              color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前计划',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  plan.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$finishedGroups/$totalGroups 组',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, color: AppColors.muted),
            tooltip: '退出计划',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **步骤 9：计划模式隐藏部位筛选**

在 `_buildWorkoutContent` 中，把 `_WorkoutBodyPartFilter` 这一段改为：

```dart
        if (_activePlan == null) ...[
          _WorkoutBodyPartFilter(
            parts: _bodyParts,
            selected: _activeBodyPart,
            onChanged: (part) => setState(() => _activeBodyPart = part),
          ),
          const SizedBox(height: 14),
        ],
```

- [ ] **步骤 10：运行测试确认通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout plan opens detail and starts scoped workout"
```

预期：

- `All tests passed!`

- [ ] **步骤 11：Commit 计划训练模式**

```powershell
git add lib/modules/workout/workout_module.dart
git commit -m "feat: start scoped workout plans"
```

---

### 任务 5：回归验证和收尾

**文件：**
- 修改：无预期修改

- [ ] **步骤 1：运行锻炼页现有测试**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "workout top tabs show plan data and history"
```

预期：

- `All tests passed!`

- [ ] **步骤 2：运行模块切换测试**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "module link strip jumps between every main module"
```

预期：

- `All tests passed!`

- [ ] **步骤 3：运行静态检查**

运行：

```powershell
flutter analyze
```

预期：

- `No issues found!`

- [ ] **步骤 4：检查只包含阶段 1 相关提交**

运行：

```powershell
git log --oneline --max-count=6
git status --short
```

预期：

- 最近提交包含：
  - `test: cover workout plan start flow`
  - `feat: add workout plan model`
  - `feat: open workout plan details`
  - `feat: start scoped workout plans`
- `git status --short` 没有未提交代码改动。

- [ ] **步骤 5：最终提交说明**

本任务不需要额外 commit，除非步骤 1-4 中修复了问题。

---

## 阶段 1 完成后的行为

完成本计划后，用户能做到：

1. 打开锻炼。
2. 进入计划 tab。
3. 点击“胸背强化”等计划。
4. 看到计划详情。
5. 点击开始训练。
6. 回到训练 tab。
7. 看到“当前计划”提示和该计划内动作。

后续阶段再实现：

- 完成训练后生成历史记录。
- 数据页读取训练历史统计。
- 历史页打开真实训练详情。
- 编辑训练计划。
