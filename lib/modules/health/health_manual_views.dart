// 中文注释：健康模块源码，负责健康数据、手动记录和系统健康数据接入。

part of 'health.dart';

class _HealthManualRecord {
  const _HealthManualRecord({
    required this.bodyTag,
    required this.energyLevel,
    required this.fatigueLevel,
    required this.stressLevel,
    required this.painNote,
    required this.moodNote,
  });

  final String bodyTag;
  final double energyLevel;
  final double fatigueLevel;
  final double stressLevel;
  final String painNote;
  final String moodNote;
}

class _HealthManualStatusCard extends StatelessWidget {
  const _HealthManualStatusCard({
    required this.bodyTag,
    required this.energyLevel,
    required this.fatigueLevel,
    required this.stressLevel,
    required this.painNote,
    required this.moodNote,
    required this.onTap,
  });

  final String bodyTag;
  final int energyLevel;
  final int fatigueLevel;
  final int stressLevel;
  final String painNote;
  final String moodNote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final painText = painNote.trim().isEmpty ? '无明显疼痛' : painNote.trim();

    return InkWell(
      key: const ValueKey('health_manual_status_card'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6F9D).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: Color(0xFFFF6F9D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '状态记录',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$bodyTag · 心情 $moodNote',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HealthManualPill(
                    label: '精神',
                    value: '$energyLevel/5',
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HealthManualPill(
                    label: '疲劳',
                    value: '$fatigueLevel/5',
                    color: const Color(0xFFFF9559),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HealthManualPill(
                    label: '压力',
                    value: '$stressLevel/5',
                    color: const Color(0xFFFF7A83),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              painText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthManualPill extends StatelessWidget {
  const _HealthManualPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthReminderCard extends StatelessWidget {
  const _HealthReminderCard({required this.reminders});

  final List<String> reminders;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('health_reminder_card'),
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.health_and_safety_rounded,
                  color: AppColors.primary, size: 21),
              SizedBox(width: 8),
              Text(
                '健康提醒',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...reminders.map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      reminder,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTrendDashboardCard extends StatelessWidget {
  const _HealthTrendDashboardCard({required this.day});

  final HealthDay day;

  @override
  Widget build(BuildContext context) {
    final stepMetric =
        day.metrics.firstWhere((metric) => metric.title == '今日步数');
    final sleepMetric =
        day.metrics.firstWhere((metric) => metric.title == '昨晚睡眠');
    final heartMetric = day.metrics.firstWhere(
      (metric) => metric.title == '今日心率' || metric.title == '实时心率',
    );
    final activeMetric =
        day.metrics.firstWhere((metric) => metric.title == '今日能量');

    return Container(
      key: const ValueKey('health_trend_dashboard_card'),
      height: 178,
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
            '最近 7 天趋势',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _HealthTrendMiniChart(metric: stepMetric),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HealthTrendMiniChart(metric: sleepMetric),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HealthTrendMiniChart(metric: heartMetric),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HealthTrendMiniChart(metric: activeMetric),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTrendMiniChart extends StatelessWidget {
  const _HealthTrendMiniChart({required this.metric});

  final HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomPaint(
            painter: TinyBarsPainter(
              values: metric.bars,
              color: metric.color,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          metric.title.replaceFirst('今日', '').replaceFirst('昨晚', ''),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HealthManualRecordSheet extends StatefulWidget {
  const _HealthManualRecordSheet({
    required this.bodyTag,
    required this.energyLevel,
    required this.fatigueLevel,
    required this.stressLevel,
    required this.painNote,
    required this.moodNote,
    required this.onSave,
  });

  final String bodyTag;
  final double energyLevel;
  final double fatigueLevel;
  final double stressLevel;
  final String painNote;
  final String moodNote;
  final ValueChanged<_HealthManualRecord> onSave;

  @override
  State<_HealthManualRecordSheet> createState() =>
      _HealthManualRecordSheetState();
}

class _HealthManualRecordSheetState extends State<_HealthManualRecordSheet> {
  late String _bodyTag;
  late double _energyLevel;
  late double _fatigueLevel;
  late double _stressLevel;
  late final TextEditingController _painController;
  late final TextEditingController _moodController;
  static const _tags = ['很好', '正常', '疲惫', '压力大', '睡眠差'];

  @override
  void initState() {
    super.initState();
    _bodyTag = widget.bodyTag;
    _energyLevel = widget.energyLevel;
    _fatigueLevel = widget.fatigueLevel;
    _stressLevel = widget.stressLevel;
    _painController = TextEditingController(text: widget.painNote);
    _moodController = TextEditingController(text: widget.moodNote);
  }

  @override
  void dispose() {
    _painController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '状态记录',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '身体状态标签',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              final active = _bodyTag == tag;
              return ChoiceChip(
                key: ValueKey('health_body_tag_$tag'),
                selected: active,
                label: Text(tag),
                onSelected: (_) => setState(() => _bodyTag = tag),
                selectedColor: AppColors.primarySoft,
                labelStyle: TextStyle(
                  color: active ? AppColors.primary : AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _HealthSlider(
            label: '精神',
            value: _energyLevel,
            onChanged: (value) => setState(() => _energyLevel = value),
          ),
          _HealthSlider(
            label: '疲劳',
            value: _fatigueLevel,
            onChanged: (value) => setState(() => _fatigueLevel = value),
          ),
          _HealthSlider(
            label: '压力',
            value: _stressLevel,
            onChanged: (value) => setState(() => _stressLevel = value),
          ),
          const SizedBox(height: 12),
          SheetTextField(
            keyName: 'health_pain_note',
            controller: _painController,
            label: '疼痛',
            hint: '例如：肩颈紧、膝盖不适',
          ),
          const SizedBox(height: 10),
          SheetTextField(
            keyName: 'health_mood_note',
            controller: _moodController,
            label: '心情',
            hint: '例如：平稳、焦虑、愉快',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey('save_health_manual_record'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '保存记录',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    widget.onSave(
      _HealthManualRecord(
        bodyTag: _bodyTag,
        energyLevel: _energyLevel,
        fatigueLevel: _fatigueLevel,
        stressLevel: _stressLevel,
        painNote: _painController.text.trim(),
        moodNote: _moodController.text.trim().isEmpty
            ? '平稳'
            : _moodController.text.trim(),
      ),
    );
  }
}

class _HealthSlider extends StatelessWidget {
  const _HealthSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${value.round()}/5',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Slider(
          min: 1,
          max: 5,
          divisions: 4,
          value: value,
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
