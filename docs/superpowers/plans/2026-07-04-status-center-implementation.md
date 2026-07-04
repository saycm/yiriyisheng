# 状态中心实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 将当前依赖 Health Connect 的健康模块重做为不依赖外部数据的“状态中心”，并保留 Health Connect 作为可选外部数据源。

**架构：** 新增一个专注的状态评分模型文件，负责把手动状态、饮食摄入和锻炼组数转换为可解释的分数、等级、原因和建议。健康页面保留现有 `HealthModulePage` 入口，但主内容改为今日状态、快速记录、今日影响、建议和趋势；Health Connect 卡片从顶部主内容移动到底部外部数据源 Sheet。

**技术栈：** Flutter、Dart、现有 `part` 结构、Flutter widget tests、现有 `SystemHealthStore` 平台通道。

---

## 文件结构

- 创建：`lib/modules/health/health_status_center.dart`
  - 职责：定义状态输入、评分结果、影响项、建议和纯 Dart 计算逻辑。
- 修改：`lib/modules/health/health.dart`
  - 职责：把 `health_status_center.dart` 接入当前健康模块的 part 链。
- 修改：`lib/modules/health/health_module.dart`
  - 职责：替换首页主结构，接入状态评分结果，新增外部数据源入口和 Sheet 打开方法。
- 修改：`lib/modules/health/health_manual_views.dart`
  - 职责：把“身体记录”文案调整为“状态记录”，保留现有滑杆输入，补充睡眠感等可解释标签。
- 修改：`lib/modules/health/health_metric_views.dart`
  - 职责：保留 Health Connect 详情和传感器卡片，供外部数据源 Sheet 使用。
- 修改：`lib/shared/module_settings_sheet.dart`
  - 职责：把 Q&A 从“健康数据来源”改成“状态中心和外部数据源”。
- 测试：`test/health_status_center_test.dart`
  - 职责：测试状态评分和建议规则。
- 测试：`test/health_widget_test.dart`
  - 职责：测试状态中心 UI、快速记录、建议、趋势和外部数据源入口。
- 测试：`test/widget_test.dart`
  - 职责：更新仍断言 Health Connect 主路径的全局帮助文案。

## 任务 1：新增状态评分模型

**文件：**
- 创建：`lib/modules/health/health_status_center.dart`
- 修改：`lib/modules/health/health.dart`
- 测试：`test/health_status_center_test.dart`

- [ ] **步骤 1：编写失败的模型测试**

在 `test/health_status_center_test.dart` 创建测试文件：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/modules/health/health.dart';

void main() {
  test('status score rewards balanced daily state', () {
    final result = const HealthStatusCalculator().calculate(
      input: HealthStatusInput(
        sleep: HealthSleepFeeling.good,
        energy: HealthEnergyFeeling.strong,
        stress: HealthStressFeeling.low,
        body: HealthBodyFeeling.normal,
        mood: HealthMoodFeeling.calm,
        foodCalories: 1650,
        workoutGroups: 6,
      ),
    );

    expect(result.score, greaterThanOrEqualTo(85));
    expect(result.level, '状态很好');
    expect(result.primaryReason, '睡眠、精力和压力都比较稳定');
    expect(result.impacts.map((impact) => impact.title), contains('饮食'));
    expect(result.suggestions, contains('状态不错，可以安排中等强度任务或训练。'));
  });

  test('status score explains stress sleep and workout overload', () {
    final result = const HealthStatusCalculator().calculate(
      input: HealthStatusInput(
        sleep: HealthSleepFeeling.poor,
        energy: HealthEnergyFeeling.tired,
        stress: HealthStressFeeling.high,
        body: HealthBodyFeeling.neckPain,
        mood: HealthMoodFeeling.anxious,
        foodCalories: 900,
        workoutGroups: 18,
      ),
    );

    expect(result.score, lessThanOrEqualTo(54));
    expect(result.level, '负载偏高');
    expect(result.primaryReason, '睡眠感较差、压力偏高、身体有不适');
    expect(result.suggestions, contains('今天压力偏高，优先处理高价值任务，减少低优先级事项。'));
    expect(result.suggestions, contains('睡眠感较差且训练量偏高，今天更适合轻度训练或拉伸。'));
    expect(result.suggestions, contains('摄入偏低时不建议直接做高强度训练。'));
  });
}
```

- [ ] **步骤 2：运行模型测试验证失败**

运行：

```powershell
flutter test test\health_status_center_test.dart
```

预期：FAIL，报错包含 `HealthStatusCalculator` 或 `HealthStatusInput` 未定义。

- [ ] **步骤 3：实现状态模型和计算器**

创建 `lib/modules/health/health_status_center.dart`：

```dart
// 中文注释：状态中心计算层，负责把手动状态和模块联动数据转换成可解释评分。

part of 'health.dart';

enum HealthSleepFeeling { good, normal, poor }

enum HealthEnergyFeeling { strong, normal, tired }

enum HealthStressFeeling { low, medium, high }

enum HealthBodyFeeling { normal, neckPain, stomach, headache, other }

enum HealthMoodFeeling { calm, happy, anxious, low }

class HealthStatusInput {
  const HealthStatusInput({
    required this.sleep,
    required this.energy,
    required this.stress,
    required this.body,
    required this.mood,
    required this.foodCalories,
    required this.workoutGroups,
  });

  final HealthSleepFeeling sleep;
  final HealthEnergyFeeling energy;
  final HealthStressFeeling stress;
  final HealthBodyFeeling body;
  final HealthMoodFeeling mood;
  final int foodCalories;
  final int workoutGroups;
}

class HealthStatusImpact {
  const HealthStatusImpact({
    required this.title,
    required this.value,
    required this.description,
    required this.color,
  });

  final String title;
  final String value;
  final String description;
  final Color color;
}

class HealthStatusResult {
  const HealthStatusResult({
    required this.score,
    required this.level,
    required this.primaryReason,
    required this.impacts,
    required this.suggestions,
    required this.trendScores,
    required this.frequentTags,
  });

  final int score;
  final String level;
  final String primaryReason;
  final List<HealthStatusImpact> impacts;
  final List<String> suggestions;
  final List<int> trendScores;
  final List<String> frequentTags;
}

class HealthStatusCalculator {
  const HealthStatusCalculator();

  HealthStatusResult calculate({required HealthStatusInput input}) {
    final sleepScore = switch (input.sleep) {
      HealthSleepFeeling.good => 25,
      HealthSleepFeeling.normal => 18,
      HealthSleepFeeling.poor => 8,
    };
    final energyScore = switch (input.energy) {
      HealthEnergyFeeling.strong => 25,
      HealthEnergyFeeling.normal => 18,
      HealthEnergyFeeling.tired => 8,
    };
    final stressScore = switch (input.stress) {
      HealthStressFeeling.low => 20,
      HealthStressFeeling.medium => 13,
      HealthStressFeeling.high => 4,
    };
    final bodyScore =
        input.body == HealthBodyFeeling.normal ? 15 : input.body == HealthBodyFeeling.other ? 8 : 5;
    final loadScore = _loadScore(input.foodCalories, input.workoutGroups);
    final score = (sleepScore + energyScore + stressScore + bodyScore + loadScore)
        .clamp(0, 100);
    final reasons = _reasons(input);

    return HealthStatusResult(
      score: score,
      level: _level(score),
      primaryReason: reasons.isEmpty ? '睡眠、精力和压力都比较稳定' : reasons.join('、'),
      impacts: _impacts(input),
      suggestions: _suggestions(input, score),
      trendScores: _trendScores(score),
      frequentTags: _frequentTags(input),
    );
  }

  int _loadScore(int foodCalories, int workoutGroups) {
    var score = 15;
    if (foodCalories > 0 && foodCalories < 1200) {
      score -= 5;
    }
    if (foodCalories > 2400) {
      score -= 3;
    }
    if (workoutGroups >= 16) {
      score -= 6;
    } else if (workoutGroups >= 12) {
      score -= 3;
    }
    return score.clamp(0, 15);
  }

  String _level(int score) {
    if (score >= 85) {
      return '状态很好';
    }
    if (score >= 70) {
      return '状态平稳';
    }
    if (score >= 55) {
      return '稍累';
    }
    return '负载偏高';
  }

  List<String> _reasons(HealthStatusInput input) {
    final reasons = <String>[];
    if (input.sleep == HealthSleepFeeling.poor) {
      reasons.add('睡眠感较差');
    }
    if (input.energy == HealthEnergyFeeling.tired) {
      reasons.add('精力偏低');
    }
    if (input.stress == HealthStressFeeling.high) {
      reasons.add('压力偏高');
    }
    if (input.body != HealthBodyFeeling.normal) {
      reasons.add('身体有不适');
    }
    if (input.workoutGroups >= 16) {
      reasons.add('今日训练量偏高');
    }
    return reasons;
  }

  List<HealthStatusImpact> _impacts(HealthStatusInput input) {
    return [
      HealthStatusImpact(
        title: '饮食',
        value: input.foodCalories == 0 ? '未记录' : '${input.foodCalories} kcal',
        description: input.foodCalories == 0
            ? '今天还没有饮食记录'
            : input.foodCalories < 1200
                ? '摄入偏低，训练前要补能量'
                : input.foodCalories > 2400
                    ? '摄入偏高，晚间保持清淡'
                    : '摄入节奏稳定',
        color: AppColors.primary,
      ),
      HealthStatusImpact(
        title: '锻炼',
        value: '${input.workoutGroups} 组',
        description: input.workoutGroups >= 16
            ? '训练量偏高，注意恢复'
            : input.workoutGroups == 0
                ? '今天还没有训练记录'
                : '训练量可控',
        color: const Color(0xFF43C6C8),
      ),
      HealthStatusImpact(
        title: '压力',
        value: _stressLabel(input.stress),
        description: input.stress == HealthStressFeeling.high
            ? '适合减少低优先级任务'
            : '压力处于可控范围',
        color: const Color(0xFFFF7A83),
      ),
    ];
  }

  List<String> _suggestions(HealthStatusInput input, int score) {
    final suggestions = <String>[];
    if (input.stress == HealthStressFeeling.high) {
      suggestions.add('今天压力偏高，优先处理高价值任务，减少低优先级事项。');
    }
    if (input.sleep == HealthSleepFeeling.poor && input.workoutGroups >= 12) {
      suggestions.add('睡眠感较差且训练量偏高，今天更适合轻度训练或拉伸。');
    }
    if (input.foodCalories > 0 && input.foodCalories < 1200) {
      suggestions.add('摄入偏低时不建议直接做高强度训练。');
    }
    if (input.body == HealthBodyFeeling.neckPain) {
      suggestions.add('肩颈不适时，减少久坐并安排 5 分钟放松。');
    }
    if (suggestions.isEmpty && score >= 85) {
      suggestions.add('状态不错，可以安排中等强度任务或训练。');
    }
    if (suggestions.isEmpty) {
      suggestions.add('保持当前节奏，晚间做一次简短复盘。');
    }
    return suggestions.take(3).toList();
  }

  List<int> _trendScores(int score) {
    return [
      (score - 6).clamp(0, 100),
      (score - 3).clamp(0, 100),
      (score - 4).clamp(0, 100),
      (score + 1).clamp(0, 100),
      (score - 2).clamp(0, 100),
      (score + 3).clamp(0, 100),
      score,
    ];
  }

  List<String> _frequentTags(HealthStatusInput input) {
    final tags = <String>[];
    if (input.sleep == HealthSleepFeeling.poor) {
      tags.add('睡眠差');
    }
    if (input.energy == HealthEnergyFeeling.tired) {
      tags.add('疲惫');
    }
    if (input.stress == HealthStressFeeling.high) {
      tags.add('压力大');
    }
    if (input.body != HealthBodyFeeling.normal) {
      tags.add(_bodyLabel(input.body));
    }
    return tags.isEmpty ? const ['状态稳定'] : tags;
  }
}

String _sleepLabel(HealthSleepFeeling value) => switch (value) {
      HealthSleepFeeling.good => '好',
      HealthSleepFeeling.normal => '一般',
      HealthSleepFeeling.poor => '差',
    };

String _energyLabel(HealthEnergyFeeling value) => switch (value) {
      HealthEnergyFeeling.strong => '充足',
      HealthEnergyFeeling.normal => '普通',
      HealthEnergyFeeling.tired => '疲惫',
    };

String _stressLabel(HealthStressFeeling value) => switch (value) {
      HealthStressFeeling.low => '低',
      HealthStressFeeling.medium => '中',
      HealthStressFeeling.high => '高',
    };

String _bodyLabel(HealthBodyFeeling value) => switch (value) {
      HealthBodyFeeling.normal => '正常',
      HealthBodyFeeling.neckPain => '肩颈痛',
      HealthBodyFeeling.stomach => '胃不舒服',
      HealthBodyFeeling.headache => '头痛',
      HealthBodyFeeling.other => '其他',
    };

String _moodLabel(HealthMoodFeeling value) => switch (value) {
      HealthMoodFeeling.calm => '平静',
      HealthMoodFeeling.happy => '开心',
      HealthMoodFeeling.anxious => '焦虑',
      HealthMoodFeeling.low => '低落',
    };
```

修改 `lib/modules/health/health.dart`，在现有 part 列表中增加：

```dart
part 'health_status_center.dart';
```

- [ ] **步骤 4：运行模型测试验证通过**

运行：

```powershell
flutter test test\health_status_center_test.dart
```

预期：PASS，两个评分测试通过。

- [ ] **步骤 5：提交模型变更**

运行：

```powershell
git add lib\modules\health\health.dart lib\modules\health\health_status_center.dart test\health_status_center_test.dart
git commit -m "feat: add health status scoring model"
```

## 任务 2：把健康首页改成状态中心

**文件：**
- 修改：`lib/modules/health/health_module.dart`
- 测试：`test/health_widget_test.dart`

- [ ] **步骤 1：编写失败的首页测试**

在 `test/health_widget_test.dart` 新增测试：

```dart
testWidgets('health module shows status center before external data source',
    (tester) async {
  mockSystemHealthStatus(
    status: 'permissionRequired',
    message: '还没有授予步数、睡眠和心率权限。',
  );
  tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
  addTearDown(
    () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
  );

  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();

  expect(find.text('今日状态'), findsWidgets);
  expect(find.text('状态中心'), findsOneWidget);
  expect(find.byKey(const ValueKey('health_status_score_card')), findsOneWidget);
  expect(find.byKey(const ValueKey('health_quick_record_card')), findsOneWidget);
  expect(find.byKey(const ValueKey('health_external_source_entry')), findsOneWidget);

  final statusTop = tester.getTopLeft(
    find.byKey(const ValueKey('health_status_score_card')),
  ).dy;
  final externalTop = tester.getTopLeft(
    find.byKey(const ValueKey('health_external_source_entry')),
  ).dy;
  expect(statusTop, lessThan(externalTop));
  expect(find.text('Health Connect 未授权'), findsNothing);
});
```

- [ ] **步骤 2：运行首页测试验证失败**

运行：

```powershell
flutter test test\health_widget_test.dart --plain-name "health module shows status center before external data source"
```

预期：FAIL，报错找不到 `health_status_score_card`。

- [ ] **步骤 3：接入状态输入和评分结果**

在 `_HealthModulePageState` 中新增状态字段和计算属性：

```dart
  HealthSleepFeeling _sleepFeeling = HealthSleepFeeling.normal;
  HealthEnergyFeeling _energyFeeling = HealthEnergyFeeling.normal;
  HealthStressFeeling _stressFeeling = HealthStressFeeling.medium;
  HealthBodyFeeling _bodyFeeling = HealthBodyFeeling.normal;
  HealthMoodFeeling _moodFeeling = HealthMoodFeeling.calm;

  HealthStatusResult get _statusResult {
    return const HealthStatusCalculator().calculate(
      input: HealthStatusInput(
        sleep: _sleepFeeling,
        energy: _energyFeeling,
        stress: _stressFeeling,
        body: _bodyFeeling,
        mood: _moodFeeling,
        foodCalories: widget.foodCalories,
        workoutGroups: widget.workoutGroups,
      ),
    );
  }
```

保留 `_systemHealth`、`_loadSystemHealth`、`_requestSystemHealthAccess` 和 `_openSystemHealthSettings`，因为外部数据源 Sheet 仍需要。

- [ ] **步骤 4：替换 ListView 主内容顺序**

在 `HealthModulePage.build` 的 `ListView` children 中，用以下主结构替换原来的系统状态卡、圆环卡和指标网格：

```dart
                      _HealthDateStrip(
                        days: days,
                        selectedDay: selectedDay,
                        onSelect: (day) {
                          setState(() => _selectedIndex = days.indexOf(day));
                        },
                      ),
                      const SizedBox(height: 16),
                      _HealthStatusScoreCard(
                        result: _statusResult,
                        onRecord: _openManualRecordSheet,
                      ),
                      const SizedBox(height: 14),
                      _HealthQuickRecordCard(
                        sleep: _sleepFeeling,
                        energy: _energyFeeling,
                        stress: _stressFeeling,
                        body: _bodyFeeling,
                        mood: _moodFeeling,
                        onSleepChanged: (value) => setState(() => _sleepFeeling = value),
                        onEnergyChanged: (value) => setState(() => _energyFeeling = value),
                        onStressChanged: (value) => setState(() => _stressFeeling = value),
                        onBodyChanged: (value) => setState(() => _bodyFeeling = value),
                        onMoodChanged: (value) => setState(() => _moodFeeling = value),
                      ),
                      const SizedBox(height: 14),
                      _HealthImpactCard(impacts: _statusResult.impacts),
                      const SizedBox(height: 14),
                      _HealthStatusSuggestionCard(
                        suggestions: _statusResult.suggestions,
                      ),
                      const SizedBox(height: 14),
                      _HealthStatusTrendCard(result: _statusResult),
                      const SizedBox(height: 14),
                      _HealthExternalSourceEntry(
                        snapshot: _systemHealth,
                        loading: _loadingHealth,
                        onTap: _openExternalSourceSheet,
                      ),
```

删除首页中直接显示的 `_HealthSystemStatusCard`、`_HealthRingsCard`、`GridView.count` 和 `_HealthSensorCard`。这些组件先保留在文件中，供外部数据源 Sheet 或指标详情使用。

- [ ] **步骤 5：新增状态中心卡片组件**

在 `health_module.dart` 的 `_HealthDateStrip` 前新增以下组件：

```dart
class _HealthStatusScoreCard extends StatelessWidget {
  const _HealthStatusScoreCard({
    required this.result,
    required this.onRecord,
  });

  final HealthStatusResult result;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('health_status_score_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              result.score.toString(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '今日状态',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  result.level,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  result.primaryReason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: onRecord,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(92, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '记录状态',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
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

同文件新增 `_HealthImpactCard`、`_HealthStatusSuggestionCard`、`_HealthStatusTrendCard` 和 `_HealthExternalSourceEntry`。实现时沿用 `AppColors.surface`、8px 圆角和现有字体权重，分别使用 key：

```dart
const ValueKey('health_impact_card')
const ValueKey('health_status_suggestion_card')
const ValueKey('health_status_trend_card')
const ValueKey('health_external_source_entry')
```

- [ ] **步骤 6：运行首页测试验证通过**

运行：

```powershell
flutter test test\health_widget_test.dart --plain-name "health module shows status center before external data source"
```

预期：PASS。

- [ ] **步骤 7：提交首页结构变更**

运行：

```powershell
git add lib\modules\health\health_module.dart test\health_widget_test.dart
git commit -m "feat: make health page a status center"
```

## 任务 3：完善快速记录和状态记录弹层

**文件：**
- 修改：`lib/modules/health/health_module.dart`
- 修改：`lib/modules/health/health_manual_views.dart`
- 测试：`test/health_widget_test.dart`

- [ ] **步骤 1：编写失败的快速记录测试**

在 `test/health_widget_test.dart` 新增测试：

```dart
testWidgets('quick status record updates score and suggestions', (tester) async {
  mockSystemHealthStatus(
    status: 'permissionRequired',
    message: '还没有授予步数、睡眠和心率权限。',
  );
  tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
  addTearDown(
    () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
  );

  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('health_quick_sleep_poor')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('health_quick_stress_high')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('health_quick_body_neckPain')));
  await tester.pumpAndSettle();

  expect(find.text('负载偏高'), findsWidgets);
  expect(find.textContaining('压力偏高'), findsWidgets);
  expect(find.textContaining('肩颈不适'), findsWidgets);
});
```

- [ ] **步骤 2：运行快速记录测试验证失败**

运行：

```powershell
flutter test test\health_widget_test.dart --plain-name "quick status record updates score and suggestions"
```

预期：FAIL，报错找不到 `health_quick_sleep_poor`。

- [ ] **步骤 3：实现快速记录卡片**

在 `health_module.dart` 新增 `_HealthQuickRecordCard` 和 `_HealthChoiceChip`：

```dart
class _HealthQuickRecordCard extends StatelessWidget {
  const _HealthQuickRecordCard({
    required this.sleep,
    required this.energy,
    required this.stress,
    required this.body,
    required this.mood,
    required this.onSleepChanged,
    required this.onEnergyChanged,
    required this.onStressChanged,
    required this.onBodyChanged,
    required this.onMoodChanged,
  });

  final HealthSleepFeeling sleep;
  final HealthEnergyFeeling energy;
  final HealthStressFeeling stress;
  final HealthBodyFeeling body;
  final HealthMoodFeeling mood;
  final ValueChanged<HealthSleepFeeling> onSleepChanged;
  final ValueChanged<HealthEnergyFeeling> onEnergyChanged;
  final ValueChanged<HealthStressFeeling> onStressChanged;
  final ValueChanged<HealthBodyFeeling> onBodyChanged;
  final ValueChanged<HealthMoodFeeling> onMoodChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('health_quick_record_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快速记录',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _HealthChoiceRow<HealthSleepFeeling>(
            title: '睡眠感',
            value: sleep,
            values: HealthSleepFeeling.values,
            keyPrefix: 'health_quick_sleep',
            labelBuilder: _sleepLabel,
            onChanged: onSleepChanged,
          ),
          _HealthChoiceRow<HealthEnergyFeeling>(
            title: '精力',
            value: energy,
            values: HealthEnergyFeeling.values,
            keyPrefix: 'health_quick_energy',
            labelBuilder: _energyLabel,
            onChanged: onEnergyChanged,
          ),
          _HealthChoiceRow<HealthStressFeeling>(
            title: '压力',
            value: stress,
            values: HealthStressFeeling.values,
            keyPrefix: 'health_quick_stress',
            labelBuilder: _stressLabel,
            onChanged: onStressChanged,
          ),
          _HealthChoiceRow<HealthBodyFeeling>(
            title: '身体',
            value: body,
            values: HealthBodyFeeling.values,
            keyPrefix: 'health_quick_body',
            labelBuilder: _bodyLabel,
            onChanged: onBodyChanged,
          ),
          _HealthChoiceRow<HealthMoodFeeling>(
            title: '心情',
            value: mood,
            values: HealthMoodFeeling.values,
            keyPrefix: 'health_quick_mood',
            labelBuilder: _moodLabel,
            onChanged: onMoodChanged,
          ),
        ],
      ),
    );
  }
}
```

`_HealthChoiceRow` 使用 `Wrap` 展示选项，每个选项 key 按 `$keyPrefix_${value.name}` 生成，选中时使用 `AppColors.primarySoft` 背景，未选中使用 `AppColors.background`。

- [ ] **步骤 4：同步弹层文案和保存回填**

修改 `_HealthManualRecordSheet` 标题：

```dart
return InfoSheetFrame(
  title: '状态记录',
```

修改 `_HealthManualStatusCard` 标题：

```dart
const Text(
  '状态记录',
```

在 `_openManualRecordSheet` 的 `onSave` 中，同步旧字段到新枚举：

```dart
            _energyFeeling = record.energyLevel >= 4
                ? HealthEnergyFeeling.strong
                : record.energyLevel <= 2
                    ? HealthEnergyFeeling.tired
                    : HealthEnergyFeeling.normal;
            _stressFeeling = record.stressLevel >= 4
                ? HealthStressFeeling.high
                : record.stressLevel <= 2
                    ? HealthStressFeeling.low
                    : HealthStressFeeling.medium;
            _bodyFeeling = record.bodyTag == '疲惫'
                ? HealthBodyFeeling.other
                : record.bodyTag == '压力大'
                    ? HealthBodyFeeling.other
                    : record.bodyTag == '睡眠差'
                        ? HealthBodyFeeling.normal
                        : HealthBodyFeeling.normal;
```

- [ ] **步骤 5：运行快速记录测试验证通过**

运行：

```powershell
flutter test test\health_widget_test.dart --plain-name "quick status record updates score and suggestions"
```

预期：PASS。

- [ ] **步骤 6：提交快速记录变更**

运行：

```powershell
git add lib\modules\health\health_module.dart lib\modules\health\health_manual_views.dart test\health_widget_test.dart
git commit -m "feat: add quick status records"
```

## 任务 4：外部数据源 Sheet

**文件：**
- 修改：`lib/modules/health/health_module.dart`
- 修改：`lib/modules/health/health_metric_views.dart`
- 测试：`test/health_widget_test.dart`

- [ ] **步骤 1：编写失败的外部数据源测试**

替换原测试 `health connect status explains setup and empty data states` 的断言重点，新测试如下：

```dart
testWidgets('external data source explains health connect as optional',
    (tester) async {
  mockSystemHealthStatus(
    status: 'permissionRequired',
    message: '还没有授予步数、睡眠和心率权限。',
  );
  tester.binding.platformDispatcher.defaultRouteNameTestValue = '/health';
  addTearDown(
    () => tester.binding.platformDispatcher.defaultRouteNameTestValue = '/',
  );

  await tester.pumpWidget(const PingShengApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('health_external_source_entry')));
  await tester.pumpAndSettle();

  expect(find.text('外部数据源'), findsOneWidget);
  expect(find.text('Health Connect 未授权'), findsOneWidget);
  expect(find.textContaining('可选数据源'), findsOneWidget);
  expect(find.text('去授权'), findsOneWidget);
});
```

- [ ] **步骤 2：运行外部数据源测试验证失败**

运行：

```powershell
flutter test test\health_widget_test.dart --plain-name "external data source explains health connect as optional"
```

预期：FAIL，点击入口后没有 `外部数据源` Sheet。

- [ ] **步骤 3：实现打开外部数据源 Sheet**

在 `_HealthModulePageState` 新增方法：

```dart
  void _openExternalSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthExternalSourceSheet(
        snapshot: _systemHealth,
        loading: _loadingHealth,
        onRefresh: _loadSystemHealth,
        onRequestPermission: _requestSystemHealthAccess,
        onOpenSettings: _openSystemHealthSettings,
      ),
    );
  }
```

在 `health_module.dart` 新增 `_HealthExternalSourceSheet`：

```dart
class _HealthExternalSourceSheet extends StatelessWidget {
  const _HealthExternalSourceSheet({
    required this.snapshot,
    required this.loading,
    required this.onRefresh,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final HealthSystemSnapshot snapshot;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '外部数据源',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EmptyCard(
            title: 'Health Connect 是可选数据源',
            subtitle: '没有授权或设备不支持时，状态中心仍然可以通过手动记录、饮食和锻炼数据正常使用。',
          ),
          const SizedBox(height: 12),
          _HealthSystemStatusCard(
            snapshot: snapshot,
            loading: loading,
            onRefresh: onRefresh,
            onRequestPermission: onRequestPermission,
            onOpenSettings: onOpenSettings,
          ),
          const SizedBox(height: 12),
          _HealthSensorCard(snapshot: snapshot.sensors),
        ],
      ),
    );
  }
}
```

- [ ] **步骤 4：调整 `_HealthSystemStatusCard` 文案**

在 `_HealthConnectionState.fromSnapshot` 相关逻辑中保留原标题，但把 subtitle 或 `snapshot.message` 附近显示的说明加上“可选数据源”语义。标题仍为：

```dart
Health Connect 未授权
需要安装 Health Connect
需要更新 Health Connect
Health Connect 已连接，暂无数据
系统健康数据已连接
```

新增说明文本：

```dart
const Text(
  '这是可选数据源，不影响状态中心使用。',
  style: TextStyle(
    color: AppColors.muted,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  ),
)
```

- [ ] **步骤 5：运行外部数据源测试验证通过**

运行：

```powershell
flutter test test\health_widget_test.dart --plain-name "external data source explains health connect as optional"
```

预期：PASS。

- [ ] **步骤 6：提交外部数据源变更**

运行：

```powershell
git add lib\modules\health\health_module.dart lib\modules\health\health_metric_views.dart test\health_widget_test.dart
git commit -m "feat: move health connect into external data source"
```

## 任务 5：更新设置和帮助文案

**文件：**
- 修改：`lib/shared/module_settings_sheet.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的设置文案测试**

在 `test/widget_test.dart` 中找到设置 Q&A 测试，把健康相关断言改为：

```dart
expect(find.text('状态中心的数据从哪里来？'), findsOneWidget);
await tester.tap(find.text('状态中心的数据从哪里来？'));
await tester.pumpAndSettle();
expect(find.textContaining('手动状态记录'), findsWidgets);
expect(find.textContaining('Health Connect 是可选数据源'), findsWidgets);
```

- [ ] **步骤 2：运行设置测试验证失败**

运行：

```powershell
flutter test test\widget_test.dart --plain-name "settings"
```

预期：FAIL，找不到 `状态中心的数据从哪里来？`。

- [ ] **步骤 3：更新 Q&A 条目**

在 `_QaSheet` 的 `items` 替换健康相关条目：

```dart
const items = [
  (
    '状态中心的数据从哪里来？',
    '状态中心优先使用手动状态记录，并结合饮食摄入、锻炼组数和计划信息生成今日状态。Health Connect 是可选数据源，没有授权也不影响使用。'
  ),
  ('为什么不再默认显示步数和心率？', '大多数设备不会默认配置 Health Connect。状态中心先保证没有外部权限也能记录和回溯，步数、心率和睡眠会放在外部数据源里作为参考。'),
  (
    '怎样开启真实系统健康数据？',
    '进入状态页底部的外部数据源，按系统提示允许 Health Connect 读取步数、能量、睡眠、心率和呼吸数据，再回到 App 刷新。'
  ),
  ('桌面小组件的状态摘要如何更新？', 'App 会优先展示今日状态记录和模块联动摘要；有系统健康数据时，再补充外部数据源参考。'),
  (
    '数据会上传吗？',
    '当前实现只在本机展示状态记录和系统健康参考数据，不接入服务器上传。你可以随时在系统 Health Connect 权限里关闭访问。'
  ),
];
```

把设置入口 subtitle 改为：

```dart
subtitle: '状态中心、外部数据源、小组件常见问题',
```

- [ ] **步骤 4：运行设置测试验证通过**

运行：

```powershell
flutter test test\widget_test.dart --plain-name "settings"
```

预期：PASS。

- [ ] **步骤 5：提交设置文案变更**

运行：

```powershell
git add lib\shared\module_settings_sheet.dart test\widget_test.dart
git commit -m "docs: update status center help copy"
```

## 任务 6：全量健康模块回归和清理

**文件：**
- 修改：`test/health_widget_test.dart`
- 修改：`lib/modules/health/health_module.dart`
- 修改：`lib/modules/health/health_metric_views.dart`

- [ ] **步骤 1：更新旧测试名称和断言**

把 `health date switch opens metric detail and summary` 改名为：

```dart
testWidgets('status center opens summary and external metric details',
```

调整测试流程：

1. 先断言首页有 `状态中心`、`今日状态`、`外部数据源`。
2. 点击顶部更多按钮后，仍能打开摘要 Sheet。
3. 点击 `health_external_source_entry` 打开外部数据源 Sheet。
4. 在 Sheet 中断言 `系统健康数据已连接`。
5. 关闭 Sheet。

保留对 `健康总览`、`饮食摄入`、`锻炼完成` 的断言，删掉首页直接查找 `今日步数` 的断言。

- [ ] **步骤 2：运行健康测试验证失败或通过**

运行：

```powershell
flutter test test\health_widget_test.dart
```

预期：如果有旧断言仍找首页系统指标则 FAIL；根据失败行删除或改到外部数据源 Sheet 内验证。

- [ ] **步骤 3：清理未使用代码**

运行：

```powershell
flutter analyze
```

预期：如果出现未使用的 `_openMetricSheet`、`_HealthMetricCard`、`_HealthRingsCard` 或 painter 警告，只删除首页已不再引用且外部数据源 Sheet 也不需要的私有 widget。保留 `_HealthSystemStatusCard` 和 `_HealthSensorCard`。

- [ ] **步骤 4：运行回归测试**

运行：

```powershell
flutter test test\health_status_center_test.dart test\health_widget_test.dart test\widget_test.dart
```

预期：PASS。

- [ ] **步骤 5：运行全项目分析**

运行：

```powershell
flutter analyze
```

预期：`No issues found!`

- [ ] **步骤 6：提交回归清理**

运行：

```powershell
git add lib\modules\health test\health_widget_test.dart test\widget_test.dart
git commit -m "test: update status center regressions"
```

## 任务 7：最终验证

**文件：**
- 不新增文件

- [ ] **步骤 1：检查工作区**

运行：

```powershell
git status --short
```

预期：只剩与其他历史任务有关的既有改动；本计划涉及的文件已全部提交。

- [ ] **步骤 2：运行核心测试**

运行：

```powershell
flutter test test\health_status_center_test.dart test\health_widget_test.dart test\widget_test.dart test\source_structure_test.dart
```

预期：PASS。

- [ ] **步骤 3：运行分析**

运行：

```powershell
flutter analyze
```

预期：`No issues found!`

- [ ] **步骤 4：记录结果**

在最终回复中说明：

```text
已完成健康模块到状态中心的重做。
验证：
- flutter test test\health_status_center_test.dart test\health_widget_test.dart test\widget_test.dart test\source_structure_test.dart
- flutter analyze
```

如果验证失败，先修复失败项，再重新执行本任务步骤 2 和步骤 3。
