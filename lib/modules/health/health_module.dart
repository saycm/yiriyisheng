// 中文注释：健康模块源码，负责健康数据、手动记录和系统健康数据接入。

part of 'health.dart';

class HealthMetric {
  const HealthMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bars,
    required this.hasData,
    required this.source,
    required this.statusText,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final List<double> bars;
  final bool hasData;
  final String source;
  final String statusText;
}

class HealthDay {
  const HealthDay({
    required this.date,
    required this.week,
    required this.day,
    required this.ringProgress,
    required this.ringLabels,
    required this.metrics,
    required this.statusMessage,
  });

  final DateTime date;
  final String week;
  final String day;
  final List<double> ringProgress;
  final List<String> ringLabels;
  final List<HealthMetric> metrics;
  final String statusMessage;

  String get title => '${date.month}月$day日⌄';
}

class HealthModulePage extends StatefulWidget {
  const HealthModulePage({
    super.key,
    required this.moduleNav,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.foodCalories,
    required this.workoutGroups,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final Widget moduleNav;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final int foodCalories;
  final int workoutGroups;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<HealthModulePage> createState() => _HealthModulePageState();
}

class _HealthModulePageState extends State<HealthModulePage> {
  static const _healthStore = SystemHealthStore();

  var _selectedIndex = 0;
  int _handledQuickActionToken = 0;
  var _loadingHealth = true;
  HealthSystemSnapshot _systemHealth = HealthSystemSnapshot.loading();
  String _bodyTag = '正常';
  double _energyLevel = 3;
  double _fatigueLevel = 2;
  double _stressLevel = 3;
  String _painNote = '';
  String _moodNote = '平稳';
  HealthSleepFeeling _sleepFeeling = HealthSleepFeeling.normal;
  HealthEnergyFeeling _energyFeeling = HealthEnergyFeeling.normal;
  HealthStressFeeling _stressFeeling = HealthStressFeeling.medium;
  HealthBodyFeeling _bodyFeeling = HealthBodyFeeling.normal;
  HealthMoodFeeling _moodFeeling = HealthMoodFeeling.calm;

  List<HealthDay> get _days => _buildHealthDays(_systemHealth);

  HealthDay get _selectedDay {
    final days = _days;
    final index = math.min(_selectedIndex, days.length - 1);
    return days[index];
  }

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

  @override
  void initState() {
    super.initState();
    unawaited(_loadSystemHealth());
    _maybeHandleQuickAction();
  }

  @override
  void didUpdateWidget(covariant HealthModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  void _maybeHandleQuickAction() {
    if (widget.quickAction != WidgetQuickAction.openHealth ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 小组件“健康详情”直达健康总览弹层，显示饮食和锻炼联动后的完整数据。
      _openSummarySheet();
      widget.onQuickActionHandled();
    });
  }

  Future<void> _loadSystemHealth() async {
    if (mounted) {
      setState(() => _loadingHealth = true);
    }
    final snapshot = await _healthStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _systemHealth = snapshot;
      _loadingHealth = false;
      _selectedIndex = math.max(0, _buildHealthDays(snapshot).length - 1);
    });
  }

  // ignore: unused_element
  Future<void> _requestSystemHealthAccess() async {
    await _healthStore.requestPermissions();
    await _loadSystemHealth();
  }

  // ignore: unused_element
  Future<void> _openSystemHealthSettings() async {
    await _healthStore.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    final selectedDay = _selectedDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _HealthHeader(
                  onOpenModules: widget.onOpenModules,
                  onOpenSummary: _openSummarySheet,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: widget.moduleNav,
                ),
                Expanded(
                  child: ListView(
                    key: const ValueKey('health_main_list'),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      moduleSwitchBarReservedHeight + 24,
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HealthDateStrip(
                            days: days,
                            selectedDay: selectedDay,
                            onSelect: (day) {
                              setState(
                                  () => _selectedIndex = days.indexOf(day));
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
                            onSleepChanged: _updateSleepFeeling,
                            onEnergyChanged: _updateEnergyFeeling,
                            onStressChanged: _updateStressFeeling,
                            onBodyChanged: _updateBodyFeeling,
                            onMoodChanged: _updateMoodFeeling,
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: moduleSwitchBarBottomGap),
                child: WorkoutBottomNav(
                  selectedIndex: 0,
                  keyPrefix: 'health_bottom_nav',
                  items: const [(Icons.monitor_heart_rounded, '总览')],
                  onChanged: (_) {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSummarySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthSummarySheet(
        day: _selectedDay,
        foodCalories: widget.foodCalories,
        workoutGroups: widget.workoutGroups,
        bodyTag: _bodyTag,
        moodNote: _moodNote,
      ),
    );
  }

  void _openExternalSourceSheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('外部数据源将在这里管理')),
    );
  }

  void _updateSleepFeeling(HealthSleepFeeling value) {
    setState(() {
      _sleepFeeling = value;
      if (value == HealthSleepFeeling.poor) {
        _bodyTag = '睡眠差';
      } else if (_bodyTag == '睡眠差') {
        _bodyTag = '正常';
      }
    });
  }

  void _updateEnergyFeeling(HealthEnergyFeeling value) {
    setState(() {
      _energyFeeling = value;
      _energyLevel = switch (value) {
        HealthEnergyFeeling.strong => 5,
        HealthEnergyFeeling.normal => 3,
        HealthEnergyFeeling.tired => 2,
      };
      _fatigueLevel = switch (value) {
        HealthEnergyFeeling.strong => 1,
        HealthEnergyFeeling.normal => 2,
        HealthEnergyFeeling.tired => 4,
      };
      if (value == HealthEnergyFeeling.tired) {
        _bodyTag = '疲惫';
      } else if (_bodyTag == '疲惫') {
        _bodyTag = '正常';
      }
    });
  }

  void _updateStressFeeling(HealthStressFeeling value) {
    setState(() {
      _stressFeeling = value;
      _stressLevel = switch (value) {
        HealthStressFeeling.low => 1,
        HealthStressFeeling.medium => 3,
        HealthStressFeeling.high => 5,
      };
      if (value == HealthStressFeeling.high) {
        _bodyTag = '压力大';
      } else if (_bodyTag == '压力大') {
        _bodyTag = '正常';
      }
    });
  }

  void _updateBodyFeeling(HealthBodyFeeling value) {
    setState(() {
      _bodyFeeling = value;
      _painNote = _painNoteForBody(value);
    });
  }

  void _updateMoodFeeling(HealthMoodFeeling value) {
    setState(() {
      _moodFeeling = value;
      _moodNote = _moodLabel(value);
    });
  }

  void _openManualRecordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthManualRecordSheet(
        bodyTag: _bodyTag,
        energyLevel: _energyLevel,
        fatigueLevel: _fatigueLevel,
        stressLevel: _stressLevel,
        painNote: _painNote,
        moodNote: _moodNote,
        onSave: (record) {
          Navigator.of(context).pop();
          setState(() {
            _bodyTag = record.bodyTag;
            _energyLevel = record.energyLevel;
            _fatigueLevel = record.fatigueLevel;
            _stressLevel = record.stressLevel;
            _painNote = record.painNote;
            _moodNote = record.moodNote;
            _sleepFeeling = _sleepFeelingFromRecord(record);
            _energyFeeling = _energyFeelingFromRecord(record);
            _stressFeeling = _stressFeelingFromRecord(record);
            _bodyFeeling = _bodyFeelingFromRecord(record);
            _moodFeeling = _moodFeelingFromNote(record.moodNote);
          });
        },
      ),
    );
  }

  HealthSleepFeeling _sleepFeelingFromRecord(_HealthManualRecord record) {
    if (record.bodyTag == '很好') {
      return HealthSleepFeeling.good;
    }
    if (record.bodyTag == '睡眠差') {
      return HealthSleepFeeling.poor;
    }
    return HealthSleepFeeling.normal;
  }

  HealthEnergyFeeling _energyFeelingFromRecord(_HealthManualRecord record) {
    if (record.bodyTag == '很好' || record.energyLevel >= 4) {
      return HealthEnergyFeeling.strong;
    }
    if (record.bodyTag == '疲惫' || record.energyLevel <= 2) {
      return HealthEnergyFeeling.tired;
    }
    return HealthEnergyFeeling.normal;
  }

  HealthStressFeeling _stressFeelingFromRecord(_HealthManualRecord record) {
    if (record.bodyTag == '很好' || record.stressLevel <= 2) {
      return HealthStressFeeling.low;
    }
    if (record.bodyTag == '压力大' || record.stressLevel >= 4) {
      return HealthStressFeeling.high;
    }
    return HealthStressFeeling.medium;
  }

  HealthBodyFeeling _bodyFeelingFromRecord(_HealthManualRecord record) {
    final painNote = record.painNote.trim();
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
    return HealthBodyFeeling.normal;
  }

  HealthMoodFeeling _moodFeelingFromNote(String moodNote) {
    if (moodNote.contains('焦虑')) {
      return HealthMoodFeeling.anxious;
    }
    if (moodNote.contains('低落') || moodNote.contains('难过')) {
      return HealthMoodFeeling.low;
    }
    if (moodNote.contains('开心') || moodNote.contains('愉快')) {
      return HealthMoodFeeling.happy;
    }
    return HealthMoodFeeling.calm;
  }

  String _painNoteForBody(HealthBodyFeeling value) {
    switch (value) {
      case HealthBodyFeeling.normal:
        return '';
      case HealthBodyFeeling.neckPain:
        return '肩颈不适';
      case HealthBodyFeeling.stomach:
        return '胃部不适';
      case HealthBodyFeeling.headache:
        return '头痛';
      case HealthBodyFeeling.other:
        return '身体不适';
    }
  }

  // Keep legacy health cards available for the external data source sheet.
  // ignore: unused_element
  Object? get _legacyHealthCardRefs => (
        _HealthManualStatusCard,
        _HealthReminderCard,
        _HealthTrendDashboardCard,
        _HealthSensorCard,
      );

  // ignore: unused_element
  List<String> _healthReminders(HealthDay day) {
    final steps = _metricNumber(day.metrics, '今日步数');
    final sleep = day.metrics.firstWhere((metric) => metric.title == '昨晚睡眠');
    final reminders = <String>[];
    if (steps != null && steps < 6000) {
      reminders.add('步数偏少，可以安排一次轻量走动');
    }
    if (sleep.hasData && sleep.value.startsWith(RegExp(r'[0-5]h'))) {
      reminders.add('昨晚睡眠偏少，今天训练强度建议降低');
    }
    if (_fatigueLevel >= 4) {
      reminders.add('连续疲劳时优先恢复和拉伸');
    }
    if (widget.workoutGroups == 0 && DateTime.now().hour >= 15) {
      reminders.add('久坐时间较长时，先做 5 分钟活动');
    }
    if (widget.foodCalories > 1800) {
      reminders.add('今日摄入较高，晚间注意清淡');
    }
    if (reminders.isEmpty) {
      reminders.add('状态稳定，继续保持今天的节奏');
    }
    return reminders;
  }

  int? _metricNumber(List<HealthMetric> metrics, String title) {
    final metric = metrics.firstWhere((item) => item.title == title);
    if (!metric.hasData) {
      return null;
    }
    return int.tryParse(metric.value.replaceAll(',', ''));
  }

  List<HealthDay> _buildHealthDays(HealthSystemSnapshot snapshot) {
    // 健康页只接受系统健康/传感器返回值；缺权限时保留真实日期但不填假指标。
    final samples = snapshot.days.isEmpty
        ? [HealthSystemDaySample.empty(DateTime.now())]
        : snapshot.days;
    return samples
        .map((sample) => _buildHealthDay(sample, samples, snapshot))
        .toList();
  }

  HealthDay _buildHealthDay(
    HealthSystemDaySample sample,
    List<HealthSystemDaySample> samples,
    HealthSystemSnapshot snapshot,
  ) {
    final stepsTrend = _trendValues(samples, (day) => day.steps);
    final activeTrend = _trendValues(samples, (day) => day.activeCaloriesKcal);
    final basalTrend = _trendValues(samples, (day) => day.basalCaloriesKcal);
    final sleepTrend = _trendValues(samples, (day) => day.sleepMinutes);
    final heartTrend = _trendValues(samples, (day) => day.heartRateBpm);
    final respiratoryTrend =
        _trendValues(samples, (day) => day.respiratoryRate);
    final sensorHeartRate = snapshot.sensors.heartRateBpm?.round();
    final heartRate = sample.heartRateBpm ?? sensorHeartRate;
    final heartSource = sample.heartRateBpm == null && sensorHeartRate != null
        ? '传感器实时'
        : 'Health Connect';

    return HealthDay(
      date: sample.date,
      week: _weekdayLabel(sample.date),
      day: sample.date.day.toString(),
      statusMessage: snapshot.message,
      ringProgress: [
        _progress(sample.steps, 10000),
        _progress(sample.activeCaloriesKcal, 500),
        snapshot.sensors.accelerometerAvailable ? 1.0 : 0.0,
      ],
      ringLabels: [
        _percentLabel(sample.steps, 10000),
        _percentLabel(sample.activeCaloriesKcal, 500),
        snapshot.sensors.accelerometerAvailable ? '已连接' : '无传感器',
      ],
      metrics: [
        _metric(
          title: '今日基础代谢',
          value: sample.basalCaloriesKcal?.round().toString(),
          unit: 'kcal',
          icon: Icons.bolt_rounded,
          color: const Color(0xFFFFD749),
          bars: basalTrend,
          source: 'Health Connect',
        ),
        _metric(
          title: '今日能量',
          value: sample.activeCaloriesKcal?.round().toString(),
          unit: 'kcal',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFFA14A),
          bars: activeTrend,
          source: 'Health Connect',
        ),
        _metric(
          title: '今日步数',
          value: _formatOptionalWhole(sample.steps),
          unit: '步',
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFF61CE86),
          bars: stepsTrend,
          source: 'Health Connect',
        ),
        _metric(
          title: '昨晚睡眠',
          value: _formatOptionalSleep(sample.sleepMinutes),
          unit: '小时',
          icon: Icons.dark_mode_rounded,
          color: const Color(0xFF8D7CF6),
          bars: sleepTrend,
          source: 'Health Connect',
        ),
        _metric(
          title: heartSource == '传感器实时' ? '实时心率' : '今日心率',
          value: heartRate?.toString(),
          unit: 'bpm',
          icon: Icons.favorite_rounded,
          color: const Color(0xFFFF7A83),
          bars: heartTrend,
          source: heartSource,
        ),
        _metric(
          title: '今日呼吸',
          value: sample.respiratoryRate?.toStringAsFixed(1),
          unit: '次/分',
          icon: Icons.air_rounded,
          color: const Color(0xFFB58CFF),
          bars: respiratoryTrend,
          source: 'Health Connect',
        ),
      ],
    );
  }

  HealthMetric _metric({
    required String title,
    required String? value,
    required String unit,
    required IconData icon,
    required Color color,
    required List<double> bars,
    required String source,
  }) {
    final hasData = value != null;
    return HealthMetric(
      title: title,
      value: value ?? '--',
      unit: hasData ? unit : '无系统记录',
      icon: icon,
      color: color,
      bars: hasData ? bars : const [],
      hasData: hasData,
      source: source,
      statusText: hasData ? source : _systemHealth.message,
    );
  }

  List<double> _trendValues(
    List<HealthSystemDaySample> samples,
    num? Function(HealthSystemDaySample sample) selector,
  ) {
    final values = <double>[];
    for (final sample in samples) {
      final value = selector(sample);
      if (value != null) {
        values.add(math.max(0, value.toDouble()));
      }
    }
    return values;
  }

  double _progress(num? value, num goal) {
    if (value == null || goal <= 0) {
      return 0;
    }
    return (value / goal).clamp(0.0, 1.0).toDouble();
  }

  String _percentLabel(num? value, num goal) {
    if (value == null || goal <= 0) {
      return '无数据';
    }
    return '${((value / goal) * 100).round()}%';
  }

  String _weekdayLabel(DateTime date) {
    final today = DateTime.now();
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return '今天';
    }
    return const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
  }

  String _formatWhole(num value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String? _formatOptionalWhole(int? value) {
    if (value == null) {
      return null;
    }
    return _formatWhole(value);
  }

  String? _formatOptionalSleep(int? minutes) {
    if (minutes == null) {
      return null;
    }
    return _formatSleep(minutes);
  }

  String _formatSleep(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return '${hours}h ${rest}m';
  }
}

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({
    required this.onOpenModules,
    required this.onOpenSummary,
  });

  final VoidCallback onOpenModules;
  final VoidCallback onOpenSummary;

  @override
  Widget build(BuildContext context) {
    return ModuleGlassHeader(
      module: LifeModule.health,
      title: '健康',
      onOpenModules: onOpenModules,
      onOpenMore: onOpenSummary,
    );
  }
}

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日状态',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '状态中心',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onRecord,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('记录状态'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result.score.toString(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.level,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.primaryReason,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(10),
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
              Icon(Icons.fact_check_rounded,
                  color: AppColors.primary, size: 21),
              SizedBox(width: 8),
              Text(
                '快速记录',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HealthChoiceRow<HealthSleepFeeling>(
            label: '睡眠',
            selected: sleep,
            values: HealthSleepFeeling.values,
            keyPrefix: 'health_quick_sleep',
            labelFor: _sleepLabel,
            onChanged: onSleepChanged,
          ),
          const SizedBox(height: 4),
          _HealthChoiceRow<HealthEnergyFeeling>(
            label: '精力',
            selected: energy,
            values: HealthEnergyFeeling.values,
            keyPrefix: 'health_quick_energy',
            labelFor: _energyLabel,
            onChanged: onEnergyChanged,
          ),
          const SizedBox(height: 4),
          _HealthChoiceRow<HealthStressFeeling>(
            label: '压力',
            selected: stress,
            values: HealthStressFeeling.values,
            keyPrefix: 'health_quick_stress',
            labelFor: _stressLabel,
            onChanged: onStressChanged,
          ),
          const SizedBox(height: 4),
          _HealthChoiceRow<HealthBodyFeeling>(
            label: '身体',
            selected: body,
            values: HealthBodyFeeling.values,
            keyPrefix: 'health_quick_body',
            labelFor: _quickBodyLabel,
            onChanged: onBodyChanged,
          ),
          const SizedBox(height: 4),
          _HealthChoiceRow<HealthMoodFeeling>(
            label: '心情',
            selected: mood,
            values: HealthMoodFeeling.values,
            keyPrefix: 'health_quick_mood',
            labelFor: _moodLabel,
            onChanged: onMoodChanged,
          ),
        ],
      ),
    );
  }
}

class _HealthChoiceRow<T extends Enum> extends StatelessWidget {
  const _HealthChoiceRow({
    required this.label,
    required this.selected,
    required this.values,
    required this.keyPrefix,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T selected;
  final List<T> values;
  final String keyPrefix;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .map(
                  (value) => _HealthChoiceChip<T>(
                    keyPrefix: keyPrefix,
                    value: value,
                    label: labelFor(value),
                    selected: value == selected,
                    onChanged: onChanged,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _HealthChoiceChip<T extends Enum> extends StatelessWidget {
  const _HealthChoiceChip({
    required this.keyPrefix,
    required this.value,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String keyPrefix;
  final T value;
  final String label;
  final bool selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: selected ? AppColors.primary : AppColors.ink,
      fontSize: 11,
      fontWeight: FontWeight.w900,
    );

    return InkWell(
      key: ValueKey('${keyPrefix}_${value.name}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: selected
            ? Text(label, style: labelStyle)
            : RichText(text: TextSpan(text: label, style: labelStyle)),
      ),
    );
  }
}

String _quickBodyLabel(HealthBodyFeeling value) {
  if (value == HealthBodyFeeling.neckPain) {
    return '肩颈不适';
  }
  return _bodyLabel(value);
}

class _HealthImpactCard extends StatelessWidget {
  const _HealthImpactCard({required this.impacts});

  final List<HealthStatusImpact> impacts;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('health_impact_card'),
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
            '影响因素',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...impacts.map(
            (impact) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HealthImpactRow(impact: impact),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthImpactRow extends StatelessWidget {
  const _HealthImpactRow({required this.impact});

  final HealthStatusImpact impact;

  @override
  Widget build(BuildContext context) {
    final hasScore = impact.maxScore > 0;
    final progress = hasScore
        ? (impact.score / impact.maxScore).clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: impact.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                impact.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (hasScore)
              Text(
                '${impact.score}/${impact.maxScore}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          impact.label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hasScore) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: impact.color,
              backgroundColor: AppColors.background,
            ),
          ),
        ],
      ],
    );
  }
}

class _HealthStatusSuggestionCard extends StatelessWidget {
  const _HealthStatusSuggestionCard({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('health_status_suggestion_card'),
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
            '状态建议',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
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

class _HealthStatusTrendCard extends StatelessWidget {
  const _HealthStatusTrendCard({required this.result});

  final HealthStatusResult result;

  @override
  Widget build(BuildContext context) {
    final scoredImpacts =
        result.impacts.where((impact) => impact.maxScore > 0).toList();
    final frequentTags = result.impacts
        .where((impact) => impact.label.trim().isNotEmpty)
        .take(4)
        .map((impact) => impact.label)
        .join(' · ');

    return Container(
      key: const ValueKey('health_status_trend_card'),
      height: 168,
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
            '状态趋势',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: TinyBarsPainter(
                values: scoredImpacts
                    .map((impact) => impact.score.toDouble())
                    .toList(),
                color: AppColors.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            frequentTags,
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
    );
  }
}

class _HealthExternalSourceEntry extends StatelessWidget {
  const _HealthExternalSourceEntry({
    required this.snapshot,
    required this.loading,
    required this.onTap,
  });

  final HealthSystemSnapshot snapshot;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = _HealthConnectionState.fromSnapshot(snapshot, loading);

    return InkWell(
      key: const ValueKey('health_external_source_entry'),
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: state.color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.sync_alt_rounded, color: state.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '外部数据源',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Health Connect 是可选数据源，不影响状态中心。',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _HealthDateStrip extends StatelessWidget {
  const _HealthDateStrip({
    required this.days,
    required this.selectedDay,
    required this.onSelect,
  });

  final List<HealthDay> days;
  final HealthDay selectedDay;
  final ValueChanged<HealthDay> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: days.map((day) {
            final selected = day.day == selectedDay.day;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelect(day),
                child: SizedBox(
                  width: 38,
                  child: Column(
                    children: [
                      Text(
                        day.week,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: CustomPaint(
                          painter: _MiniRingsPainter(
                            selected: selected,
                            progress: day.ringProgress,
                          ),
                          child: Center(
                            child: Text(
                              day.day,
                              style: TextStyle(
                                color:
                                    selected ? AppColors.ink : AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _HealthSystemStatusCard extends StatelessWidget {
  const _HealthSystemStatusCard({
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
    final state = _HealthConnectionState.fromSnapshot(snapshot, loading);

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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: state.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  state.icon,
                  color: state.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HealthStatusPill(
                label: 'Health Connect',
                value: state.badge,
              ),
              _HealthStatusPill(
                label: '传感器',
                value: snapshot.sensors.summary,
              ),
              _HealthStatusPill(
                label: '刷新',
                value: snapshot.lastUpdated == null
                    ? '未完成'
                    : _formatUpdated(snapshot.lastUpdated!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('刷新'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.opensSettings
                      ? onOpenSettings
                      : onRequestPermission,
                  icon: Icon(state.actionIcon, size: 18),
                  label: Text(state.actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatUpdated(DateTime value) {
    final local = value.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.hour}:$minute';
  }
}

class _HealthConnectionState {
  const _HealthConnectionState({
    required this.title,
    required this.badge,
    required this.actionLabel,
    required this.icon,
    required this.actionIcon,
    required this.color,
    required this.opensSettings,
  });

  final String title;
  final String badge;
  final String actionLabel;
  final IconData icon;
  final IconData actionIcon;
  final Color color;
  final bool opensSettings;

  factory _HealthConnectionState.fromSnapshot(
    HealthSystemSnapshot snapshot,
    bool loading,
  ) {
    if (loading || snapshot.status == SystemHealthStatus.loading) {
      return const _HealthConnectionState(
        title: '正在读取系统健康数据',
        badge: '读取中',
        actionLabel: '刷新',
        icon: Icons.sync_rounded,
        actionIcon: Icons.refresh_rounded,
        color: AppColors.primary,
        opensSettings: false,
      );
    }
    if (snapshot.status == SystemHealthStatus.ok) {
      if (!snapshot.hasAnyData) {
        return const _HealthConnectionState(
          title: 'Health Connect 已连接，暂无数据',
          badge: '数据为空',
          actionLabel: '打开设置',
          icon: Icons.dataset_outlined,
          actionIcon: Icons.settings_rounded,
          color: AppColors.primary,
          opensSettings: true,
        );
      }
      return const _HealthConnectionState(
        title: '系统健康数据已连接',
        badge: '已连接',
        actionLabel: '打开设置',
        icon: Icons.verified_rounded,
        actionIcon: Icons.settings_rounded,
        color: AppColors.success,
        opensSettings: true,
      );
    }
    if (snapshot.status == SystemHealthStatus.permissionRequired) {
      return const _HealthConnectionState(
        title: 'Health Connect 未授权',
        badge: '未授权',
        actionLabel: '去授权',
        icon: Icons.lock_outline_rounded,
        actionIcon: Icons.lock_open_rounded,
        color: AppColors.primary,
        opensSettings: false,
      );
    }
    if (snapshot.status == SystemHealthStatus.updateRequired) {
      return const _HealthConnectionState(
        title: '需要更新 Health Connect',
        badge: '需更新',
        actionLabel: '去更新',
        icon: Icons.system_update_alt_rounded,
        actionIcon: Icons.open_in_new_rounded,
        color: AppColors.primary,
        opensSettings: true,
      );
    }
    if (snapshot.status == SystemHealthStatus.error) {
      return const _HealthConnectionState(
        title: '系统健康读取失败',
        badge: '读取失败',
        actionLabel: '重试',
        icon: Icons.error_outline_rounded,
        actionIcon: Icons.refresh_rounded,
        color: AppColors.financeRed,
        opensSettings: false,
      );
    }
    return const _HealthConnectionState(
      title: '需要安装 Health Connect',
      badge: '未安装',
      actionLabel: '去安装',
      icon: Icons.download_rounded,
      actionIcon: Icons.open_in_new_rounded,
      color: AppColors.primary,
      opensSettings: true,
    );
  }
}

class _HealthStatusPill extends StatelessWidget {
  const _HealthStatusPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _HealthRingsCard extends StatelessWidget {
  const _HealthRingsCard({required this.day});

  final HealthDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 136,
            height: 136,
            child: CustomPaint(
              painter: _ActivityRingsPainter(progress: day.ringProgress),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RingLegend(
                  color: const Color(0xFF48CE81),
                  title: '步数',
                  value: day.ringLabels[0],
                ),
                const SizedBox(height: 12),
                _RingLegend(
                  color: const Color(0xFFFF9559),
                  title: '能量',
                  value: day.ringLabels[1],
                ),
                const SizedBox(height: 12),
                _RingLegend(
                  color: const Color(0xFF7D9CFF),
                  title: '传感',
                  value: day.ringLabels[2],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingLegend extends StatelessWidget {
  const _RingLegend({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
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
      ],
    );
  }
}

// ignore: unused_element
class _HealthLinkedSummaryCard extends StatelessWidget {
  const _HealthLinkedSummaryCard({
    required this.foodCalories,
    required this.workoutGroups,
  });

  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    return ModuleLinkedSummaryCard(
      title: '模块联动',
      subtitle: '饮食和锻炼记录会同步影响健康总览。',
      icon: Icons.monitor_heart_rounded,
      values: [
        ('饮食', '$foodCalories kcal'),
        ('锻炼', '$workoutGroups 组'),
      ],
    );
  }
}
