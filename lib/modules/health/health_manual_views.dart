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
    required this.sleep,
    required this.energy,
    required this.stress,
    required this.body,
    required this.mood,
  });

  final String bodyTag;
  final double energyLevel;
  final double fatigueLevel;
  final double stressLevel;
  final String painNote;
  final String moodNote;
  final HealthSleepFeeling sleep;
  final HealthEnergyFeeling energy;
  final HealthStressFeeling stress;
  final HealthBodyFeeling body;
  final HealthMoodFeeling mood;
}

class _HealthManualRecordSheet extends StatefulWidget {
  const _HealthManualRecordSheet({
    required this.bodyTag,
    required this.energyLevel,
    required this.fatigueLevel,
    required this.stressLevel,
    required this.painNote,
    required this.moodNote,
    required this.sleep,
    required this.energy,
    required this.stress,
    required this.body,
    required this.mood,
    required this.onSave,
  });

  final String bodyTag;
  final double energyLevel;
  final double fatigueLevel;
  final double stressLevel;
  final String painNote;
  final String moodNote;
  final HealthSleepFeeling sleep;
  final HealthEnergyFeeling energy;
  final HealthStressFeeling stress;
  final HealthBodyFeeling body;
  final HealthMoodFeeling mood;
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
  late HealthSleepFeeling _sleep;
  late HealthEnergyFeeling _energy;
  late HealthStressFeeling _stress;
  late HealthBodyFeeling _body;
  late HealthMoodFeeling _mood;
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
    _sleep = widget.sleep;
    _energy = widget.energy;
    _stress = widget.stress;
    _body = widget.body;
    _mood = widget.mood;
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
                onSelected: (_) => setState(() => _selectBodyTag(tag)),
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
            onChanged: (value) => setState(() {
              _energyLevel = value;
              _energy = _energyFeelingFromLevel(value);
            }),
          ),
          _HealthSlider(
            label: '疲劳',
            value: _fatigueLevel,
            onChanged: (value) => setState(() => _fatigueLevel = value),
          ),
          _HealthSlider(
            label: '压力',
            value: _stressLevel,
            onChanged: (value) => setState(() {
              _stressLevel = value;
              _stress = _stressFeelingFromLevel(value);
            }),
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
    final painNote = _painController.text.trim();
    final moodNote = _moodController.text.trim().isEmpty
        ? _moodLabel(_mood)
        : _moodController.text.trim();
    widget.onSave(
      _HealthManualRecord(
        bodyTag: _bodyTag,
        energyLevel: _energyLevel,
        fatigueLevel: _fatigueLevel,
        stressLevel: _stressLevel,
        painNote: painNote,
        moodNote: moodNote,
        sleep: _sleep,
        energy: _energy,
        stress: _stress,
        body: _bodyFeelingFromPainNote(painNote),
        mood: _moodFeelingFromNote(moodNote),
      ),
    );
  }

  void _selectBodyTag(String tag) {
    _bodyTag = tag;
    switch (tag) {
      case '很好':
        _sleep = HealthSleepFeeling.good;
        _energy = HealthEnergyFeeling.strong;
        _stress = HealthStressFeeling.low;
        _body = HealthBodyFeeling.normal;
      case '正常':
        _sleep = HealthSleepFeeling.normal;
        _energy = HealthEnergyFeeling.normal;
        _stress = HealthStressFeeling.medium;
        _body = HealthBodyFeeling.normal;
      case '疲惫':
        _energy = HealthEnergyFeeling.tired;
      case '压力大':
        _stress = HealthStressFeeling.high;
      case '睡眠差':
        _sleep = HealthSleepFeeling.poor;
    }
  }

  HealthEnergyFeeling _energyFeelingFromLevel(double value) {
    if (value >= 4) {
      return HealthEnergyFeeling.strong;
    }
    if (value <= 2) {
      return HealthEnergyFeeling.tired;
    }
    return HealthEnergyFeeling.normal;
  }

  HealthStressFeeling _stressFeelingFromLevel(double value) {
    if (value <= 2) {
      return HealthStressFeeling.low;
    }
    if (value >= 4) {
      return HealthStressFeeling.high;
    }
    return HealthStressFeeling.medium;
  }

  HealthBodyFeeling _bodyFeelingFromPainNote(String painNote) {
    if (painNote.contains('肩') || painNote.contains('颈')) {
      return HealthBodyFeeling.neckPain;
    }
    if (painNote.contains('胃')) {
      return HealthBodyFeeling.stomach;
    }
    if (painNote.contains('头')) {
      return HealthBodyFeeling.headache;
    }
    if (painNote.isNotEmpty) {
      return HealthBodyFeeling.other;
    }
    return _body;
  }

  HealthMoodFeeling _moodFeelingFromNote(String moodNote) {
    if (moodNote.contains('焦虑')) {
      return HealthMoodFeeling.anxious;
    }
    if (moodNote.contains('低落') ||
        moodNote.contains('难过') ||
        moodNote.contains('偏低')) {
      return HealthMoodFeeling.low;
    }
    if (moodNote.contains('开心') ||
        moodNote.contains('愉快') ||
        moodNote.contains('不错')) {
      return HealthMoodFeeling.happy;
    }
    return HealthMoodFeeling.calm;
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
