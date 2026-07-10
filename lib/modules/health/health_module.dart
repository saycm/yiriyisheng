// 中文注释：健康模块源码，负责健康数据、手动记录和系统健康数据接入。

part of 'health.dart';

class HealthMetric {
  const HealthMetric({
    required this.title,
    required this.value,
    required this.unit,
  });

  final String title;
  final String value;
  final String unit;
}

class HealthDay {
  const HealthDay({
    required this.date,
    required this.week,
    required this.day,
    required this.ringLabels,
    required this.metrics,
    required this.statusMessage,
  });

  final DateTime date;
  final String week;
  final String day;
  final List<String> ringLabels;
  final List<HealthMetric> metrics;
  final String statusMessage;

  String get title => '${date.month}月$day日⌄';
  String get monthDayLabel => '${date.month}月$day日';
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
      // 小组件“状态详情”直达状态总览弹层，显示饮食和锻炼联动后的完整数据。
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
      body: LiquidModuleBackground(
        child: SafeArea(
          child: Column(
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
                          statusResult: _statusResult,
                          onSelect: _openDaySummarySheet,
                        ),
                        const SizedBox(height: 10),
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
        ),
      ),
    );
  }

  void _openSummarySheet() {
    _openDaySummarySheet(
      _selectedDay,
      title: '状态总览',
      helperText: null,
    );
  }

  void _openDaySummarySheet(
    HealthDay day, {
    String? title,
    String? helperText = '查看当天摘要，不会修改今日状态记录。',
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthSummarySheet(
        day: day,
        title: title,
        helperText: helperText,
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
    final samples =
        snapshot.hasAnyData ? snapshot.days : _recentEmptyHealthSamples();
    return samples.map((sample) => _buildHealthDay(sample, snapshot)).toList();
  }

  List<HealthSystemDaySample> _recentEmptyHealthSamples() {
    final today = DateTime.now();
    return List.generate(
      7,
      (index) => HealthSystemDaySample.empty(
        today.subtract(Duration(days: 6 - index)),
      ),
    );
  }

  HealthDay _buildHealthDay(
    HealthSystemDaySample sample,
    HealthSystemSnapshot snapshot,
  ) {
    final sensorHeartRate = snapshot.sensors.heartRateBpm?.round();
    final heartRate = sample.heartRateBpm ?? sensorHeartRate;
    final usesSensorHeartRate =
        sample.heartRateBpm == null && sensorHeartRate != null;

    return HealthDay(
      date: sample.date,
      week: _weekdayLabel(sample.date),
      day: sample.date.day.toString(),
      statusMessage: snapshot.message,
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
        ),
        _metric(
          title: '今日能量',
          value: sample.activeCaloriesKcal?.round().toString(),
          unit: 'kcal',
        ),
        _metric(
          title: '今日步数',
          value: _formatOptionalWhole(sample.steps),
          unit: '步',
        ),
        _metric(
          title: '昨晚睡眠',
          value: _formatOptionalSleep(sample.sleepMinutes),
          unit: '小时',
        ),
        _metric(
          title: usesSensorHeartRate ? '实时心率' : '今日心率',
          value: heartRate?.toString(),
          unit: 'bpm',
        ),
        _metric(
          title: '今日呼吸',
          value: sample.respiratoryRate?.toStringAsFixed(1),
          unit: '次/分',
        ),
      ],
    );
  }

  HealthMetric _metric({
    required String title,
    required String? value,
    required String unit,
  }) {
    return HealthMetric(
      title: title,
      value: value ?? '--',
      unit: value == null ? '无系统记录' : unit,
    );
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
    required this.statusResult,
    required this.onSelect,
  });

  final List<HealthDay> days;
  final HealthDay selectedDay;
  final HealthStatusResult statusResult;
  final ValueChanged<HealthDay> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return KeyedSubtree(
      key: const ValueKey('health_date_strip'),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.82),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '近 7 天状态',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '今天 ${today.month}月${today.day}日',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            LayoutBuilder(
              builder: (context, constraints) {
                if (days.isEmpty) {
                  return const SizedBox.shrink();
                }

                const gap = 4.0;
                final itemWidth =
                    ((constraints.maxWidth - gap * (days.length - 1)) /
                            days.length)
                        .clamp(40.0, 54.0)
                        .toDouble();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < days.length; index++)
                        Padding(
                          padding: EdgeInsets.only(
                            right: index == days.length - 1 ? 0 : gap,
                          ),
                          child: _HealthDayPill(
                            day: days[index],
                            width: itemWidth,
                            selected: DateUtils.isSameDay(
                              days[index].date,
                              selectedDay.date,
                            ),
                            isToday:
                                DateUtils.isSameDay(days[index].date, today),
                            score: DateUtils.isSameDay(days[index].date, today)
                                ? statusResult.score
                                : null,
                            onTap: () => onSelect(days[index]),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthDayPill extends StatelessWidget {
  const _HealthDayPill({
    required this.day,
    required this.width,
    required this.selected,
    required this.isToday,
    required this.score,
    required this.onTap,
  });

  final HealthDay day;
  final double width;
  final bool selected;
  final bool isToday;
  final int? score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(score);
    final dateKey = _dateKey(day.date);
    final statusLabel = score == null ? '未记录' : '$score分';
    final foreground = selected || score != null ? accent : AppColors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: '查看${day.monthDayLabel}状态摘要，$statusLabel',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            key: ValueKey(
                isToday ? 'health_day_pill_today' : 'health_day_pill_$dateKey'),
            duration: const Duration(milliseconds: 160),
            width: width,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: BoxDecoration(
              color: _backgroundColor(score),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? accent : AppColors.line,
                width: selected ? 1.4 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isToday ? '今天' : day.week,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  day.day,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusLabel,
                  key: ValueKey(
                    isToday
                        ? 'health_day_status_today'
                        : 'health_day_status_$dateKey',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}_${date.month}_${date.day}';
  }

  Color _accentColor(int? score) {
    if (score == null) {
      return AppColors.muted;
    }
    if (score >= 85) {
      return AppColors.success;
    }
    if (score >= 70) {
      return AppColors.primary;
    }
    if (score >= 55) {
      return AppColors.sun;
    }
    return AppColors.financeRed;
  }

  Color _backgroundColor(int? score) {
    if (score == null) {
      return AppColors.surface.withValues(alpha: 0.74);
    }
    if (score >= 85) {
      return AppColors.mintSoft.withValues(alpha: 0.92);
    }
    if (score >= 70) {
      return AppColors.primarySoft.withValues(alpha: 0.92);
    }
    if (score >= 55) {
      return AppColors.sun.withValues(alpha: 0.14);
    }
    return AppColors.roseSoft.withValues(alpha: 0.94);
  }
}
