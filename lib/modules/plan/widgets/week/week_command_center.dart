// 中文注释：计划周视图命令中心，负责一周统计、洞察和快捷排程按钮。

part of '../../plan.dart';

class _WeekCommandCenter extends StatelessWidget {
  const _WeekCommandCenter({
    required this.weekTodos,
    required this.completedCount,
    required this.unscheduledCount,
    required this.riskCount,
    required this.insight,
    required this.onAutoSchedule,
    required this.onBalanceWeek,
    required this.onMoveLowPriorityNextWeek,
    required this.onCleanOverdue,
  });

  final int weekTodos;
  final int completedCount;
  final int unscheduledCount;
  final int riskCount;
  final String insight;
  final VoidCallback? onAutoSchedule;
  final VoidCallback onBalanceWeek;
  final VoidCallback onMoveLowPriorityNextWeek;
  final VoidCallback? onCleanOverdue;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week_plan_command_center'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _weekCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '一周安排工作台',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insight,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _WeekMetricTile(
                  label: '本周',
                  value: '$weekTodos',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _WeekMetricTile(
                  label: '完成',
                  value: '$completedCount',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _WeekMetricTile(
                  label: '待安排',
                  value: '$unscheduledCount',
                  color: const Color(0xFFFF9559),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _WeekMetricTile(
                  label: '风险',
                  value: '$riskCount',
                  color: AppColors.financeRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('week_plan_auto_schedule'),
              onPressed: onAutoSchedule,
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: const Text('一键排周'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primarySoft,
                disabledForegroundColor: AppColors.muted,
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _WeekCommandButton(
                  key: const ValueKey('week_plan_balance_week'),
                  onPressed: onBalanceWeek,
                  icon: Icons.balance_rounded,
                  label: '平衡本周',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _WeekCommandButton(
                  key: const ValueKey('week_plan_clean_overdue'),
                  onPressed: onCleanOverdue,
                  icon: Icons.history_toggle_off_rounded,
                  label: '清理逾期',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _WeekCommandButton(
                  key: const ValueKey('week_plan_move_low_priority_next_week'),
                  onPressed: onMoveLowPriorityNextWeek,
                  icon: Icons.low_priority_rounded,
                  label: '低优先级移到下周',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekCommandButton extends StatelessWidget {
  const _WeekCommandButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.muted.withValues(alpha: 0.7),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.24)),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(
            fontSize: 11,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekMetricTile extends StatelessWidget {
  const _WeekMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
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
    );
  }
}
