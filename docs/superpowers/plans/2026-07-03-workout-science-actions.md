# 锻炼科学动作库扩容实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 按科学训练原则扩容锻炼动作库，并重组默认训练模板，让动作和计划覆盖主要运动模式。

**架构：** 保留现有 `WorkoutAction` 数据模型和锻炼模块页面结构，只更新动作数据、默认计划和测试断言。新增图片资源继续放在 `assets/workout/actions/`，由现有 `Image.asset` 渲染逻辑加载。

**技术栈：** Flutter、Dart、现有 widget tests、PNG 图片资源、PowerShell 验证命令。

---

## 文件结构

- 修改：`test/workout_widget_test.dart`
  - 职责：锁定新增动作数量、分类筛选数量、默认计划详情、快练计划完成流程。
- 修改：`lib/modules/workout/workout_module.dart`
  - 职责：在 `_actions` 常量列表中添加科学动作库条目。
- 修改：`lib/modules/workout/workout_models.dart`
  - 职责：更新 `createDefaultWorkoutPlans()` 的默认计划动作组合。
- 创建：`assets/workout/actions/*.png`
  - 职责：为新增动作提供真实动作姿态图片。

不修改：

- `WorkoutAction` 模型字段。
- 锻炼模块 UI 布局。
- 存储结构。
- 其他模块。

## 新增动作和资源命名

新增 42 个动作。每类从 7 个动作扩到 14 个动作，总动作数从 42 变为 84。

| 分类 | 新增动作 | 图片文件 |
| --- | --- | --- |
| 胸背 | 上斜俯卧撑 | `chest_incline_push_up.png` |
| 胸背 | 哑铃地板卧推 | `chest_dumbbell_floor_press.png` |
| 胸背 | 反向划船 | `chest_inverted_row.png` |
| 胸背 | 直臂下拉 | `chest_straight_arm_pulldown.png` |
| 胸背 | 弹力带拉开 | `chest_band_pull_apart.png` |
| 胸背 | 俯卧 Y-T-W | `chest_prone_ytw.png` |
| 胸背 | 肩胛俯卧撑 | `chest_scapular_push_up.png` |
| 肩颈 | 墙滑 | `shoulder_wall_slide.png` |
| 肩颈 | 墙天使 | `shoulder_wall_angel.png` |
| 肩颈 | 弹力带外展拉开 | `shoulder_band_pull_apart.png` |
| 肩颈 | 下巴回收 | `shoulder_chin_tuck.png` |
| 肩颈 | 肩胛绕环 | `shoulder_scapular_circle.png` |
| 肩颈 | 俯身 Y 字上举 | `shoulder_prone_y_raise.png` |
| 肩颈 | 轻重量阿诺德推举 | `shoulder_light_arnold_press.png` |
| 核心 | 鸟狗 | `core_bird_dog.png` |
| 核心 | Pallof 抗旋转推 | `core_pallof_press.png` |
| 核心 | 平板触肩 | `core_plank_shoulder_tap.png` |
| 核心 | Hollow Hold | `core_hollow_hold.png` |
| 核心 | 半跪姿砍木 | `core_half_kneeling_wood_chop.png` |
| 核心 | 单侧农夫走 | `core_suitcase_carry.png` |
| 核心 | 反向卷腹 | `core_reverse_crunch.png` |
| 腿臀 | 高脚杯深蹲 | `legs_goblet_squat.png` |
| 腿臀 | 箱式深蹲 | `legs_box_squat.png` |
| 腿臀 | 侧弓步 | `legs_lateral_lunge.png` |
| 腿臀 | 腿弯举 | `legs_hamstring_curl.png` |
| 腿臀 | 站姿提踵 | `legs_standing_calf_raise.png` |
| 腿臀 | 弹力带侧走 | `legs_band_lateral_walk.png` |
| 腿臀 | 蚌式开合 | `legs_clamshell.png` |
| 有氧 | 坡度快走 | `cardio_incline_walk.png` |
| 有氧 | 低冲击开合步 | `cardio_low_impact_step_jack.png` |
| 有氧 | 空气单车间歇 | `cardio_air_bike_intervals.png` |
| 有氧 | 战绳 | `cardio_battle_rope.png` |
| 有氧 | 雪橇推 | `cardio_sled_push.png` |
| 有氧 | 原地高抬腿低冲击版 | `cardio_low_impact_high_knees.png` |
| 有氧 | 农夫行走 | `cardio_farmer_carry.png` |
| 拉伸 | 胸椎旋转 | `stretch_thoracic_rotation.png` |
| 拉伸 | 沙发拉伸 | `stretch_couch_stretch.png` |
| 拉伸 | 踝关节前移活动 | `stretch_ankle_dorsiflexion.png` |
| 拉伸 | 90/90 髋旋转 | `stretch_9090_hip_rotation.png` |
| 拉伸 | 背阔肌拉伸 | `stretch_lat_stretch.png` |
| 拉伸 | 梨状肌拉伸 | `stretch_piriformis_stretch.png` |
| 拉伸 | 肩后侧拉伸 | `stretch_posterior_shoulder_stretch.png` |

新增动作组数合计 124 组。现有总组数 133 组，新增后总组数为 257 组。

---

### 任务 1：写测试锁定动作库扩容

**文件：**
- 修改：`test/workout_widget_test.dart`

- [ ] **步骤 1：修改动作库数量和筛选测试**

在 `workout action library renders generated art and filters by body part` 测试中，把总数和分类数量改成新增后的预期，并加入代表性新增动作断言。

```dart
expect(find.text('84 个动作'), findsOneWidget);
expect(
  find.byKey(const ValueKey('workout_action_art_蝴蝶机夹胸')),
  findsOneWidget,
);
expect(find.text('上斜俯卧撑'), findsOneWidget);

await tester.tap(find.byKey(const ValueKey('workout_body_part_肩颈')));
await tester.pumpAndSettle();
expect(find.text('14 个动作'), findsOneWidget);
expect(find.text('哑铃侧平举'), findsOneWidget);
expect(find.text('墙滑'), findsOneWidget);

await tester.tap(find.byKey(const ValueKey('workout_body_part_有氧')));
await tester.pumpAndSettle();
expect(find.text('14 个动作'), findsOneWidget);
expect(find.text('跑步机慢跑'), findsOneWidget);
expect(find.text('坡度快走'), findsOneWidget);

await tester.tap(find.byKey(const ValueKey('workout_body_part_拉伸')));
await tester.pumpAndSettle();
expect(find.text('14 个动作'), findsOneWidget);
expect(find.text('站姿股四头肌拉伸'), findsOneWidget);
expect(find.text('胸椎旋转'), findsOneWidget);
```

- [ ] **步骤 2：修改总组数测试**

在 `workout finished set updates list summary and data` 测试中，把总组数断言从 133 改为 257。

```dart
expect(find.text('0/257 组'), findsOneWidget);
expect(find.text('0/4 组 ›'), findsWidgets);

// 完成一组后
expect(find.text('1/257 组'), findsOneWidget);
expect(find.text('1/4 组 ›'), findsOneWidget);
```

- [ ] **步骤 3：运行测试验证失败**

运行：

```powershell
flutter test test\workout_widget_test.dart
```

预期：FAIL，错误包含找不到 `84 个动作`、`14 个动作`、`上斜俯卧撑` 或 `0/257 组`。

---

### 任务 2：添加胸背、肩颈、核心动作

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/workout_widget_test.dart`

- [ ] **步骤 1：在胸背现有 7 个动作后追加 7 个动作**

在 `_actions` 的胸背动作块末尾、肩颈动作块之前插入：

```dart
WorkoutAction(
    name: '上斜俯卧撑',
    detail: '3组 × 10-15次',
    imageAsset: 'assets/workout/actions/chest_incline_push_up.png',
    icon: Icons.sports_gymnastics_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '胸背',
    reps: '10-15次',
    note: '身体保持直线，手掌推离支撑面。'),
WorkoutAction(
    name: '哑铃地板卧推',
    detail: '3组 × 10-12次 × 12kg',
    imageAsset: 'assets/workout/actions/chest_dumbbell_floor_press.png',
    icon: Icons.fitness_center_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '胸背',
    reps: '10-12次',
    weight: '12kg',
    note: '上臂触地后平稳推起，肩胛保持稳定。'),
WorkoutAction(
    name: '反向划船',
    detail: '3组 × 8-12次',
    imageAsset: 'assets/workout/actions/chest_inverted_row.png',
    icon: Icons.rowing_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '胸背',
    reps: '8-12次',
    note: '胸口拉向横杆，身体保持一条直线。'),
WorkoutAction(
    name: '直臂下拉',
    detail: '3组 × 12-15次 × 15kg',
    imageAsset: 'assets/workout/actions/chest_straight_arm_pulldown.png',
    icon: Icons.fitness_center_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '胸背',
    reps: '12-15次',
    weight: '15kg',
    note: '手臂微屈固定，用背阔肌带动下压。'),
WorkoutAction(
    name: '弹力带拉开',
    detail: '3组 × 15次',
    imageAsset: 'assets/workout/actions/chest_band_pull_apart.png',
    icon: Icons.accessibility_new_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '胸背',
    reps: '15次',
    note: '肩膀下沉，向两侧拉开弹力带。'),
WorkoutAction(
    name: '俯卧 Y-T-W',
    detail: '3组 × 8次',
    imageAsset: 'assets/workout/actions/chest_prone_ytw.png',
    icon: Icons.self_improvement_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '胸背',
    reps: '8次',
    note: '按 Y、T、W 三个姿态轻抬手臂，避免耸肩。'),
WorkoutAction(
    name: '肩胛俯卧撑',
    detail: '3组 × 10-12次',
    imageAsset: 'assets/workout/actions/chest_scapular_push_up.png',
    icon: Icons.sports_gymnastics_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '胸背',
    reps: '10-12次',
    note: '手肘伸直，只做肩胛前伸和后收。'),
```

- [ ] **步骤 2：在肩颈现有 7 个动作后追加 7 个动作**

在肩颈动作块末尾、核心动作块之前插入：

```dart
WorkoutAction(
    name: '墙滑',
    detail: '3组 × 10次',
    imageAsset: 'assets/workout/actions/shoulder_wall_slide.png',
    icon: Icons.accessibility_new_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '肩颈',
    reps: '10次',
    note: '背部贴墙，手臂沿墙面缓慢上滑。'),
WorkoutAction(
    name: '墙天使',
    detail: '3组 × 8次',
    imageAsset: 'assets/workout/actions/shoulder_wall_angel.png',
    icon: Icons.self_improvement_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '肩颈',
    reps: '8次',
    note: '肋骨下收，手臂贴墙画弧。'),
WorkoutAction(
    name: '弹力带外展拉开',
    detail: '3组 × 15次',
    imageAsset: 'assets/workout/actions/shoulder_band_pull_apart.png',
    icon: Icons.accessibility_new_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '肩颈',
    reps: '15次',
    note: '手臂与肩同高，感受肩后侧发力。'),
WorkoutAction(
    name: '下巴回收',
    detail: '2组 × 10次',
    imageAsset: 'assets/workout/actions/shoulder_chin_tuck.png',
    icon: Icons.self_improvement_rounded,
    groups: 2,
    status: '未开始',
    bodyPart: '肩颈',
    reps: '10次',
    note: '头部水平后移，避免低头或仰头。'),
WorkoutAction(
    name: '肩胛绕环',
    detail: '2组 × 8次/方向',
    imageAsset: 'assets/workout/actions/shoulder_scapular_circle.png',
    icon: Icons.rotate_right_rounded,
    groups: 2,
    status: '未开始',
    bodyPart: '肩颈',
    reps: '8次/方向',
    note: '动作小而慢，保持颈部放松。'),
WorkoutAction(
    name: '俯身 Y 字上举',
    detail: '3组 × 10次',
    imageAsset: 'assets/workout/actions/shoulder_prone_y_raise.png',
    icon: Icons.sports_gymnastics_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '肩颈',
    reps: '10次',
    note: '拇指朝上，手臂呈 Y 字轻抬。'),
WorkoutAction(
    name: '轻重量阿诺德推举',
    detail: '3组 × 10次 × 6kg',
    imageAsset: 'assets/workout/actions/shoulder_light_arnold_press.png',
    icon: Icons.fitness_center_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '肩颈',
    reps: '10次',
    weight: '6kg',
    note: '轻重量控制旋转，肩部不适时停止。'),
```

- [ ] **步骤 3：在核心现有 7 个动作后追加 7 个动作**

在核心动作块末尾、腿臀动作块之前插入：

```dart
WorkoutAction(
    name: '鸟狗',
    detail: '3组 × 10次/侧',
    imageAsset: 'assets/workout/actions/core_bird_dog.png',
    icon: Icons.self_improvement_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '核心',
    reps: '10次/侧',
    note: '对侧手脚伸直，骨盆保持稳定。'),
WorkoutAction(
    name: 'Pallof 抗旋转推',
    detail: '3组 × 10次/侧 × 10kg',
    imageAsset: 'assets/workout/actions/core_pallof_press.png',
    icon: Icons.fitness_center_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '核心',
    reps: '10次/侧',
    weight: '10kg',
    note: '绳索在身体侧方，推出时躯干不被拉转。'),
WorkoutAction(
    name: '平板触肩',
    detail: '3组 × 20次',
    imageAsset: 'assets/workout/actions/core_plank_shoulder_tap.png',
    icon: Icons.self_improvement_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '核心',
    reps: '20次',
    note: '左右交替触肩，髋部尽量不晃动。'),
WorkoutAction(
    name: 'Hollow Hold',
    detail: '3组 × 20-30s',
    imageAsset: 'assets/workout/actions/core_hollow_hold.png',
    icon: Icons.accessibility_new_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '核心',
    reps: '20-30s',
    note: '腰背贴地，肋骨下收，保持稳定呼吸。'),
WorkoutAction(
    name: '半跪姿砍木',
    detail: '3组 × 10次/侧 × 10kg',
    imageAsset: 'assets/workout/actions/core_half_kneeling_wood_chop.png',
    icon: Icons.rotate_right_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '核心',
    reps: '10次/侧',
    weight: '10kg',
    note: '半跪稳定骨盆，躯干带动绳索斜向移动。'),
WorkoutAction(
    name: '单侧农夫走',
    detail: '3组 × 30m/侧 × 16kg',
    imageAsset: 'assets/workout/actions/core_suitcase_carry.png',
    icon: Icons.directions_walk_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '核心',
    reps: '30m/侧',
    weight: '16kg',
    note: '单手持重行走，身体不要向一侧倾斜。'),
WorkoutAction(
    name: '反向卷腹',
    detail: '3组 × 12次',
    imageAsset: 'assets/workout/actions/core_reverse_crunch.png',
    icon: Icons.sports_gymnastics_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '核心',
    reps: '12次',
    note: '卷起骨盆而不是甩腿，回落要慢。'),
```

- [ ] **步骤 4：运行局部测试验证仍有预期失败**

运行：

```powershell
flutter test test\workout_widget_test.dart
```

预期：FAIL，剩余失败集中在腿臀、有氧、拉伸新增动作缺失、总组数未到 257，或默认计划尚未更新。

---

### 任务 3：添加腿臀、有氧、拉伸动作

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 测试：`test/workout_widget_test.dart`

- [ ] **步骤 1：在腿臀现有 7 个动作后追加 7 个动作**

在腿臀动作块末尾、有氧动作块之前插入：

```dart
WorkoutAction(
    name: '高脚杯深蹲',
    detail: '4组 × 10次 × 16kg',
    imageAsset: 'assets/workout/actions/legs_goblet_squat.png',
    icon: Icons.fitness_center_rounded,
    groups: 4,
    status: '未开始',
    bodyPart: '腿臀',
    reps: '10次',
    weight: '16kg',
    note: '哑铃贴近胸前，膝盖方向跟脚尖一致。'),
WorkoutAction(
    name: '箱式深蹲',
    detail: '3组 × 8-10次',
    imageAsset: 'assets/workout/actions/legs_box_squat.png',
    icon: Icons.chair_alt_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '腿臀',
    reps: '8-10次',
    note: '臀部轻触箱面后起身，保持脚掌踩稳。'),
WorkoutAction(
    name: '侧弓步',
    detail: '3组 × 10次/侧',
    imageAsset: 'assets/workout/actions/legs_lateral_lunge.png',
    icon: Icons.sports_gymnastics_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '腿臀',
    reps: '10次/侧',
    note: '一侧屈膝下蹲，另一侧腿伸直，髋部向后坐。'),
WorkoutAction(
    name: '腿弯举',
    detail: '3组 × 12次 × 25kg',
    imageAsset: 'assets/workout/actions/legs_hamstring_curl.png',
    icon: Icons.fitness_center_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '腿臀',
    reps: '12次',
    weight: '25kg',
    note: '顶峰收紧腘绳肌，回放时控制速度。'),
WorkoutAction(
    name: '站姿提踵',
    detail: '3组 × 15次',
    imageAsset: 'assets/workout/actions/legs_standing_calf_raise.png',
    icon: Icons.accessibility_new_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '腿臀',
    reps: '15次',
    note: '脚跟抬高后停顿半秒，再缓慢下放。'),
WorkoutAction(
    name: '弹力带侧走',
    detail: '3组 × 12步/侧',
    imageAsset: 'assets/workout/actions/legs_band_lateral_walk.png',
    icon: Icons.directions_walk_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '腿臀',
    reps: '12步/侧',
    note: '膝盖微屈，保持弹力带张力。'),
WorkoutAction(
    name: '蚌式开合',
    detail: '3组 × 15次/侧',
    imageAsset: 'assets/workout/actions/legs_clamshell.png',
    icon: Icons.self_improvement_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '腿臀',
    reps: '15次/侧',
    note: '侧卧屈膝，骨盆不后滚，只打开上侧膝盖。'),
```

- [ ] **步骤 2：在有氧现有 7 个动作后追加 7 个动作**

在有氧动作块末尾、拉伸动作块之前插入：

```dart
WorkoutAction(
    name: '坡度快走',
    detail: '3组 × 8min',
    imageAsset: 'assets/workout/actions/cardio_incline_walk.png',
    icon: Icons.directions_walk_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '有氧',
    reps: '8min',
    note: '坡度中等，保持能说短句的呼吸强度。'),
WorkoutAction(
    name: '低冲击开合步',
    detail: '3组 × 45s',
    imageAsset: 'assets/workout/actions/cardio_low_impact_step_jack.png',
    icon: Icons.sports_gymnastics_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '有氧',
    reps: '45s',
    note: '左右侧点代替跳跃，手臂同步打开。'),
WorkoutAction(
    name: '空气单车间歇',
    detail: '6组 × 30s',
    imageAsset: 'assets/workout/actions/cardio_air_bike_intervals.png',
    icon: Icons.pedal_bike_rounded,
    groups: 6,
    status: '未开始',
    bodyPart: '有氧',
    reps: '30s',
    note: '冲刺和恢复交替，保持躯干稳定。'),
WorkoutAction(
    name: '战绳',
    detail: '4组 × 30s',
    imageAsset: 'assets/workout/actions/cardio_battle_rope.png',
    icon: Icons.bolt_rounded,
    groups: 4,
    status: '未开始',
    bodyPart: '有氧',
    reps: '30s',
    note: '膝盖微屈，肩膀放松，双臂快速甩绳。'),
WorkoutAction(
    name: '雪橇推',
    detail: '4组 × 20m',
    imageAsset: 'assets/workout/actions/cardio_sled_push.png',
    icon: Icons.directions_run_rounded,
    groups: 4,
    status: '未开始',
    bodyPart: '有氧',
    reps: '20m',
    note: '身体前倾，脚掌持续蹬地推进。'),
WorkoutAction(
    name: '原地高抬腿低冲击版',
    detail: '3组 × 45s',
    imageAsset: 'assets/workout/actions/cardio_low_impact_high_knees.png',
    icon: Icons.directions_run_rounded,
    groups: 3,
    status: '未开始',
    bodyPart: '有氧',
    reps: '45s',
    note: '交替抬膝，不跳跃，保持稳定节奏。'),
WorkoutAction(
    name: '农夫行走',
    detail: '4组 × 30m × 20kg',
    imageAsset: 'assets/workout/actions/cardio_farmer_carry.png',
    icon: Icons.directions_walk_rounded,
    groups: 4,
    status: '未开始',
    bodyPart: '有氧',
    reps: '30m',
    weight: '20kg',
    note: '双手持重行走，肩膀下沉，步伐稳定。'),
```

- [ ] **步骤 3：在拉伸现有 7 个动作后追加 7 个动作**

在拉伸动作块末尾、`_bodyParts` 定义之前插入：

```dart
WorkoutAction(
    name: '胸椎旋转',
    detail: '2组 × 8次/侧',
    imageAsset: 'assets/workout/actions/stretch_thoracic_rotation.png',
    icon: Icons.rotate_right_rounded,
    groups: 2,
    status: '未开始',
    bodyPart: '拉伸',
    reps: '8次/侧',
    note: '侧卧打开上侧手臂，视线跟随手移动。'),
WorkoutAction(
    name: '沙发拉伸',
    detail: '2组 × 30s/侧',
    imageAsset: 'assets/workout/actions/stretch_couch_stretch.png',
    icon: Icons.self_improvement_rounded,
    groups: 2,
    status: '未开始',
    bodyPart: '拉伸',
    reps: '30s/侧',
    note: '后脚搭高，收紧臀部，避免腰椎过伸。'),
WorkoutAction(
    name: '踝关节前移活动',
    detail: '2组 × 10次/侧',
    imageAsset: 'assets/workout/actions/stretch_ankle_dorsiflexion.png',
    icon: Icons.self_improvement_rounded,
    groups: 2,
    status: '未开始',
    bodyPart: '拉伸',
    reps: '10次/侧',
    note: '膝盖向脚尖方向前移，脚跟保持贴地。'),
WorkoutAction(
    name: '90/90 髋旋转',
    detail: '2组 × 8次/侧',
    imageAsset: 'assets/workout/actions/stretch_9090_hip_rotation.png',
    icon: Icons.self_improvement_rounded,
    groups: 2,
    status: '未开始',
    bodyPart: '拉伸',
    reps: '8次/侧',
    note: '两腿呈 90 度，缓慢切换髋部内外旋。'),
WorkoutAction(
    name: '背阔肌拉伸',
    detail: '2组 × 30s/侧',
    imageAsset: 'assets/workout/actions/stretch_lat_stretch.png',
    icon: Icons.self_improvement_rounded,
    groups: 2,
    status: '未开始',
    bodyPart: '拉伸',
    reps: '30s/侧',
    note: '手扶固定物，髋部后坐，感受身体侧后方拉伸。'),
WorkoutAction(
    name: '梨状肌拉伸',
    detail: '2组 × 30s/侧',
    imageAsset: 'assets/workout/actions/stretch_piriformis_stretch.png',
    icon: Icons.self_improvement_rounded,
    groups: 2,
    status: '未开始',
    bodyPart: '拉伸',
    reps: '30s/侧',
    note: '一腿交叉放在另一腿上，轻轻靠近胸口。'),
WorkoutAction(
    name: '肩后侧拉伸',
    detail: '2组 × 30s/侧',
    imageAsset: 'assets/workout/actions/stretch_posterior_shoulder_stretch.png',
    icon: Icons.self_improvement_rounded,
    groups: 2,
    status: '未开始',
    bodyPart: '拉伸',
    reps: '30s/侧',
    note: '手臂横过胸前，另一只手轻柔辅助。'),
```

- [ ] **步骤 4：运行动作库测试**

运行：

```powershell
flutter test test\workout_widget_test.dart
```

预期：动作数量和总组数相关断言通过；默认计划相关断言仍可能失败，因为默认计划还没有重组。

---

### 任务 4：生成并放入动作图片资源

**文件：**
- 创建：`assets/workout/actions/chest_incline_push_up.png`
- 创建：`assets/workout/actions/chest_dumbbell_floor_press.png`
- 创建：`assets/workout/actions/chest_inverted_row.png`
- 创建：`assets/workout/actions/chest_straight_arm_pulldown.png`
- 创建：`assets/workout/actions/chest_band_pull_apart.png`
- 创建：`assets/workout/actions/chest_prone_ytw.png`
- 创建：`assets/workout/actions/chest_scapular_push_up.png`
- 创建：`assets/workout/actions/shoulder_wall_slide.png`
- 创建：`assets/workout/actions/shoulder_wall_angel.png`
- 创建：`assets/workout/actions/shoulder_band_pull_apart.png`
- 创建：`assets/workout/actions/shoulder_chin_tuck.png`
- 创建：`assets/workout/actions/shoulder_scapular_circle.png`
- 创建：`assets/workout/actions/shoulder_prone_y_raise.png`
- 创建：`assets/workout/actions/shoulder_light_arnold_press.png`
- 创建：`assets/workout/actions/core_bird_dog.png`
- 创建：`assets/workout/actions/core_pallof_press.png`
- 创建：`assets/workout/actions/core_plank_shoulder_tap.png`
- 创建：`assets/workout/actions/core_hollow_hold.png`
- 创建：`assets/workout/actions/core_half_kneeling_wood_chop.png`
- 创建：`assets/workout/actions/core_suitcase_carry.png`
- 创建：`assets/workout/actions/core_reverse_crunch.png`
- 创建：`assets/workout/actions/legs_goblet_squat.png`
- 创建：`assets/workout/actions/legs_box_squat.png`
- 创建：`assets/workout/actions/legs_lateral_lunge.png`
- 创建：`assets/workout/actions/legs_hamstring_curl.png`
- 创建：`assets/workout/actions/legs_standing_calf_raise.png`
- 创建：`assets/workout/actions/legs_band_lateral_walk.png`
- 创建：`assets/workout/actions/legs_clamshell.png`
- 创建：`assets/workout/actions/cardio_incline_walk.png`
- 创建：`assets/workout/actions/cardio_low_impact_step_jack.png`
- 创建：`assets/workout/actions/cardio_air_bike_intervals.png`
- 创建：`assets/workout/actions/cardio_battle_rope.png`
- 创建：`assets/workout/actions/cardio_sled_push.png`
- 创建：`assets/workout/actions/cardio_low_impact_high_knees.png`
- 创建：`assets/workout/actions/cardio_farmer_carry.png`
- 创建：`assets/workout/actions/stretch_thoracic_rotation.png`
- 创建：`assets/workout/actions/stretch_couch_stretch.png`
- 创建：`assets/workout/actions/stretch_ankle_dorsiflexion.png`
- 创建：`assets/workout/actions/stretch_9090_hip_rotation.png`
- 创建：`assets/workout/actions/stretch_lat_stretch.png`
- 创建：`assets/workout/actions/stretch_piriformis_stretch.png`
- 创建：`assets/workout/actions/stretch_posterior_shoulder_stretch.png`

- [ ] **步骤 1：生成图片**

执行本任务时使用 `imagegen` 或已配置的 Agnes 生图能力。统一风格提示词：

```text
Clean mobile fitness app exercise illustration, full body human figure performing [ACTION], accurate anatomy and posture, light gym or home training background, bright white and pale blue UI-friendly style, no text, no logos, square composition, 1024x1024.
```

将 `[ACTION]` 替换为对应英文动作描述，例如：

```text
incline push-up with hands on bench
dumbbell floor press
inverted row under a low bar
straight-arm cable pulldown
band pull-apart
prone Y-T-W raise sequence
scapular push-up plank position
wall slide
wall angel
chin tuck posture exercise
bird dog
Pallof press with cable
goblet squat
low impact step jack
thoracic rotation stretch
```

- [ ] **步骤 2：保存图片到指定路径**

所有图片保存为 PNG，文件名必须与本计划“新增动作和资源命名”表一致。

- [ ] **步骤 3：验证图片文件完整**

运行：

```powershell
$files = @(
  'chest_incline_push_up.png','chest_dumbbell_floor_press.png','chest_inverted_row.png',
  'chest_straight_arm_pulldown.png','chest_band_pull_apart.png','chest_prone_ytw.png',
  'chest_scapular_push_up.png','shoulder_wall_slide.png','shoulder_wall_angel.png',
  'shoulder_band_pull_apart.png','shoulder_chin_tuck.png','shoulder_scapular_circle.png',
  'shoulder_prone_y_raise.png','shoulder_light_arnold_press.png','core_bird_dog.png',
  'core_pallof_press.png','core_plank_shoulder_tap.png','core_hollow_hold.png',
  'core_half_kneeling_wood_chop.png','core_suitcase_carry.png','core_reverse_crunch.png',
  'legs_goblet_squat.png','legs_box_squat.png','legs_lateral_lunge.png',
  'legs_hamstring_curl.png','legs_standing_calf_raise.png','legs_band_lateral_walk.png',
  'legs_clamshell.png','cardio_incline_walk.png','cardio_low_impact_step_jack.png',
  'cardio_air_bike_intervals.png','cardio_battle_rope.png','cardio_sled_push.png',
  'cardio_low_impact_high_knees.png','cardio_farmer_carry.png','stretch_thoracic_rotation.png',
  'stretch_couch_stretch.png','stretch_ankle_dorsiflexion.png','stretch_9090_hip_rotation.png',
  'stretch_lat_stretch.png','stretch_piriformis_stretch.png','stretch_posterior_shoulder_stretch.png'
)
$missing = $files | Where-Object { -not (Test-Path -LiteralPath "assets\workout\actions\$_") }
if ($missing.Count -gt 0) { $missing; exit 1 }
'all workout action assets exist'
```

预期：输出 `all workout action assets exist`。

---

### 任务 5：重组默认训练计划

**文件：**
- 修改：`lib/modules/workout/workout_models.dart`
- 修改：`test/workout_widget_test.dart`

- [ ] **步骤 1：更新默认计划函数**

将 `createDefaultWorkoutPlans()` 中的返回列表替换为：

```dart
return [
  WorkoutPlan(
    id: 'plan-chest-back',
    name: '胸背强化',
    target: '胸背力量和体态稳定',
    bodyParts: const ['胸背'],
    actionNames: const [
      '器械推胸',
      '宽握高位下拉',
      '坐姿绳索划船',
      '上斜哑铃卧推',
      '弹力带拉开',
      '俯卧 Y-T-W',
    ],
    estimatedMinutes: 42,
    createdAt: now,
    updatedAt: now,
  ),
  WorkoutPlan(
    id: 'plan-leg-stability',
    name: '腿臀训练',
    target: '腿臀力量、膝髋稳定和下肢完整模式',
    bodyParts: const ['腿臀'],
    actionNames: const [
      '杠铃深蹲',
      '罗马尼亚硬拉',
      '保加利亚分腿蹲',
      '臀桥',
      '弹力带侧走',
      '站姿提踵',
    ],
    estimatedMinutes: 40,
    createdAt: now,
    updatedAt: now,
  ),
  WorkoutPlan(
    id: 'plan-core-recovery',
    name: '核心恢复',
    target: '核心控制、抗旋转和轻恢复',
    bodyParts: const ['核心', '拉伸'],
    actionNames: const [
      '死虫',
      '鸟狗',
      'Pallof 抗旋转推',
      '侧桥',
      '胸椎旋转',
      '儿童式放松',
    ],
    estimatedMinutes: 24,
    createdAt: now,
    updatedAt: now,
  ),
  WorkoutPlan(
    id: 'plan-quick-ten',
    name: '快练 10 分钟',
    target: '碎片时间低风险激活',
    bodyParts: const ['胸背', '腿臀', '核心', '有氧', '拉伸'],
    actionNames: const [
      '上斜俯卧撑',
      '箱式深蹲',
      '平板触肩',
      '低冲击开合步',
      '胸椎旋转',
    ],
    estimatedMinutes: 10,
    createdAt: now,
    updatedAt: now,
  ),
  WorkoutPlan(
    id: 'plan-beginner-full-body',
    name: '新手全身基础',
    target: '用基础动作覆盖全身主要模式',
    bodyParts: const ['胸背', '腿臀', '核心', '有氧'],
    actionNames: const [
      '高脚杯深蹲',
      '哑铃地板卧推',
      '反向划船',
      '鸟狗',
      '坡度快走',
    ],
    estimatedMinutes: 28,
    createdAt: now,
    updatedAt: now,
  ),
  WorkoutPlan(
    id: 'plan-desk-shoulder-reset',
    name: '久坐肩颈修复',
    target: '肩颈放松、胸椎活动和肩胛控制',
    bodyParts: const ['肩颈', '拉伸'],
    actionNames: const [
      '墙滑',
      '下巴回收',
      '弹力带外展拉开',
      '胸椎旋转',
      '胸大肌门框拉伸',
      '肩后侧拉伸',
    ],
    estimatedMinutes: 20,
    createdAt: now,
    updatedAt: now,
  ),
  WorkoutPlan(
    id: 'plan-low-impact-conditioning',
    name: '低冲击燃脂',
    target: '减少膝踝冲击，同时提供心肺训练',
    bodyParts: const ['有氧', '核心', '拉伸'],
    actionNames: const [
      '坡度快走',
      '空气单车间歇',
      '农夫行走',
      '低冲击开合步',
      '儿童式放松',
    ],
    estimatedMinutes: 26,
    createdAt: now,
    updatedAt: now,
  ),
];
```

- [ ] **步骤 2：更新计划详情测试**

在 `workout plan opens detail and starts scoped workout` 测试中，把胸背计划断言改成新动作数和新组数。

```dart
expect(find.descendant(of: detailSheet, matching: find.text('6 个动作')),
    findsOneWidget);
expect(find.descendant(of: detailSheet, matching: find.text('22 组')),
    findsOneWidget);
```

并把开始训练后的断言改成：

```dart
expect(find.text('6 个动作'), findsWidgets);
expect(find.text('器械推胸'), findsWidgets);
expect(find.text('宽握高位下拉'), findsWidgets);
expect(find.text('弹力带拉开'), findsWidgets);
expect(find.text('平板支撑'), findsNothing);
```

- [ ] **步骤 3：更新快练计划完成测试**

在 `finishing planned workout creates history entry`、`workout data cards open real metric detail` 以及其他遍历快练动作的测试中，将旧动作列表：

```dart
['登山跑', '俄罗斯转体', '波比跳']
```

替换为：

```dart
['上斜俯卧撑', '箱式深蹲', '平板触肩', '低冲击开合步', '胸椎旋转']
```

内层循环不要写死 `index < 3`。改为动作组数映射：

```dart
const quickPlanGroups = {
  '上斜俯卧撑': 3,
  '箱式深蹲': 3,
  '平板触肩': 3,
  '低冲击开合步': 3,
  '胸椎旋转': 2,
};
for (final entry in quickPlanGroups.entries) {
  for (var index = 0; index < entry.value; index++) {
    await tapWorkoutActionByName(tester, entry.key);
    await tester.tap(find.text('开始动作'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
  }
}
```

- [ ] **步骤 4：更新腿部计划名称断言**

把测试中用户可见的 `腿部稳定` 文案断言改为 `腿臀训练`。保留 `plan-leg-stability` 的 id 断言不变，避免现有 key 大范围变化。

```dart
expect(find.text('腿臀训练'), findsWidgets);
```

- [ ] **步骤 5：添加新计划模板测试断言**

在 `workout training templates open matching plan detail` 测试中补充：

```dart
expect(find.text('新手全身基础'), findsWidgets);
expect(find.text('久坐肩颈修复'), findsWidgets);
expect(find.text('低冲击燃脂'), findsWidgets);
```

- [ ] **步骤 6：运行锻炼测试**

运行：

```powershell
flutter test test\workout_widget_test.dart
```

预期：PASS。

---

### 任务 6：全量验证和提交

**文件：**
- 修改：`lib/modules/workout/workout_module.dart`
- 修改：`lib/modules/workout/workout_models.dart`
- 修改：`test/workout_widget_test.dart`
- 创建：`assets/workout/actions/*.png`

- [ ] **步骤 1：格式化 Dart 文件**

运行：

```powershell
dart format lib\modules\workout\workout_module.dart lib\modules\workout\workout_models.dart test\workout_widget_test.dart
```

预期：输出 3 个文件的格式化结果或 `Changed 0 files`。

- [ ] **步骤 2：静态分析**

运行：

```powershell
flutter analyze
```

预期：`No issues found!`

- [ ] **步骤 3：锻炼测试**

运行：

```powershell
flutter test test\workout_widget_test.dart
```

预期：所有测试通过。

- [ ] **步骤 4：全量测试**

运行：

```powershell
flutter test
```

预期：所有测试通过。

- [ ] **步骤 5：检查 diff 空白错误**

运行：

```powershell
git diff --check
```

预期：无错误输出。Windows 行尾提示如果只来自 Git 自动换行警告，不视为失败。

- [ ] **步骤 6：只提交本任务文件**

运行：

```powershell
git add -- lib/modules/workout/workout_module.dart lib/modules/workout/workout_models.dart test/workout_widget_test.dart assets/workout/actions
git diff --cached --name-status
git commit -m "feat: expand science-based workout actions"
```

预期：暂存内容只包含锻炼模块、锻炼测试和新增动作图片资源。提交成功后输出新的 commit hash。

## 自检结果

- 规格覆盖度：动作库扩容、计划重组、图片资源、测试验收均有任务覆盖。
- 范围控制：未新增模型字段、未新增训练算法、未重构锻炼 UI。
- 类型一致性：动作名称、图片路径、默认计划中的 `actionNames` 与任务 2、3、4 的新增条目一致。
- 验证闭环：先修改测试确认失败，再补实现，最后运行局部和全量验证。
