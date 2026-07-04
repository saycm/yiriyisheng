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
    await _refreshSystemHealthSnapshot();
  }

  Future<HealthSystemSnapshot> _refreshSystemHealthSnapshot() async {
    final snapshot = await _healthStore.load();
    if (!mounted) {
      return snapshot;
    }
    setState(() {
      _systemHealth = snapshot;
      _loadingHealth = false;
      _selectedIndex = math.max(0, _buildHealthDays(snapshot).length - 1);
    });
    return snapshot;
  }

  Future<HealthSystemSnapshot> _requestSystemHealthAccessSnapshot() async {
    await _healthStore.requestPermissions();
    return _refreshSystemHealthSnapshot();
  }

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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthExternalSourceSheet(
        snapshot: _systemHealth,
        loading: _loadingHealth,
        onRefreshSnapshot: _refreshSystemHealthSnapshot,
        onRequestPermissionAndRefresh: _requestSystemHealthAccessSnapshot,
        onOpenSettings: _openSystemHealthSettings,
      ),
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
        sleep: _sleepFeeling,
        energy: _energyFeeling,
        stress: _stressFeeling,
        body: _bodyFeeling,
        mood: _moodFeeling,
        onSave: (record) {
          Navigator.of(context).pop();
          setState(() {
            _bodyTag = record.bodyTag;
            _energyLevel = record.energyLevel;
            _fatigueLevel = record.fatigueLevel;
            _stressLevel = record.stressLevel;
            _painNote = record.painNote;
            _moodNote = record.moodNote;
            _sleepFeeling = record.sleep;
            _energyFeeling = record.energy;
            _stressFeeling = record.stress;
            _bodyFeeling = record.body;
            _moodFeeling = record.mood;
          });
        },
      ),
    );
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
