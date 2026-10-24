// 中文注释：健康模块源码，负责健康数据、手动记录和系统健康数据接入。

part of 'health.dart';

/// 健康指标：名称、数值、单位和趋势数据。
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

/// 健康数据中的一天：日期和各项指标。
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

/// 健康模块页面：展示状态评分、手动记录、Health Connect 数据和趋势。
class HealthModulePage extends StatefulWidget {
  const HealthModulePage({
    super.key,
    required this.moduleNav,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.foodCalories,
    required this.workoutGroups,
    this.foodLogs = const [],
    this.workoutHistory = const [],
    this.currentDate,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final Widget moduleNav;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final int foodCalories;
  final int workoutGroups;
  final List<FoodLogEntry> foodLogs;
  final List<WorkoutHistoryEntry> workoutHistory;
  final DateTime? currentDate;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<HealthModulePage> createState() => _HealthModulePageState();
}

/// 健康页状态：日期选择、系统健康快照和手动记录。
class _HealthModulePageState extends State<HealthModulePage> {
  static const _healthStore = SystemHealthStore();
  static const _manualStore = HealthManualStore();

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
  Map<String, HealthManualRecordData> _manualRecords = const {};
  var _manualRecordChangedWhileLoading = false;
  late String _manualRecordDateKey;

  DateTime get _today => DateUtils.dateOnly(
        widget.currentDate ?? DateTime.now(),
      );

  List<HealthDay> get _days => _buildHealthDays(_systemHealth);

  /// 取当前选中的日期；索引越界时自动回退到最新一天。
  HealthDay get _selectedDay {
    final days = _days;
    final index = math.min(_selectedIndex, days.length - 1);
    return days[index];
  }

  /// 用今天的手动感受、饮食热量和训练组数实时计算状态评分。
  HealthStatusResult get _statusResult {
    return _calculateStatus(
      sleep: _sleepFeeling,
      energy: _energyFeeling,
      stress: _stressFeeling,
      body: _bodyFeeling,
      mood: _moodFeeling,
      foodCalories: widget.foodCalories,
      workoutGroups: widget.workoutGroups,
    );
  }

  @override
  void initState() {
    super.initState();
    _manualRecordDateKey = healthManualDateKey(_today);
    unawaited(_loadSystemHealth());
    unawaited(_loadManualRecords());
    _maybeHandleQuickAction();
  }

  @override
  void didUpdateWidget(covariant HealthModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentDateKey = healthManualDateKey(_today);
    if (currentDateKey != _manualRecordDateKey) {
      _manualRecordDateKey = currentDateKey;
      final record = _manualRecords[currentDateKey];
      if (record == null) {
        _resetManualRecord();
      } else {
        _applyManualRecord(record);
      }
      unawaited(_loadSystemHealth());
    }
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

  /// 从 Health Connect/传感器读取快照并刷新页面，默认选中最新日期。
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

  /// 请求系统健康权限，然后重新读取授权后的数据。
  Future<HealthSystemSnapshot> _requestSystemHealthAccessSnapshot() async {
    await _healthStore.requestPermissions();
    return _refreshSystemHealthSnapshot();
  }

  /// 跳转到系统健康设置，供用户手动补授权。
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
                          today: _today,
                          statusScores: {
                            for (final day in days)
                              if (_statusScoreForDay(day.date)
                                  case final score?)
                                healthManualDateKey(day.date): score,
                          },
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
    final days = _days;
    final today = days.firstWhere(
      (day) => DateUtils.isSameDay(day.date, _today),
      orElse: () => _buildHealthDay(
        HealthSystemDaySample.empty(_today),
        _systemHealth,
      ),
    );
    _openDaySummarySheet(
      today,
      title: '状态总览',
      helperText: null,
    );
  }

  /// 打开指定日期的健康摘要；今天优先使用当前编辑态，历史日期读取已保存记录。
  void _openDaySummarySheet(
    HealthDay day, {
    String? title,
    String? helperText = '查看当天摘要，不会修改今日状态记录。',
  }) {
    final isToday = DateUtils.isSameDay(day.date, _today);
    final manualRecord = _manualRecords[healthManualDateKey(day.date)];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthSummarySheet(
        day: day,
        title: title,
        helperText: helperText,
        foodCalories: _foodCaloriesForDay(day.date),
        workoutGroups: _workoutGroupsForDay(day.date),
        bodyTag: isToday ? _bodyTag : manualRecord?.bodyTag,
        moodNote: isToday ? _moodNote : manualRecord?.moodNote,
      ),
    );
  }

  /// 打开外部健康数据源面板，展示权限、刷新和设置入口。
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

  /// 更新睡眠感受；睡眠差时同步身体标签，并立即持久化。
  void _updateSleepFeeling(HealthSleepFeeling value) {
    setState(() {
      _sleepFeeling = value;
      if (value == HealthSleepFeeling.poor) {
        _bodyTag = '睡眠差';
      } else if (_bodyTag == '睡眠差') {
        _bodyTag = '正常';
      }
    });
    _persistCurrentManualRecord();
  }

  /// 更新精力感受，并同步精力/疲劳等级和身体标签。
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
    _persistCurrentManualRecord();
  }

  /// 更新压力感受，并同步压力等级和身体标签。
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
    _persistCurrentManualRecord();
  }

  /// 更新身体不适类型，同时生成摘要里的疼痛说明。
  void _updateBodyFeeling(HealthBodyFeeling value) {
    setState(() {
      _bodyFeeling = value;
      _painNote = _painNoteForBody(value);
    });
    _persistCurrentManualRecord();
  }

  /// 更新心情，并同步摘要里的情绪文案。
  void _updateMoodFeeling(HealthMoodFeeling value) {
    setState(() {
      _moodFeeling = value;
      _moodNote = _moodLabel(value);
    });
    _persistCurrentManualRecord();
  }

  /// 打开手动状态记录表单，保存后覆盖今天的内存数据和持久化记录。
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
          _persistCurrentManualRecord();
        },
      ),
    );
  }

  /// 读取历史手动记录；若加载期间用户已编辑，则保留新值并写回存储。
  Future<void> _loadManualRecords() async {
    final records = await _manualStore.load();
    if (!mounted) {
      return;
    }
    final loaded = {
      for (final record in records) record.dateKey: record,
    };
    final todayKey = _manualRecordDateKey;
    if (_manualRecordChangedWhileLoading) {
      loaded.addAll(_manualRecords);
    }
    setState(() {
      _manualRecords = loaded;
      final todayRecord = loaded[todayKey];
      if (todayRecord != null) {
        _applyManualRecord(todayRecord);
      }
    });
    if (_manualRecordChangedWhileLoading) {
      _manualRecordChangedWhileLoading = false;
      unawaited(_manualStore.save(loaded.values));
    }
  }

  /// 把当前编辑态组装成当天记录，并异步保存到本地存储。
  void _persistCurrentManualRecord() {
    _manualRecordChangedWhileLoading = true;
    final record = _currentManualRecord();
    final updated = Map<String, HealthManualRecordData>.of(_manualRecords)
      ..[record.dateKey] = record;
    _manualRecords = updated;
    unawaited(_manualStore.save(updated.values));
  }

  /// 把分散在多个评分字段中的状态组装为可序列化的日记录。
  HealthManualRecordData _currentManualRecord() {
    return HealthManualRecordData(
      date: _today,
      bodyTag: _bodyTag,
      energyLevel: _energyLevel,
      fatigueLevel: _fatigueLevel,
      stressLevel: _stressLevel,
      painNote: _painNote,
      moodNote: _moodNote,
      sleep: _sleepFeeling.name,
      energy: _energyFeeling.name,
      stress: _stressFeeling.name,
      body: _bodyFeeling.name,
      mood: _moodFeeling.name,
    );
  }

  /// 用已保存记录覆盖当前编辑态，枚举字符串无法识别时回退到默认值。
  void _applyManualRecord(HealthManualRecordData record) {
    _bodyTag = record.bodyTag;
    _energyLevel = record.energyLevel;
    _fatigueLevel = record.fatigueLevel;
    _stressLevel = record.stressLevel;
    _painNote = record.painNote;
    _moodNote = record.moodNote;
    _sleepFeeling = _enumValue(
      HealthSleepFeeling.values,
      record.sleep,
      HealthSleepFeeling.normal,
    );
    _energyFeeling = _enumValue(
      HealthEnergyFeeling.values,
      record.energy,
      HealthEnergyFeeling.normal,
    );
    _stressFeeling = _enumValue(
      HealthStressFeeling.values,
      record.stress,
      HealthStressFeeling.medium,
    );
    _bodyFeeling = _enumValue(
      HealthBodyFeeling.values,
      record.body,
      HealthBodyFeeling.normal,
    );
    _moodFeeling = _enumValue(
      HealthMoodFeeling.values,
      record.mood,
      HealthMoodFeeling.calm,
    );
  }

  /// 把手动记录恢复为中性默认值，用于今天还没有记录的情况。
  void _resetManualRecord() {
    _bodyTag = '正常';
    _energyLevel = 3;
    _fatigueLevel = 2;
    _stressLevel = 3;
    _painNote = '';
    _moodNote = '平稳';
    _sleepFeeling = HealthSleepFeeling.normal;
    _energyFeeling = HealthEnergyFeeling.normal;
    _stressFeeling = HealthStressFeeling.medium;
    _bodyFeeling = HealthBodyFeeling.normal;
    _moodFeeling = HealthMoodFeeling.calm;
  }

  /// 取某天的状态分：今天用实时值，历史日期只有存在手动记录时才返回分数。
  int? _statusScoreForDay(DateTime date) {
    if (DateUtils.isSameDay(date, _today)) {
      return _statusResult.score;
    }
    final record = _manualRecords[healthManualDateKey(date)];
    if (record == null) {
      return null;
    }
    return _calculateStatusForRecord(record, date).score;
  }

  /// 用历史记录中的主观感受，加上当天的饮食和训练数据，重新计算历史状态分。
  HealthStatusResult _calculateStatusForRecord(
    HealthManualRecordData record,
    DateTime date,
  ) {
    return _calculateStatus(
      sleep: _enumValue(
        HealthSleepFeeling.values,
        record.sleep,
        HealthSleepFeeling.normal,
      ),
      energy: _enumValue(
        HealthEnergyFeeling.values,
        record.energy,
        HealthEnergyFeeling.normal,
      ),
      stress: _enumValue(
        HealthStressFeeling.values,
        record.stress,
        HealthStressFeeling.medium,
      ),
      body: _enumValue(
        HealthBodyFeeling.values,
        record.body,
        HealthBodyFeeling.normal,
      ),
      mood: _enumValue(
        HealthMoodFeeling.values,
        record.mood,
        HealthMoodFeeling.calm,
      ),
      foodCalories: _foodCaloriesForDay(date),
      workoutGroups: _workoutGroupsForDay(date),
    );
  }

  /// 汇总指定日期的饮食热量；今天直接使用父级传入的实时值。
  int _foodCaloriesForDay(DateTime date) {
    if (DateUtils.isSameDay(date, _today)) {
      return widget.foodCalories;
    }
    return widget.foodLogs
        .where((entry) => DateUtils.isSameDay(entry.recordedAt, date))
        .fold(0, (total, entry) => total + entry.calories);
  }

  /// 汇总指定日期的训练组数；今天直接使用父级传入的实时值。
  int _workoutGroupsForDay(DateTime date) {
    if (DateUtils.isSameDay(date, _today)) {
      return widget.workoutGroups;
    }
    return widget.workoutHistory
        .where((entry) => DateUtils.isSameDay(entry.finishedAt, date))
        .fold(0, (total, entry) => total + entry.totalGroups);
  }

  /// 统一构造健康评分输入，避免页面各处重复拼装参数。
  HealthStatusResult _calculateStatus({
    required HealthSleepFeeling sleep,
    required HealthEnergyFeeling energy,
    required HealthStressFeeling stress,
    required HealthBodyFeeling body,
    required HealthMoodFeeling mood,
    required int foodCalories,
    required int workoutGroups,
  }) {
    return const HealthStatusCalculator().calculate(
      input: HealthStatusInput(
        sleep: sleep,
        energy: energy,
        stress: stress,
        body: body,
        mood: mood,
        foodCalories: foodCalories,
        workoutGroups: workoutGroups,
      ),
    );
  }

  /// 把存储中的枚举名称安全转回枚举值，未知值使用 fallback。
  T _enumValue<T extends Enum>(List<T> values, String name, T fallback) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }

  /// 把身体不适枚举转换成摘要中展示的说明文字。
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

  /// 把系统健康数据转换成页面日期条需要的七天模型；无数据时仍保留真实日期。
  List<HealthDay> _buildHealthDays(HealthSystemSnapshot snapshot) {
    // 健康页只接受系统健康/传感器返回值；缺权限时保留真实日期但不填假指标。
    final samples =
        snapshot.hasAnyData ? snapshot.days : _recentEmptyHealthSamples();
    return samples.map((sample) => _buildHealthDay(sample, snapshot)).toList();
  }

  /// 生成最近七天的空健康样本，避免无权限时展示虚构指标。
  List<HealthSystemDaySample> _recentEmptyHealthSamples() {
    final today = _today;
    return List.generate(
      7,
      (index) => HealthSystemDaySample.empty(
        today.subtract(Duration(days: 6 - index)),
      ),
    );
  }

  /// 把单日系统健康样本转换成页面展示模型，心率缺失时可回退到实时传感器值。
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
      ],
    );
  }

  /// 构造单个指标；没有系统记录时显示占位符而不是 0。
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

  /// 计算完成目标的百分比文案。
  String _percentLabel(num? value, num goal) {
    if (value == null || goal <= 0) {
      return '无数据';
    }
    return '${((value / goal) * 100).round()}%';
  }

  /// 今天显示“今天”，其他日期显示中文星期。
  String _weekdayLabel(DateTime date) {
    final today = _today;
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return '今天';
    }
    return const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];
  }

  /// 给整数添加千位分隔符，提升步数等大数值的可读性。
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

  /// 可空整数的格式化入口，空值继续返回空值。
  String? _formatOptionalWhole(int? value) {
    if (value == null) {
      return null;
    }
    return _formatWhole(value);
  }

  /// 可空睡眠分钟数的格式化入口。
  String? _formatOptionalSleep(int? minutes) {
    if (minutes == null) {
      return null;
    }
    return _formatSleep(minutes);
  }

  /// 把分钟数转换成“小时 + 分钟”的展示格式。
  String _formatSleep(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return '${hours}h ${rest}m';
  }
}

/// 健康页顶部的日期横向选择条。
class _HealthDateStrip extends StatelessWidget {
  const _HealthDateStrip({
    required this.days,
    required this.selectedDay,
    required this.today,
    required this.statusScores,
    required this.onSelect,
  });

  final List<HealthDay> days;
  final HealthDay selectedDay;
  final DateTime today;
  final Map<String, int> statusScores;
  final ValueChanged<HealthDay> onSelect;

  @override
  Widget build(BuildContext context) {
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
                            score: statusScores[
                                healthManualDateKey(days[index].date)],
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

/// 日期条中的单天胶囊。
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
