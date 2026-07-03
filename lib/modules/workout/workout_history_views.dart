part of 'workout.dart';

class _WorkoutHistoryDetailSheet extends StatelessWidget {
  const _WorkoutHistoryDetailSheet({
    required this.entry,
    required this.onRestart,
  });

  final WorkoutHistoryEntry entry;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        key: const ValueKey('workout_history_detail_sheet'),
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.planName,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              '${entry.totalGroups} 组 · ${entry.durationMinutes} min',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ...entry.actionResults.map(
              (result) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${result.actionName} ${result.finishedGroups}/${result.targetGroups} 组',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: onRestart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.replay_rounded),
                label: const Text(
                  '再次训练',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutHistoryView extends StatelessWidget {
  const _WorkoutHistoryView({
    required this.history,
    required this.onOpenHistory,
  });

  final List<WorkoutHistoryEntry> history;
  final ValueChanged<WorkoutHistoryEntry> onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: history.isEmpty ? null : const ValueKey('workout_history_real_list'),
      padding: const EdgeInsets.fromLTRB(
          18, 18, 18, moduleSwitchBarReservedHeight + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WorkoutCalendarCard(),
          const SizedBox(height: 12),
          const _WorkoutActionTrendCard(),
          const SizedBox(height: 12),
          const _WorkoutProgressTrendCard(),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const _WorkoutEmptyHistoryCard()
          else
            ...history.map(
              (entry) => _WorkoutHistoryTile(
                title: entry.planName,
                subtitle:
                    '${entry.actionResults.length} 个动作 · ${entry.totalGroups} 组 · ${entry.durationMinutes} min',
                status: _historyStatusLabel(entry.finishedAt),
                color: AppColors.primary,
                onTap: () => onOpenHistory(entry),
              ),
            ),
        ],
      ),
    );
  }

  String _historyStatusLabel(DateTime finishedAt) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(finishedAt, now)) {
      return '今天';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(finishedAt, yesterday)) {
      return '昨天';
    }
    return '${finishedAt.month}/${finishedAt.day}';
  }
}

class _WorkoutEmptyHistoryCard extends StatelessWidget {
  const _WorkoutEmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '暂无训练记录',
        style: TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WorkoutCalendarCard extends StatelessWidget {
  const _WorkoutCalendarCard();

  @override
  Widget build(BuildContext context) {
    final days = [
      ('一', '12', true, AppColors.success),
      ('二', '13', false, AppColors.muted),
      ('三', '14', true, AppColors.primary),
      ('四', '15', false, AppColors.muted),
      ('五', '16', true, const Color(0xFFFF9559)),
      ('六', '17', true, AppColors.primary),
      ('日', '18', false, AppColors.muted),
    ];

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
          const Text(
            '训练日历',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            key: const ValueKey('workout_calendar_strip'),
            children: days
                .map(
                  (day) => Expanded(
                    child: _WorkoutCalendarDay(
                      week: day.$1,
                      date: day.$2,
                      trained: day.$3,
                      color: day.$4,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCalendarDay extends StatelessWidget {
  const _WorkoutCalendarDay({
    required this.week,
    required this.date,
    required this.trained,
    required this.color,
  });

  final String week;
  final String date;
  final bool trained;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          week,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                trained ? color.withValues(alpha: 0.14) : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: trained ? color.withValues(alpha: 0.35) : AppColors.line,
            ),
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                color: trained ? color : AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutActionTrendCard extends StatelessWidget {
  const _WorkoutActionTrendCard();

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
        children: const [
          Text(
            '动作历史曲线',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _WorkoutTrendRow(
            title: '蝴蝶机夹胸',
            subtitle: '最近 4 次',
            values: [24, 28, 30, 35],
            color: AppColors.primary,
          ),
          SizedBox(height: 10),
          _WorkoutTrendRow(
            title: '宽握高位下拉',
            subtitle: '最近 4 次',
            values: [26, 28, 30, 32],
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _WorkoutTrendRow extends StatelessWidget {
  const _WorkoutTrendRow({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.color,
  });

  final String title;
  final String subtitle;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce(math.max);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 116,
          height: 36,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: values
                .map(
                  (value) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: FractionallySizedBox(
                        heightFactor: value / maxValue,
                        alignment: Alignment.bottomCenter,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _WorkoutProgressTrendCard extends StatelessWidget {
  const _WorkoutProgressTrendCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _WorkoutProgressTrendTile(
            title: '重量进步',
            value: '30kg → 35kg',
            subtitle: '蝴蝶机夹胸',
            icon: Icons.monitor_weight_rounded,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _WorkoutProgressTrendTile(
            title: '次数进步',
            value: '8次 → 12次',
            subtitle: '宽握高位下拉',
            icon: Icons.repeat_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _WorkoutProgressTrendTile extends StatelessWidget {
  const _WorkoutProgressTrendTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHistoryTile extends StatelessWidget {
  const _WorkoutHistoryTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: color,
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
