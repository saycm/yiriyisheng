// 中文注释：锻炼模块源码，负责动作库、训练计划、训练记录和更多菜单。

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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkoutCalendarCard(history: history),
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
  const _WorkoutCalendarCard({required this.history});

  final List<WorkoutHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = today.subtract(const Duration(days: 6));
    final days = List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final records = history
          .where((entry) => DateUtils.isSameDay(entry.finishedAt, date))
          .toList();
      final groups = records.fold<int>(
        0,
        (total, entry) => total + entry.totalGroups,
      );
      return _WorkoutCalendarDayData(
        date: date,
        sessions: records.length,
        groups: groups,
        isToday: DateUtils.isSameDay(date, today),
      );
    });

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
                      data: day,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _WorkoutCalendarLegendItem(
                color: AppColors.primary,
                label: '蓝色边框：今天',
                outlined: true,
              ),
              _WorkoutCalendarLegendItem(
                color: AppColors.success,
                label: '绿色圆点：有训练',
              ),
              _WorkoutCalendarLegendItem(
                color: AppColors.muted,
                label: '灰色：空档',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutCalendarDayData {
  const _WorkoutCalendarDayData({
    required this.date,
    required this.sessions,
    required this.groups,
    required this.isToday,
  });

  final DateTime date;
  final int sessions;
  final int groups;
  final bool isToday;

  bool get hasTraining => sessions > 0;
}

class _WorkoutCalendarDay extends StatelessWidget {
  const _WorkoutCalendarDay({required this.data});

  final _WorkoutCalendarDayData data;

  @override
  Widget build(BuildContext context) {
    final week =
        const ['一', '二', '三', '四', '五', '六', '日'][data.date.weekday - 1];
    final dayKey = data.isToday
        ? 'workout_calendar_day_today'
        : 'workout_calendar_day_${data.date.toIso8601String()}';
    final dateColor = data.isToday
        ? AppColors.primary
        : data.hasTraining
            ? AppColors.ink
            : AppColors.muted;

    return Semantics(
      label:
          '${data.date.month}月${data.date.day}日${data.isToday ? '，今天' : ''}${data.hasTraining ? '，已训练${data.sessions}次，共${data.groups}组' : '，空档'}',
      child: Column(
        key: ValueKey(dayKey),
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
              color: data.isToday
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: data.isToday
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : AppColors.line,
              ),
            ),
            child: Center(
              child: Text(
                '${data.date.day}',
                style: TextStyle(
                  color: dateColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 12,
            child: data.hasTraining
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${data.sessions}次',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  )
                : Text(
                    data.isToday ? '今天' : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCalendarLegendItem extends StatelessWidget {
  const _WorkoutCalendarLegendItem({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: outlined ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
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
