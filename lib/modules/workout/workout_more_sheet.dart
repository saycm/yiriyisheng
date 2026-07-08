// 中文注释：锻炼模块源码，负责动作库、训练计划、训练记录和更多菜单。

part of 'workout.dart';

// 锻炼页右上角“三点”菜单，只负责展示入口；实际数据变更交给 WorkoutModulePage。
class _WorkoutMoreSheet extends StatefulWidget {
  const _WorkoutMoreSheet({
    required this.hasActiveSession,
    required this.canFinishTraining,
    required this.canEditActivePlan,
    required this.canResetProgress,
    required this.hasHistory,
    required this.showOnlyUnfinished,
    required this.defaultRestSeconds,
    required this.finishedGroups,
    required this.totalGroups,
    required this.historyCount,
    required this.activePlanName,
    required this.onContinueTraining,
    required this.onFinishTraining,
    required this.onShowOnlyUnfinishedChanged,
    required this.onRestSecondsChanged,
    required this.onEditActivePlan,
    required this.onCreatePlan,
    required this.onCopyActivePlan,
    required this.onResetProgress,
    required this.onExportHistory,
  });

  final bool hasActiveSession;
  final bool canFinishTraining;
  final bool canEditActivePlan;
  final bool canResetProgress;
  final bool hasHistory;
  final bool showOnlyUnfinished;
  final int defaultRestSeconds;
  final int finishedGroups;
  final int totalGroups;
  final int historyCount;
  final String? activePlanName;
  final VoidCallback onContinueTraining;
  final VoidCallback onFinishTraining;
  final ValueChanged<bool> onShowOnlyUnfinishedChanged;
  final ValueChanged<int> onRestSecondsChanged;
  final VoidCallback onEditActivePlan;
  final VoidCallback onCreatePlan;
  final VoidCallback onCopyActivePlan;
  final VoidCallback onResetProgress;
  final VoidCallback onExportHistory;

  @override
  State<_WorkoutMoreSheet> createState() => _WorkoutMoreSheetState();
}

class _WorkoutMoreSheetState extends State<_WorkoutMoreSheet> {
  late bool _showOnlyUnfinished = widget.showOnlyUnfinished;
  late int _restSeconds = widget.defaultRestSeconds;

  @override
  Widget build(BuildContext context) {
    final activePlanName = widget.activePlanName ?? '未选择计划';

    return InfoSheetFrame(
      title: '锻炼选项',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkoutMoreStatusCard(
            activePlanName: activePlanName,
            hasActiveSession: widget.hasActiveSession,
            finishedGroups: widget.finishedGroups,
            totalGroups: widget.totalGroups,
          ),
          const SizedBox(height: 16),
          _WorkoutMoreSection(
            title: '训练',
            children: [
              _WorkoutMoreActionTile(
                keyValue: 'workout_more_continue',
                icon: widget.hasActiveSession
                    ? Icons.play_circle_fill_rounded
                    : Icons.arrow_forward_rounded,
                title: widget.hasActiveSession ? '继续当前训练' : '开始下一个动作',
                subtitle:
                    widget.hasActiveSession ? activePlanName : '进入下一项未完成动作',
                onTap: () => _closeAndRun(widget.onContinueTraining),
              ),
              _WorkoutMoreActionTile(
                keyValue: 'workout_more_finish_training',
                icon: Icons.check_circle_rounded,
                title: '完成当前训练',
                subtitle: '生成一条训练历史记录',
                enabled: widget.canFinishTraining,
                onTap: () => _closeAndRun(widget.onFinishTraining),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WorkoutMoreSection(
            title: '显示',
            children: [
              _WorkoutMoreSwitchTile(
                keyValue: 'workout_more_unfinished_only',
                icon: Icons.filter_alt_rounded,
                title: '只看未完成动作',
                value: _showOnlyUnfinished,
                onChanged: (value) {
                  setState(() => _showOnlyUnfinished = value);
                  widget.onShowOnlyUnfinishedChanged(value);
                },
              ),
              const SizedBox(height: 12),
              _WorkoutRestTimeSelector(
                selectedSeconds: _restSeconds,
                onChanged: (seconds) {
                  setState(() => _restSeconds = seconds);
                  widget.onRestSecondsChanged(seconds);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WorkoutMoreSection(
            title: '计划',
            children: [
              _WorkoutMoreActionTile(
                keyValue: 'workout_more_edit_plan',
                icon: Icons.edit_rounded,
                title: '编辑当前计划',
                subtitle: activePlanName,
                enabled: widget.canEditActivePlan,
                onTap: () => _closeAndRun(widget.onEditActivePlan),
              ),
              _WorkoutMoreActionTile(
                keyValue: 'workout_more_create_plan',
                icon: Icons.add_task_rounded,
                title: '新建训练计划',
                subtitle: '创建空计划后选择动作',
                onTap: () => _closeAndRun(widget.onCreatePlan),
              ),
              _WorkoutMoreActionTile(
                keyValue: 'workout_more_copy_plan',
                icon: Icons.copy_rounded,
                title: '复制当前计划',
                subtitle: '保留动作和目标，生成副本',
                enabled: widget.canEditActivePlan,
                onTap: () => _closeAndRun(widget.onCopyActivePlan),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WorkoutMoreSection(
            title: '数据',
            children: [
              _WorkoutMoreActionTile(
                keyValue: 'workout_more_reset_progress',
                icon: Icons.restart_alt_rounded,
                title: '重置今日进度',
                subtitle: '清空动作组数和当前会话进度',
                enabled: widget.canResetProgress,
                destructive: true,
                onTap: () => _closeAndRun(widget.onResetProgress),
              ),
              _WorkoutMoreActionTile(
                keyValue: 'workout_more_export_history',
                icon: Icons.ios_share_rounded,
                title: '导出训练历史',
                subtitle: '${widget.historyCount} 条历史记录',
                enabled: widget.hasHistory,
                onTap: () => _closeAndRun(widget.onExportHistory),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _closeAndRun(VoidCallback callback) {
    Navigator.of(context).pop();
    // 先关闭底部弹层，再执行页面跳转或二次弹窗，避免两个 Route 动画互相抢焦点。
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }
}

class _WorkoutMoreStatusCard extends StatelessWidget {
  const _WorkoutMoreStatusCard({
    required this.activePlanName,
    required this.hasActiveSession,
    required this.finishedGroups,
    required this.totalGroups,
  });

  final String activePlanName;
  final bool hasActiveSession;
  final int finishedGroups;
  final int totalGroups;

  @override
  Widget build(BuildContext context) {
    final progress = totalGroups == 0
        ? 0.0
        : (finishedGroups / totalGroups).clamp(0, 1).toDouble();

    return KeyedSubtree(
      key: const ValueKey('workout_more_status_card'),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.78),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasActiveSession ? '当前训练' : '今日动作库',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activePlanName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.background,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutMoreSection extends StatelessWidget {
  const _WorkoutMoreSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _WorkoutMoreActionTile extends StatelessWidget {
  const _WorkoutMoreActionTile({
    required this.keyValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  final String keyValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.financeRed : AppColors.primary;
    final effectiveColor = enabled ? color : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: ValueKey(keyValue),
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: effectiveColor, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? AppColors.ink : AppColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled ? AppColors.muted : AppColors.line,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutMoreSwitchTile extends StatelessWidget {
  const _WorkoutMoreSwitchTile({
    required this.keyValue,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String keyValue;
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(keyValue),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _WorkoutRestTimeSelector extends StatelessWidget {
  const _WorkoutRestTimeSelector({
    required this.selectedSeconds,
    required this.onChanged,
  });

  final int selectedSeconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [60, 90, 120, 180];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '休息时间',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((seconds) {
            final selected = selectedSeconds == seconds;
            return ChoiceChip(
              key: ValueKey('workout_rest_${seconds}s'),
              label: Text('${seconds}s'),
              selected: selected,
              selectedColor: AppColors.primarySoft,
              backgroundColor: AppColors.background,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
              side: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (_) => onChanged(seconds),
            );
          }).toList(),
        ),
      ],
    );
  }
}
