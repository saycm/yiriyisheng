// 中文注释：锻炼模块源码，负责动作库、训练计划、训练记录和更多菜单。

part of 'workout.dart';

class WorkoutModulePage extends StatefulWidget {
  const WorkoutModulePage({
    super.key,
    required this.moduleNav,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.finishedGroupsByAction,
    required this.onUpdateActionGroups,
    required this.workoutPlans,
    required this.onUpdateWorkoutPlan,
    required this.activeWorkoutSession,
    required this.workoutHistory,
    required this.onStartWorkoutSession,
    required this.onUpdateWorkoutSession,
    required this.onFinishWorkoutSession,
    required this.foodCalories,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final Widget moduleNav;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final Map<String, int> finishedGroupsByAction;
  final void Function(String actionName, int finishedGroups)
      onUpdateActionGroups;
  final List<WorkoutPlan> workoutPlans;
  final ValueChanged<WorkoutPlan> onUpdateWorkoutPlan;
  final ActiveWorkoutSession? activeWorkoutSession;
  final List<WorkoutHistoryEntry> workoutHistory;
  final ValueChanged<ActiveWorkoutSession> onStartWorkoutSession;
  final ValueChanged<ActiveWorkoutSession> onUpdateWorkoutSession;
  final ValueChanged<WorkoutHistoryEntry> onFinishWorkoutSession;
  final int foodCalories;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<WorkoutModulePage> createState() => _WorkoutModulePageState();
}

class _WorkoutModulePageState extends State<WorkoutModulePage> {
  static const _actions = [
    WorkoutAction(
      name: '蝴蝶机夹胸',
      detail: '4组 × 8次 × 30kg',
      imageAsset: 'assets/workout/actions/chest_butterfly_machine.png',
      icon: Icons.accessibility_new_rounded,
      groups: 4,
      status: '未开始',
      bodyPart: '胸背',
      reps: '8次',
      weight: '30kg',
      note: '肩胛稳定，顶峰收缩 1 秒。',
    ),
    WorkoutAction(
      name: '宽握高位下拉',
      detail: '4组 × 12次 × 30kg',
      imageAsset: 'assets/workout/actions/chest_wide_lat_pulldown.png',
      icon: Icons.fitness_center_rounded,
      groups: 4,
      status: '未开始',
      bodyPart: '胸背',
      reps: '12次',
      weight: '30kg',
      note: '下拉到锁骨，避免耸肩。',
    ),
    WorkoutAction(
      name: '器械推胸',
      detail: '4组 × 12次 × 20kg',
      imageAsset: 'assets/workout/actions/chest_machine_press.png',
      icon: Icons.sports_gymnastics_rounded,
      groups: 4,
      status: '未开始',
      bodyPart: '胸背',
      reps: '12次',
      weight: '20kg',
      note: '推起呼气，回落控制。',
    ),
    WorkoutAction(
      name: '坐姿绳索划船',
      detail: '4组 × 12次 × 30kg',
      imageAsset: 'assets/workout/actions/chest_seated_cable_row.png',
      icon: Icons.rowing_rounded,
      groups: 4,
      status: '未开始',
      bodyPart: '胸背',
      reps: '12次',
      weight: '30kg',
      note: '先收肩胛再拉手柄。',
    ),
    WorkoutAction(
        name: '上斜哑铃卧推',
        detail: '4组 × 10次 × 16kg',
        imageAsset: 'assets/workout/actions/chest_incline_dumbbell_press.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '胸背',
        reps: '10次',
        weight: '16kg',
        note: '肩胛微收，手腕保持中立。'),
    WorkoutAction(
        name: '单臂哑铃划船',
        detail: '4组 × 10次 × 18kg',
        imageAsset: 'assets/workout/actions/chest_one_arm_dumbbell_row.png',
        icon: Icons.rowing_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '胸背',
        reps: '10次',
        weight: '18kg',
        note: '手肘贴近身体，顶端停顿半秒。'),
    WorkoutAction(
        name: '俯身杠铃划船',
        detail: '4组 × 8次 × 35kg',
        imageAsset: 'assets/workout/actions/chest_barbell_bent_over_row.png',
        icon: Icons.fitness_center_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '胸背',
        reps: '8次',
        weight: '35kg',
        note: '髋部后坐，脊柱保持中立。'),
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
    WorkoutAction(
        name: '哑铃侧平举',
        detail: '3组 × 15次 × 6kg',
        imageAsset:
            'assets/workout/actions/shoulder_dumbbell_lateral_raise.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '15次',
        weight: '6kg',
        note: '手肘微屈，抬到与肩平。'),
    WorkoutAction(
        name: '哑铃前平举',
        detail: '3组 × 12次 × 6kg',
        imageAsset: 'assets/workout/actions/shoulder_dumbbell_front_raise.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '12次',
        weight: '6kg',
        note: '核心收紧，避免借力摆动。'),
    WorkoutAction(
        name: '站姿推举',
        detail: '3组 × 10次 × 20kg',
        imageAsset:
            'assets/workout/actions/shoulder_standing_overhead_press.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '10次',
        weight: '20kg',
        note: '收紧臀腹，推起时头部轻微前穿。'),
    WorkoutAction(
        name: '绳索面拉',
        detail: '3组 × 15次 × 15kg',
        imageAsset: 'assets/workout/actions/shoulder_cable_face_pull.png',
        icon: Icons.fitness_center_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '15次',
        weight: '15kg',
        note: '拉向眉心，外旋打开肩关节。'),
    WorkoutAction(
        name: '俯身反向飞鸟',
        detail: '3组 × 12次 × 5kg',
        imageAsset: 'assets/workout/actions/shoulder_reverse_fly.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '12次',
        weight: '5kg',
        note: '保持胸椎延展，动作幅度稳定。'),
    WorkoutAction(
        name: '哑铃耸肩',
        detail: '3组 × 15次 × 20kg',
        imageAsset: 'assets/workout/actions/shoulder_dumbbell_shrug.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '15次',
        weight: '20kg',
        note: '肩膀向上向后提，避免颈部前探。'),
    WorkoutAction(
        name: '弹力带外旋',
        detail: '3组 × 15次',
        imageAsset:
            'assets/workout/actions/shoulder_band_external_rotation.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '15次',
        note: '上臂贴肋骨，缓慢打开前臂。'),
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
        note: '保持肋骨下沉，手臂贴墙打开。'),
    WorkoutAction(
        name: '弹力带外展拉开',
        detail: '3组 × 15次',
        imageAsset: 'assets/workout/actions/shoulder_band_pull_apart.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '15次',
        note: '肩胛后收下沉，控制弹力带回放。'),
    WorkoutAction(
        name: '下巴回收',
        detail: '2组 × 10次',
        imageAsset: 'assets/workout/actions/shoulder_chin_tuck.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '10次',
        note: '下巴水平向后收，保持后颈延展。'),
    WorkoutAction(
        name: '肩胛绕环',
        detail: '2组 × 10次/向',
        imageAsset: 'assets/workout/actions/shoulder_scapular_circle.png',
        icon: Icons.rotate_right_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '肩颈',
        reps: '10次/向',
        note: '用肩胛带动绕环，避免耸肩代偿。'),
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
        note: '轻重量旋转推起，保持躯干稳定。'),
    WorkoutAction(
      name: '平板支撑',
      detail: '3组 × 60s',
      imageAsset: 'assets/workout/actions/core_plank.png',
      icon: Icons.self_improvement_rounded,
      groups: 3,
      status: '未开始',
      bodyPart: '核心',
      reps: '60s',
      note: '保持骨盆中立，不塌腰。',
    ),
    WorkoutAction(
        name: '死虫',
        detail: '3组 × 12次',
        imageAsset: 'assets/workout/actions/core_dead_bug.png',
        icon: Icons.self_improvement_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '12次',
        note: '腰背贴地，手脚对侧交替伸展。'),
    WorkoutAction(
        name: '俄罗斯转体',
        detail: '3组 × 20次',
        imageAsset: 'assets/workout/actions/core_russian_twist.png',
        icon: Icons.rotate_right_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '20次',
        note: '躯干整体转动，避免只甩手。'),
    WorkoutAction(
        name: '仰卧举腿',
        detail: '3组 × 12次',
        imageAsset: 'assets/workout/actions/core_leg_raise.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '12次',
        note: '下放时控制速度，腰部不过度离地。'),
    WorkoutAction(
        name: '卷腹触膝',
        detail: '3组 × 15次',
        imageAsset: 'assets/workout/actions/core_crunch_knee_touch.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '15次',
        note: '呼气卷起，关注腹直肌发力。'),
    WorkoutAction(
        name: '登山跑',
        detail: '3组 × 30s',
        imageAsset: 'assets/workout/actions/core_mountain_climber.png',
        icon: Icons.directions_run_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '30s',
        note: '肩在手腕正上方，膝盖快速向胸前收。'),
    WorkoutAction(
        name: '侧桥',
        detail: '3组 × 45s',
        imageAsset: 'assets/workout/actions/core_side_plank.png',
        icon: Icons.self_improvement_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '45s',
        note: '耳肩髋踝保持一条直线。'),
    WorkoutAction(
        name: '鸟狗',
        detail: '3组 × 10次/侧',
        imageAsset: 'assets/workout/actions/core_bird_dog.png',
        icon: Icons.self_improvement_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '10次/侧',
        note: '对侧手脚伸展，骨盆保持稳定。'),
    WorkoutAction(
        name: 'Pallof 抗旋转推',
        detail: '3组 × 12次/侧 × 10kg',
        imageAsset: 'assets/workout/actions/core_pallof_press.png',
        icon: Icons.fitness_center_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '12次/侧',
        weight: '10kg',
        note: '双手前推时抵抗绳索拉扯，躯干不旋转。'),
    WorkoutAction(
        name: '平板触肩',
        detail: '3组 × 20次',
        imageAsset: 'assets/workout/actions/core_plank_shoulder_tap.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '20次',
        note: '保持髋部稳定，左右手交替触肩。'),
    WorkoutAction(
        name: 'Hollow Hold',
        detail: '3组 × 30s',
        imageAsset: 'assets/workout/actions/core_hollow_hold.png',
        icon: Icons.self_improvement_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '30s',
        note: '腰背贴地，手脚伸长保持张力。'),
    WorkoutAction(
        name: '半跪姿砍木',
        detail: '3组 × 10次/侧 × 10kg',
        imageAsset: 'assets/workout/actions/core_half_kneeling_wood_chop.png',
        icon: Icons.fitness_center_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '10次/侧',
        weight: '10kg',
        note: '髋膝稳定，躯干带动斜向发力。'),
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
        note: '单手负重行走，保持躯干直立。'),
    WorkoutAction(
        name: '反向卷腹',
        detail: '3组 × 12次',
        imageAsset: 'assets/workout/actions/core_reverse_crunch.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '核心',
        reps: '12次',
        note: '骨盆向上卷起，下放时控制速度。'),
    WorkoutAction(
        name: '杠铃深蹲',
        detail: '4组 × 8次 × 40kg',
        imageAsset: 'assets/workout/actions/legs_barbell_squat.png',
        icon: Icons.fitness_center_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '8次',
        weight: '40kg',
        note: '脚掌踩稳，膝盖方向跟脚尖一致。'),
    WorkoutAction(
        name: '保加利亚分腿蹲',
        detail: '4组 × 10次 × 12kg',
        imageAsset: 'assets/workout/actions/legs_bulgarian_split_squat.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '10次',
        weight: '12kg',
        note: '前脚发力起身，身体微微前倾。'),
    WorkoutAction(
        name: '罗马尼亚硬拉',
        detail: '4组 × 10次 × 35kg',
        imageAsset: 'assets/workout/actions/legs_romanian_deadlift.png',
        icon: Icons.fitness_center_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '10次',
        weight: '35kg',
        note: '髋部向后折叠，感受臀腿后侧拉伸。'),
    WorkoutAction(
        name: '臀桥',
        detail: '4组 × 12次 × 50kg',
        imageAsset: 'assets/workout/actions/legs_hip_thrust.png',
        icon: Icons.accessibility_new_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '12次',
        weight: '50kg',
        note: '顶峰停顿 1 秒，避免腰椎代偿。'),
    WorkoutAction(
        name: '腿举',
        detail: '4组 × 12次 × 120kg',
        imageAsset: 'assets/workout/actions/legs_leg_press.png',
        icon: Icons.directions_run_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '12次',
        weight: '120kg',
        note: '下放到大腿接近腹部，再平稳蹬起。'),
    WorkoutAction(
        name: '箱式登阶',
        detail: '4组 × 12次 × 10kg',
        imageAsset: 'assets/workout/actions/legs_box_step_up.png',
        icon: Icons.stairs_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '12次',
        weight: '10kg',
        note: '全脚掌踩稳箱面，起身时不蹬后腿。'),
    WorkoutAction(
        name: '坐姿腿屈伸',
        detail: '4组 × 15次 × 25kg',
        imageAsset: 'assets/workout/actions/legs_leg_extension.png',
        icon: Icons.chair_alt_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '15次',
        weight: '25kg',
        note: '顶峰绷紧股四头肌，回落不要砸重量。'),
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
        note: '哑铃贴近胸前，膝盖跟随脚尖方向。'),
    WorkoutAction(
        name: '箱式深蹲',
        detail: '3组 × 10次',
        imageAsset: 'assets/workout/actions/legs_box_squat.png',
        icon: Icons.chair_alt_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '10次',
        note: '髋部向后坐到箱面，保持脚掌发力。'),
    WorkoutAction(
        name: '侧弓步',
        detail: '3组 × 10次/侧',
        imageAsset: 'assets/workout/actions/legs_lateral_lunge.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '10次/侧',
        note: '一侧屈膝下沉，另一侧腿伸直。'),
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
        note: '脚跟向臀部卷收，回放保持控制。'),
    WorkoutAction(
        name: '站姿提踵',
        detail: '3组 × 15次',
        imageAsset: 'assets/workout/actions/legs_standing_calf_raise.png',
        icon: Icons.directions_walk_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '15次',
        note: '脚跟充分抬起，顶端短暂停顿。'),
    WorkoutAction(
        name: '弹力带侧走',
        detail: '3组 × 12步/侧',
        imageAsset: 'assets/workout/actions/legs_band_lateral_walk.png',
        icon: Icons.directions_walk_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '12步/侧',
        note: '膝盖微屈，保持弹力带张力侧向移动。'),
    WorkoutAction(
        name: '蚌式开合',
        detail: '3组 × 15次/侧',
        imageAsset: 'assets/workout/actions/legs_clamshell.png',
        icon: Icons.accessibility_new_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '腿臀',
        reps: '15次/侧',
        note: '髋部叠放稳定，上侧膝盖向外打开。'),
    WorkoutAction(
        name: '跑步机慢跑',
        detail: '3组 × 6min',
        imageAsset: 'assets/workout/actions/cardio_treadmill_jog.png',
        icon: Icons.directions_run_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '6min',
        note: '保持均匀呼吸，步频稳定。'),
    WorkoutAction(
        name: '划船机冲刺',
        detail: '3组 × 500m',
        imageAsset: 'assets/workout/actions/cardio_rowing_sprint.png',
        icon: Icons.rowing_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '500m',
        note: '腿蹬、后仰、拉手顺序连贯。'),
    WorkoutAction(
        name: '动感单车',
        detail: '3组 × 8min',
        imageAsset: 'assets/workout/actions/cardio_spinning_bike.png',
        icon: Icons.pedal_bike_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '8min',
        note: '阻力保持中高强度，稳定踩踏。'),
    WorkoutAction(
        name: '椭圆机耐力',
        detail: '3组 × 10min',
        imageAsset: 'assets/workout/actions/cardio_elliptical_endurance.png',
        icon: Icons.directions_walk_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '10min',
        note: '肩颈放松，重心保持居中。'),
    WorkoutAction(
        name: '跳绳间歇',
        detail: '3组 × 90s',
        imageAsset: 'assets/workout/actions/cardio_jump_rope.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '90s',
        note: '手腕轻甩，脚尖轻快落地。'),
    WorkoutAction(
        name: '台阶机爬升',
        detail: '3组 × 5min',
        imageAsset: 'assets/workout/actions/cardio_stair_climber.png',
        icon: Icons.stairs_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '5min',
        note: '用臀腿发力，避免过度扶把。'),
    WorkoutAction(
        name: '波比跳',
        detail: '3组 × 12次',
        imageAsset: 'assets/workout/actions/cardio_burpee.png',
        icon: Icons.bolt_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '12次',
        note: '保持节奏，落地时屈膝缓冲。'),
    WorkoutAction(
        name: '坡度快走',
        detail: '3组 × 8min',
        imageAsset: 'assets/workout/actions/cardio_incline_walk.png',
        icon: Icons.directions_walk_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '8min',
        note: '保持稳定步频，身体微前倾。'),
    WorkoutAction(
        name: '低冲击开合步',
        detail: '3组 × 45s',
        imageAsset: 'assets/workout/actions/cardio_low_impact_step_jack.png',
        icon: Icons.sports_gymnastics_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '45s',
        note: '左右侧步开合，手臂同步上举。'),
    WorkoutAction(
        name: '空气单车间歇',
        detail: '6组 × 30s',
        imageAsset: 'assets/workout/actions/cardio_air_bike_intervals.png',
        icon: Icons.pedal_bike_rounded,
        groups: 6,
        status: '未开始',
        bodyPart: '有氧',
        reps: '30s',
        note: '短时间提高踩踏频率，组间充分恢复。'),
    WorkoutAction(
        name: '战绳',
        detail: '4组 × 30s',
        imageAsset: 'assets/workout/actions/cardio_battle_rope.png',
        icon: Icons.bolt_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '有氧',
        reps: '30s',
        note: '膝髋微屈，双臂交替制造绳波。'),
    WorkoutAction(
        name: '雪橇推',
        detail: '4组 × 20m',
        imageAsset: 'assets/workout/actions/cardio_sled_push.png',
        icon: Icons.directions_run_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '有氧',
        reps: '20m',
        note: '身体前倾，用腿部持续推动。'),
    WorkoutAction(
        name: '原地高抬腿低冲击版',
        detail: '3组 × 45s',
        imageAsset: 'assets/workout/actions/cardio_low_impact_high_knees.png',
        icon: Icons.directions_run_rounded,
        groups: 3,
        status: '未开始',
        bodyPart: '有氧',
        reps: '45s',
        note: '交替抬膝，脚步轻落地。'),
    WorkoutAction(
        name: '农夫行走',
        detail: '4组 × 30m × 20kg',
        imageAsset: 'assets/workout/actions/cardio_farmer_carry.png',
        icon: Icons.fitness_center_rounded,
        groups: 4,
        status: '未开始',
        bodyPart: '有氧',
        reps: '30m',
        weight: '20kg',
        note: '双手负重行走，肩膀下沉收紧。'),
    WorkoutAction(
        name: '站姿股四头肌拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_quad_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '膝盖并拢，骨盆轻轻后收。'),
    WorkoutAction(
        name: '坐姿腘绳肌拉伸',
        detail: '2组 × 30s',
        imageAsset: 'assets/workout/actions/stretch_hamstring_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s',
        note: '背部延展，髋部前倾找拉伸感。'),
    WorkoutAction(
        name: '跪姿髋屈肌拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_hip_flexor_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '后侧臀部收紧，骨盆保持正位。'),
    WorkoutAction(
        name: '胸大肌门框拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_doorway_chest_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '前臂贴门框，身体缓慢前移。'),
    WorkoutAction(
        name: '猫牛式伸展',
        detail: '2组 × 8次',
        imageAsset: 'assets/workout/actions/stretch_cat_cow.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '8次',
        note: '一呼一吸配合脊柱屈伸。'),
    WorkoutAction(
        name: '儿童式放松',
        detail: '2组 × 45s',
        imageAsset: 'assets/workout/actions/stretch_child_pose.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '45s',
        note: '坐向脚跟，肩背放松下沉。'),
    WorkoutAction(
        name: '肩颈侧屈拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_neck_side_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '肩膀向下放松，头部轻柔侧屈。'),
    WorkoutAction(
        name: '胸椎旋转',
        detail: '2组 × 8次/侧',
        imageAsset: 'assets/workout/actions/stretch_thoracic_rotation.png',
        icon: Icons.rotate_right_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '8次/侧',
        note: '髋部稳定，胸椎带动上背旋转。'),
    WorkoutAction(
        name: '沙发拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_couch_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '后脚置于支撑面，骨盆轻轻后收。'),
    WorkoutAction(
        name: '踝关节前移活动',
        detail: '2组 × 10次/侧',
        imageAsset: 'assets/workout/actions/stretch_ankle_dorsiflexion.png',
        icon: Icons.directions_walk_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '10次/侧',
        note: '膝盖向脚尖方向前移，脚跟保持接触地面。'),
    WorkoutAction(
        name: '90/90 髋旋转',
        detail: '2组 × 8次/侧',
        imageAsset: 'assets/workout/actions/stretch_9090_hip_rotation.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '8次/侧',
        note: '双腿呈 90/90 位，髋部缓慢内外旋。'),
    WorkoutAction(
        name: '背阔肌拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_lat_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '手臂向前延展，侧腰和背阔肌放松。'),
    WorkoutAction(
        name: '梨状肌拉伸',
        detail: '2组 × 30s/侧',
        imageAsset: 'assets/workout/actions/stretch_piriformis_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '一侧脚踝搭在对侧腿上，髋部外侧放松。'),
    WorkoutAction(
        name: '肩后侧拉伸',
        detail: '2组 × 30s/侧',
        imageAsset:
            'assets/workout/actions/stretch_posterior_shoulder_stretch.png',
        icon: Icons.self_improvement_rounded,
        groups: 2,
        status: '未开始',
        bodyPart: '拉伸',
        reps: '30s/侧',
        note: '手臂横过胸前，肩后侧保持轻柔拉伸。'),
  ];
  static const _bodyParts = ['全部', '胸背部', '肩颈', '核心', '腿臀', '有氧', '拉伸'];

  int _selectedTopTab = 0;
  int _selectedBottomTab = 0;
  WorkoutAction? _activeAction;
  int _handledQuickActionToken = 0;
  String _activeBodyPart = '全部';
  String _lastFeedback = '刚好';
  bool _showOnlyUnfinished = false;
  int _defaultRestSeconds = 120;
  int _restSecondsLeft = 0;

  int get _totalGroups =>
      _actions.fold(0, (total, action) => total + action.groups);

  int get _finishedGroupsTotal => _actions.fold(
        0,
        (total, action) => total + _finishedGroupsFor(action),
      );

  int get _finishedActionCount => _actions
      .where((action) => _finishedGroupsFor(action) >= action.groups)
      .length;

  WorkoutAction get _nextAction => _actions.firstWhere(
        (action) => _finishedGroupsFor(action) < action.groups,
        orElse: () => _actions.last,
      );

  WorkoutPlan? get _activePlan {
    final session = widget.activeWorkoutSession;
    if (session == null) return null;
    for (final plan in widget.workoutPlans) {
      if (plan.id == session.planId) return plan;
    }
    return null;
  }

  WorkoutAction get _nextActionForCurrentScope {
    final session = widget.activeWorkoutSession;
    if (session == null) {
      return _nextAction;
    }
    final scopedActions = _actions
        .where((action) => session.actionProgress.containsKey(action.name))
        .toList();
    if (scopedActions.isEmpty) {
      return _nextAction;
    }
    return scopedActions.firstWhere(
      (action) => _finishedGroupsFor(action) < action.groups,
      orElse: () => scopedActions.last,
    );
  }

  List<WorkoutAction> get _currentScopeActions {
    final session = widget.activeWorkoutSession;
    if (session == null) {
      return _actions;
    }
    // 有训练会话时，菜单统计和未完成过滤只看当前计划内的动作。
    return _actions
        .where((action) => session.actionProgress.containsKey(action.name))
        .toList();
  }

  int get _currentScopeTotalGroups => _currentScopeActions.fold(
        0,
        (total, action) => total + action.groups,
      );

  int get _currentScopeFinishedGroups => _currentScopeActions.fold(
        0,
        (total, action) => total + _finishedGroupsFor(action),
      );

  bool get _activePlanCompleted {
    final session = widget.activeWorkoutSession;
    if (session == null || session.actionProgress.isEmpty) {
      return false;
    }
    final plannedActions = _actions
        .where((action) => session.actionProgress.containsKey(action.name))
        .toList();
    if (plannedActions.isEmpty) {
      return false;
    }
    return plannedActions
        .every((action) => session.groupsFor(action.name) >= action.groups);
  }

  int _finishedGroupsFor(WorkoutAction action) {
    final session = widget.activeWorkoutSession;
    if (session != null && session.actionProgress.containsKey(action.name)) {
      return session.groupsFor(action.name);
    }
    return widget.finishedGroupsByAction[action.name] ?? 0;
  }

  String _bodyPartLabel(String bodyPart) => bodyPart == '胸背' ? '胸背部' : bodyPart;

  @override
  void initState() {
    super.initState();
    _maybeHandleQuickAction();
  }

  @override
  void didUpdateWidget(covariant WorkoutModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  void _maybeHandleQuickAction() {
    if (widget.quickAction != WidgetQuickAction.startWorkout ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 小组件“练一组”进入下一个待完成动作，仍由用户确认开始，避免误触直接改训练数据。
      setState(() => _activeAction = _nextActionForCurrentScope);
      widget.onQuickActionHandled();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeAction != null) {
      return _WorkoutActionDetailPage(
        action: _activeAction!,
        finishedGroups: _finishedGroupsFor(_activeAction!),
        restSecondsLeft: _restSecondsLeft,
        feedback: _lastFeedback,
        onBack: () => setState(() => _activeAction = null),
        onStartGroup: _finishNextGroup,
        onFeedbackChanged: (feedback) =>
            setState(() => _lastFeedback = feedback),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _WorkoutHeader(
                  onOpenModules: widget.onOpenModules,
                  onOpenMore: _openMoreSheet,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: widget.moduleNav,
                ),
                _WorkoutTopTabs(
                  selected: _selectedTopTab,
                  onChanged: (index) => setState(() => _selectedTopTab = index),
                ),
                Expanded(child: _buildWorkoutContent()),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: moduleSwitchBarBottomGap),
                child: WorkoutBottomNav(
                  selectedIndex: _selectedBottomTab,
                  onChanged: _handleBottomNav,
                  keyPrefix: 'workout_bottom_nav',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutContent() {
    if (_selectedTopTab == 1) {
      return _WorkoutPlanView(
        plans: widget.workoutPlans,
        actions: _actions,
        onOpenPlan: _openPlanDetail,
      );
    }
    if (_selectedTopTab == 2) {
      return _WorkoutDataView(
        history: widget.workoutHistory,
        onOpenMetric: _openMetricDetail,
      );
    }
    if (_selectedTopTab == 3) {
      return _WorkoutHistoryView(
        history: widget.workoutHistory,
        onOpenHistory: _openHistoryDetail,
      );
    }
    final session = widget.activeWorkoutSession;
    final sourceActions = _currentScopeActions;
    final bodyPartActions = _activeBodyPart == '全部'
        ? sourceActions
        : sourceActions
            .where(
                (action) => _bodyPartLabel(action.bodyPart) == _activeBodyPart)
            .toList();
    final visibleActions = _showOnlyUnfinished
        ? bodyPartActions
            .where((action) => _finishedGroupsFor(action) < action.groups)
            .toList()
        : bodyPartActions;
    final actionCountLabel = _showOnlyUnfinished
        ? '未完成 ${visibleActions.length} / 全部 ${bodyPartActions.length}'
        : '${visibleActions.length} 个动作';
    final activePlan = _activePlan;

    return ListView(
      key: const ValueKey('workout_main_list'),
      padding: const EdgeInsets.fromLTRB(
          18, 18, 18, moduleSwitchBarReservedHeight + 24),
      children: [
        if (session != null) ...[
          _WorkoutActivePlanBanner(plan: activePlan, session: session),
          const SizedBox(height: 14),
          if (_activePlanCompleted) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _finishActivePlan,
                  child: const Text('完成训练'),
                ),
              ),
            ),
          ],
        ] else ...[
          _WorkoutSummaryCard(
            finishedActions: _finishedActionCount,
            totalActions: _actions.length,
            finishedGroups: _finishedGroupsTotal,
            totalGroups: _totalGroups,
            nextActionName: _nextActionForCurrentScope.name,
            onStart: () =>
                setState(() => _activeAction = _nextActionForCurrentScope),
          ),
          const SizedBox(height: 12),
          ModuleLinkedSummaryCard(
            title: '锻炼联动',
            subtitle: '训练组数会同步到健康和计划，饮食摄入辅助安排强度。',
            icon: Icons.fitness_center_rounded,
            values: [
              ('饮食', '${widget.foodCalories} kcal'),
              ('已练', '$_finishedGroupsTotal 组'),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _WorkoutBodyPartFilter(
          parts: _bodyParts,
          selected: _activeBodyPart,
          onChanged: (part) => setState(() => _activeBodyPart = part),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                '当前动作',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              actionCountLabel,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visibleActions.isEmpty)
          const _WorkoutEmptyPartCard()
        else
          ...visibleActions.map(
            (action) => _WorkoutActionCard(
              action: action,
              finishedGroups: _finishedGroupsFor(action),
              onTap: () => setState(() {
                _activeAction = action;
              }),
            ),
          ),
        const SizedBox(height: 2),
        _WorkoutTodayStatsCard(
          finishedGroups: _finishedGroupsTotal,
          totalGroups: _totalGroups,
          feedback: _lastFeedback,
        ),
        if (session == null) ...[
          const SizedBox(height: 12),
          _WorkoutFoodLinkCard(
            foodCalories: widget.foodCalories,
            onOpenFood: () => widget.onSwitchModule(LifeModule.food),
          ),
        ],
      ],
    );
  }

  List<WorkoutAction> _actionsForPlan(WorkoutPlan plan) {
    return _actions
        .where((action) => plan.actionNames.contains(action.name))
        .toList();
  }

  WorkoutAction? _actionByName(String actionName) {
    for (final action in _actions) {
      if (action.name == actionName) {
        return action;
      }
    }
    return null;
  }

  Future<void> _openPlanDetail(WorkoutPlan plan) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutPlanDetailSheet(
          plan: plan,
          actions: _actionsForPlan(plan),
          onEdit: () {
            Navigator.of(context).pop();
            _openPlanEdit(plan);
          },
          onStart: () {
            Navigator.of(context).pop();
            _startPlanTraining(plan);
          },
        );
      },
    );
  }

  Future<void> _openMetricDetail(WorkoutMetricDetail detail) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutMetricDetailSheet(detail: detail);
      },
    );
  }

  Future<void> _openPlanEdit(WorkoutPlan plan) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutPlanEditSheet(
          plan: _latestPlan(plan),
          allActions: _actions,
          onChanged: widget.onUpdateWorkoutPlan,
        );
      },
    );
  }

  // 汇总当前训练状态，生成右上角“三点”菜单需要的启用/禁用状态。
  Future<void> _openMoreSheet() {
    final session = widget.activeWorkoutSession;
    final activePlan = _activePlan;
    final canFinishTraining = session != null &&
        session.actionProgress.values.any((groups) => groups > 0);
    final canResetProgress = widget.finishedGroupsByAction.values
            .any((groups) => groups > 0) ||
        (session?.actionProgress.values.any((groups) => groups > 0) ?? false);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutMoreSheet(
          hasActiveSession: session != null,
          canFinishTraining: canFinishTraining,
          canEditActivePlan: activePlan != null,
          canResetProgress: canResetProgress,
          hasHistory: widget.workoutHistory.isNotEmpty,
          showOnlyUnfinished: _showOnlyUnfinished,
          defaultRestSeconds: _defaultRestSeconds,
          finishedGroups: _currentScopeFinishedGroups,
          totalGroups: _currentScopeTotalGroups,
          historyCount: widget.workoutHistory.length,
          activePlanName: activePlan?.name ?? session?.planName,
          onContinueTraining: _continueOrStartTraining,
          onFinishTraining: _finishActivePlan,
          onShowOnlyUnfinishedChanged: _setShowOnlyUnfinished,
          onRestSecondsChanged: _setDefaultRestSeconds,
          onEditActivePlan: _editActivePlan,
          onCreatePlan: _createWorkoutPlan,
          onCopyActivePlan: _copyActivePlan,
          onResetProgress: _confirmResetTodayProgress,
          onExportHistory: _exportWorkoutHistory,
        );
      },
    );
  }

  // 无论当前在哪个 tab，都回到训练页并打开下一项可执行动作。
  void _continueOrStartTraining() {
    setState(() {
      _selectedTopTab = 0;
      _activeAction = _nextActionForCurrentScope;
    });
  }

  void _setShowOnlyUnfinished(bool value) {
    setState(() => _showOnlyUnfinished = value);
  }

  void _setDefaultRestSeconds(int seconds) {
    setState(() => _defaultRestSeconds = seconds);
  }

  void _editActivePlan() {
    final plan = _activePlan;
    if (plan == null) {
      return;
    }
    _openPlanEdit(plan);
  }

  // 新建计划先创建空壳，再复用现有编辑 Sheet 选择动作。
  void _createWorkoutPlan() {
    final now = DateTime.now();
    final plan = WorkoutPlan(
      name: '自定义训练',
      target: '按当天状态自由组合',
      bodyParts: const [],
      actionNames: const [],
      estimatedMinutes: 20,
      createdAt: now,
      updatedAt: now,
    );
    widget.onUpdateWorkoutPlan(plan);
    _openPlanEdit(plan);
  }

  // 复制计划必须生成新 id，避免覆盖正在训练的原计划。
  void _copyActivePlan() {
    final plan = _activePlan;
    if (plan == null) {
      return;
    }
    final now = DateTime.now();
    final copy = WorkoutPlan(
      name: '${plan.name} 副本',
      target: plan.target,
      bodyParts: plan.bodyParts,
      actionNames: plan.actionNames,
      estimatedMinutes: plan.estimatedMinutes,
      createdAt: now,
      updatedAt: now,
    );
    widget.onUpdateWorkoutPlan(copy);
    _showWorkoutSnack('已复制训练计划');
  }

  // 重置今日进度是破坏性操作，先让用户二次确认。
  Future<void> _confirmResetTodayProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('重置今日进度'),
          content: const Text('会清空今天已记录的动作组数，训练历史不会删除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('重置'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      _resetTodayProgress();
    }
  }

  void _resetTodayProgress() {
    final session = widget.activeWorkoutSession;
    // 今日进度同时存在全局动作组数和当前训练会话里，重置时要两处保持一致。
    for (final action in _actions) {
      widget.onUpdateActionGroups(action.name, 0);
    }
    if (session != null) {
      widget.onUpdateWorkoutSession(
        session.copyWith(
          actionProgress: {
            for (final actionName in session.actionProgress.keys) actionName: 0,
          },
        ),
      );
    }
    setState(() {
      _activeAction = null;
      _restSecondsLeft = 0;
    });
    _showWorkoutSnack('今日进度已重置');
  }

  // 第一版导出走剪贴板，避免提前引入文件权限和分享插件。
  Future<void> _exportWorkoutHistory() async {
    await Clipboard.setData(ClipboardData(text: _workoutHistoryExportText()));
    _showWorkoutSnack('训练历史已复制');
  }

  String _workoutHistoryExportText() {
    final buffer = StringBuffer('训练历史\n');
    for (final entry in widget.workoutHistory) {
      // 导出内容先做成可读文本，后续如果需要文件分享可以复用这份摘要。
      buffer
        ..writeln('\n${entry.planName}')
        ..writeln('开始：${_formatWorkoutDateTime(entry.startedAt)}')
        ..writeln('完成：${_formatWorkoutDateTime(entry.finishedAt)}')
        ..writeln('时长：${entry.durationMinutes} 分钟')
        ..writeln('总组数：${entry.totalGroups} 组')
        ..writeln('预估消耗：${entry.estimatedCalories} kcal')
        ..writeln('反馈：${entry.feedback}');
      for (final result in entry.actionResults) {
        buffer.writeln(
          '- ${result.actionName}：${result.finishedGroups}/${result.targetGroups} 组 · ${result.reps}',
        );
      }
    }
    return buffer.toString().trimRight();
  }

  String _formatWorkoutDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-$month-$day $hour:$minute';
  }

  void _showWorkoutSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  WorkoutPlan _latestPlan(WorkoutPlan plan) {
    return widget.workoutPlans.firstWhere(
      (item) => item.id == plan.id,
      orElse: () => plan,
    );
  }

  Future<void> _openHistoryDetail(WorkoutHistoryEntry entry) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _WorkoutHistoryDetailSheet(
          entry: entry,
          onRestart: () {
            Navigator.of(context).pop();
            _restartPlanFromHistory(entry);
          },
        );
      },
    );
  }

  void _restartPlanFromHistory(WorkoutHistoryEntry entry) {
    final plan = widget.workoutPlans.firstWhere(
      (plan) => plan.id == entry.planId,
      orElse: () => WorkoutPlan(
        id: entry.planId,
        name: entry.planName,
        target: '再次训练',
        bodyParts: entry.actionResults
            .map((result) => _bodyPartLabel(result.bodyPart))
            .toSet()
            .toList(),
        actionNames:
            entry.actionResults.map((result) => result.actionName).toList(),
        estimatedMinutes: entry.durationMinutes,
      ),
    );
    _startPlanTraining(plan);
  }

  void _startPlanTraining(WorkoutPlan plan) {
    final planActions = _actionsForPlan(plan);
    if (planActions.isEmpty) return;
    final progress = {for (final action in planActions) action.name: 0};
    final session = ActiveWorkoutSession(
      planId: plan.id,
      planName: plan.name,
      startedAt: DateTime.now(),
      actionProgress: progress,
    );
    widget.onStartWorkoutSession(session);
    setState(() {
      _selectedTopTab = 0;
      _activeBodyPart = '全部';
      _activeAction = null;
    });
  }

  void _finishNextGroup() {
    final action = _activeAction;
    if (action == null) {
      return;
    }
    final currentGroups = _finishedGroupsFor(action);
    final nextCount = math.min(action.groups, currentGroups + 1);
    final session = widget.activeWorkoutSession;
    if (session != null && session.actionProgress.containsKey(action.name)) {
      final nextProgress = Map<String, int>.of(session.actionProgress);
      nextProgress[action.name] = nextCount;
      widget.onUpdateWorkoutSession(
        session.copyWith(
          actionProgress: nextProgress,
          feedback: _lastFeedback,
        ),
      );
    }
    widget.onUpdateActionGroups(action.name, nextCount);
    setState(() => _restSecondsLeft =
        nextCount >= action.groups ? 0 : _defaultRestSeconds);
  }

  void _finishActivePlan() {
    final session = widget.activeWorkoutSession;
    if (session == null) {
      return;
    }
    final now = DateTime.now();
    final actionResults = <WorkoutActionResult>[];
    for (final actionName in session.actionProgress.keys) {
      final action = _actionByName(actionName);
      if (action == null) {
        continue;
      }
      actionResults.add(
        WorkoutActionResult(
          actionName: action.name,
          bodyPart: action.bodyPart,
          targetGroups: action.groups,
          finishedGroups: session.groupsFor(action.name),
          reps: action.reps,
          weight: action.weight,
        ),
      );
    }
    final totalGroups = actionResults.fold<int>(
      0,
      (total, result) => total + result.finishedGroups,
    );
    final entry = WorkoutHistoryEntry(
      planId: session.planId,
      planName: session.planName,
      startedAt: session.startedAt,
      finishedAt: now,
      durationMinutes: math.max(1, now.difference(session.startedAt).inMinutes),
      totalGroups: totalGroups,
      estimatedCalories: 80 + totalGroups * 18,
      actionResults: actionResults,
      feedback: _lastFeedback,
    );
    widget.onFinishWorkoutSession(entry);
    setState(() {
      _selectedTopTab = 3;
      _activeAction = null;
      _restSecondsLeft = 0;
    });
  }

  void _handleBottomNav(int index) {
    setState(() => _selectedBottomTab = index);
  }
}
