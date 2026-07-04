// 中文注释：锻炼模块源码，负责动作库、训练计划、训练记录和更多菜单。

// ignore_for_file: use_key_in_widget_constructors
part of 'workout.dart';

class _WorkoutActionCard extends StatelessWidget {
  const _WorkoutActionCard({
    required this.action,
    required this.finishedGroups,
    required this.onTap,
  });

  final WorkoutAction action;
  final int finishedGroups;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = finishedGroups >= action.groups;
    final started = finishedGroups > 0;
    final status = completed ? '已完成' : (started ? '进行中' : action.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _WorkoutActionArt(
                  action: action,
                  size: 48,
                  radius: 8,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      action.detail,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _WorkoutActionTag(
                            label: action.bodyPart == '胸背'
                                ? '胸背部'
                                : action.bodyPart),
                        _WorkoutActionTag(label: action.reps),
                        if (action.weight != null)
                          _WorkoutActionTag(label: action.weight!),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: completed ? AppColors.success : AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$finishedGroups/${action.groups} 组 ›',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutActionArt extends StatelessWidget {
  const _WorkoutActionArt({
    required this.action,
    required this.size,
    required this.radius,
    this.iconSize = 28,
  });

  final WorkoutAction action;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: ValueKey('workout_action_art_${action.name}'),
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        action.imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) {
          return Center(
            child: Icon(action.icon, color: AppColors.primary, size: iconSize),
          );
        },
      ),
    );
  }
}

class _WorkoutActionTag extends StatelessWidget {
  const _WorkoutActionTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WorkoutActionDetailPage extends StatelessWidget {
  const _WorkoutActionDetailPage({
    required this.action,
    required this.finishedGroups,
    required this.restSecondsLeft,
    required this.feedback,
    required this.onBack,
    required this.onStartGroup,
    required this.onFeedbackChanged,
  });

  final WorkoutAction action;
  final int finishedGroups;
  final int restSecondsLeft;
  final String feedback;
  final VoidCallback onBack;
  final VoidCallback onStartGroup;
  final ValueChanged<String> onFeedbackChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          key: const ValueKey('workout_action_detail_list'),
          padding: const EdgeInsets.fromLTRB(
              18, 10, 18, 112 + moduleSwitchBarReservedHeight),
          children: [
            Row(
              children: [
                IconBubble(
                  icon: Icons.arrow_back_ios_new_rounded,
                  color: AppColors.ink,
                  onTap: onBack,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      action.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _WorkoutActionArt(
                          action: action,
                          size: 58,
                          radius: 8,
                          iconSize: 34,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.name,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              action.detail,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '未开始',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _WorkoutProgressBox(
                          label: '已完成',
                          value: '$finishedGroups/${action.groups}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WorkoutProgressBox(
                          label: '当前休息',
                          value: restSecondsLeft == 0
                              ? '未开始'
                              : _formatRest(restSecondsLeft),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(action.groups, (index) {
                      final done = index < finishedGroups;
                      return Expanded(
                        child: Container(
                          height: 12,
                          margin: EdgeInsets.only(
                            right: index == action.groups - 1 ? 0 : 7,
                          ),
                          decoration: BoxDecoration(
                            color: done
                                ? AppColors.primary
                                : const Color(0xFFDCE2EE),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '准备开始',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restSecondsLeft == 0
                        ? '开始后按组记录，完成一组会自动开启 2 分钟休息提醒。'
                        : '正在休息 ${_formatRest(restSecondsLeft)}，下一组准备好后继续。',
                    style: TextStyle(
                      color: restSecondsLeft == 0
                          ? AppColors.ink
                          : AppColors.primary,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: onStartGroup,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        '开始动作',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _WorkoutActionMetaCard(action: action),
            const SizedBox(height: 18),
            _WorkoutFeedbackCard(
              selected: feedback,
              onChanged: onFeedbackChanged,
            ),
            const SizedBox(height: 18),
            ...List.generate(action.groups, (index) {
              final done = index < finishedGroups;
              return _WorkoutSetCard(
                index: index + 1,
                done: done,
                detail: action.detail.replaceFirst('${action.groups}组 × ', ''),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatRest(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

class _WorkoutProgressBox extends StatelessWidget {
  const _WorkoutProgressBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutActionMetaCard extends StatelessWidget {
  const _WorkoutActionMetaCard({required this.action});

  final WorkoutAction action;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('部位', action.bodyPart),
      ('目标组数', '${action.groups} 组'),
      ('次数', action.reps),
      ('重量', action.weight ?? '自重'),
    ];

    return Container(
      key: const ValueKey('workout_feedback_card'),
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
            '动作字段',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: values.map((item) {
              return _WorkoutActionFieldBox(label: item.$1, value: item.$2);
            }).toList(),
          ),
          if (action.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              action.note,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 动作字段卡只展示静态信息，单独控制行高和垂直居中，避免复用进度卡后文字显得歪。
class _WorkoutActionFieldBox extends StatelessWidget {
  const _WorkoutActionFieldBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: const StrutStyle(
                fontSize: 13,
                height: 1.1,
                forceStrutHeight: true,
              ),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: const StrutStyle(
                fontSize: 17,
                height: 1.1,
                forceStrutHeight: true,
              ),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutFeedbackCard extends StatelessWidget {
  const _WorkoutFeedbackCard({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = ['轻松', '刚好', '太累'];

    return Container(
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
            '训练反馈',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((option) {
              final active = selected == option;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: option == options.last ? 0 : 8,
                  ),
                  child: ChoiceChip(
                    key: ValueKey('workout_feedback_$option'),
                    selected: active,
                    onSelected: (_) => onChanged(option),
                    label: Center(child: Text(option)),
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: active ? AppColors.primary : AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WorkoutSetCard extends StatelessWidget {
  const _WorkoutSetCard({
    required this.index,
    required this.done,
    required this.detail,
  });

  final int index;
  final bool done;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: done ? AppColors.primary : AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  color: done ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第 $index 组',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            done ? Icons.check_circle_rounded : Icons.expand_more_rounded,
            color: done ? AppColors.success : AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class WorkoutBottomNav extends StatelessWidget {
  const WorkoutBottomNav({
    required this.selectedIndex,
    required this.onChanged,
    required this.keyPrefix,
    this.items = const [
      (Icons.fitness_center_rounded, '锻炼'),
    ],
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final String keyPrefix;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return CapsuleNav(
      selectedIndex: selectedIndex,
      items: items,
      onChanged: onChanged,
      softCompact: true,
      keyPrefix: keyPrefix,
    );
  }
}
