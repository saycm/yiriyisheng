part of '../../main.dart';

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
  static const _healthStore = _SystemHealthStore();

  var _selectedIndex = 0;
  int _handledQuickActionToken = 0;
  var _loadingHealth = true;
  HealthSystemSnapshot _systemHealth = HealthSystemSnapshot.loading();
  String _bodyTag = '正常';
  double _energyLevel = 3;
  double _fatigueLevel = 2;
  double _stressLevel = 2;
  String _painNote = '';
  String _moodNote = '平稳';

  List<HealthDay> get _days => _buildHealthDays(_systemHealth);

  HealthDay get _selectedDay {
    final days = _days;
    final index = math.min(_selectedIndex, days.length - 1);
    return days[index];
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

  Future<void> _requestSystemHealthAccess() async {
    await _healthStore.requestPermissions();
    await _loadSystemHealth();
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
                      _moduleSwitchBarReservedHeight + 24,
                    ),
                    children: [
                      _HealthDateStrip(
                        days: days,
                        selectedDay: selectedDay,
                        onSelect: (day) {
                          setState(() => _selectedIndex = days.indexOf(day));
                        },
                      ),
                      const SizedBox(height: 16),
                      _HealthSystemStatusCard(
                        snapshot: _systemHealth,
                        loading: _loadingHealth,
                        onRefresh: _loadSystemHealth,
                        onRequestPermission: _requestSystemHealthAccess,
                        onOpenSettings: _openSystemHealthSettings,
                      ),
                      const SizedBox(height: 14),
                      _HealthRingsCard(day: selectedDay),
                      const SizedBox(height: 14),
                      _HealthLinkedSummaryCard(
                        foodCalories: widget.foodCalories,
                        workoutGroups: widget.workoutGroups,
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.05,
                        children: selectedDay.metrics
                            .map(
                              (metric) => _HealthMetricCard(
                                metric: metric,
                                onTap: () => _openMetricSheet(metric),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 14),
                      _HealthManualStatusCard(
                        bodyTag: _bodyTag,
                        energyLevel: _energyLevel.round(),
                        fatigueLevel: _fatigueLevel.round(),
                        stressLevel: _stressLevel.round(),
                        painNote: _painNote,
                        moodNote: _moodNote,
                        onTap: _openManualRecordSheet,
                      ),
                      const SizedBox(height: 14),
                      _HealthReminderCard(
                        reminders: _healthReminders(selectedDay),
                      ),
                      const SizedBox(height: 14),
                      _HealthTrendDashboardCard(day: selectedDay),
                      const SizedBox(height: 14),
                      _HealthSensorCard(snapshot: _systemHealth.sensors),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: _moduleSwitchBarBottomGap),
                child: _WorkoutBottomNav(
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

  void _openMetricSheet(HealthMetric metric) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HealthMetricSheet(
        day: _selectedDay,
        metric: metric,
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
          });
        },
      ),
    );
  }

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
    return _ModuleGlassHeader(
      module: LifeModule.health,
      title: '健康',
      onOpenModules: onOpenModules,
      onOpenMore: onOpenSummary,
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

class _HealthLinkedSummaryCard extends StatelessWidget {
  const _HealthLinkedSummaryCard({
    required this.foodCalories,
    required this.workoutGroups,
  });

  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    return _ModuleLinkedSummaryCard(
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
                        '手动身体记录',
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
            painter: _TinyBarsPainter(
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
    return _InfoSheetFrame(
      title: '身体记录',
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
          _SheetTextField(
            keyName: 'health_pain_note',
            controller: _painController,
            label: '疼痛',
            hint: '例如：肩颈紧、膝盖不适',
          ),
          const SizedBox(height: 10),
          _SheetTextField(
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

class _HealthSensorCard extends StatelessWidget {
  const _HealthSensorCard({required this.snapshot});

  final HealthSensorSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final values = [
      (
        '计步器',
        snapshot.stepCounterSinceBoot == null
            ? (snapshot.stepCounterAvailable ? '可用' : '无')
            : '${snapshot.stepCounterSinceBoot} 步'
      ),
      (
        '心率',
        snapshot.heartRateBpm == null
            ? (snapshot.heartRateSensorAvailable ? '待读取' : '无')
            : '${snapshot.heartRateBpm!.round()} bpm'
      ),
      (
        '加速度',
        snapshot.accelerationMagnitude == null
            ? (snapshot.accelerometerAvailable ? '可用' : '无')
            : snapshot.accelerationMagnitude!.toStringAsFixed(1)
      ),
    ];
    return _ModuleLinkedSummaryCard(
      title: '手机传感器',
      subtitle: '来自系统 SensorManager 的实时设备能力和读数。',
      icon: Icons.sensors_rounded,
      values: values,
    );
  }
}

class _LinkedValue extends StatelessWidget {
  const _LinkedValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HealthMetricCard extends StatelessWidget {
  const _HealthMetricCard({
    required this.metric,
    required this.onTap,
  });

  final HealthMetric metric;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: metric.bars.isEmpty
                  ? Center(
                      child: Text(
                        metric.hasData ? metric.source : '等待系统数据',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _TinyBarsPainter(
                        values: metric.bars,
                        color: metric.color,
                      ),
                      child: const SizedBox.expand(),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    metric.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(metric.icon, color: metric.color, size: 22),
              ],
            ),
            Text(
              metric.unit,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthMetricSheet extends StatelessWidget {
  const _HealthMetricSheet({
    required this.day,
    required this.metric,
  });

  final HealthDay day;
  final HealthMetric metric;

  @override
  Widget build(BuildContext context) {
    final average = metric.bars.isEmpty
        ? null
        : (metric.bars.fold<double>(0, (sum, value) => sum + value) /
                metric.bars.length)
            .toStringAsFixed(1);

    return _InfoSheetFrame(
      title: metric.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: metric.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(metric.icon, color: metric.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.title.replaceAll('⌄', ''),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.hasData
                            ? '${metric.value} ${metric.unit}'
                            : metric.value,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 120,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: metric.bars.isEmpty
                ? Center(
                    child: Text(
                      metric.statusText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _TinyBarsPainter(
                      values: metric.bars,
                      color: metric.color,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 14),
          _EmptyCard(
            title: '趋势摘要',
            subtitle: average == null
                ? '当前没有来自 ${metric.source} 的可用采样点。'
                : '最近 ${metric.bars.length} 个真实采样点平均值 $average，当前记录为 ${metric.value} ${metric.unit}。',
          ),
        ],
      ),
    );
  }
}

class _HealthSummarySheet extends StatelessWidget {
  const _HealthSummarySheet({
    required this.day,
    required this.foodCalories,
    required this.workoutGroups,
    required this.bodyTag,
    required this.moodNote,
  });

  final HealthDay day;
  final int foodCalories;
  final int workoutGroups;
  final String bodyTag;
  final String moodNote;

  @override
  Widget build(BuildContext context) {
    final steps = day.metrics.firstWhere((metric) => metric.title == '今日步数');
    final energy = day.metrics.firstWhere((metric) => metric.title == '今日能量');
    final sleep = day.metrics.firstWhere((metric) => metric.title == '昨晚睡眠');

    return _InfoSheetFrame(
      title: '健康总览',
      child: Column(
        children: [
          _HealthSummaryTile(
            color: const Color(0xFF48CE81),
            title: '活动完成',
            value: day.ringLabels[0],
          ),
          _HealthSummaryTile(
            color: const Color(0xFFFF9559),
            title: '能量消耗',
            value: '${energy.value} ${energy.unit}',
          ),
          _HealthSummaryTile(
            color: AppColors.primary,
            title: '饮食摄入',
            value: '$foodCalories kcal',
          ),
          _HealthSummaryTile(
            color: const Color(0xFF43C6C8),
            title: '锻炼完成',
            value: '$workoutGroups 组',
          ),
          _HealthSummaryTile(
            color: const Color(0xFF61CE86),
            title: '步数',
            value: '${steps.value} ${steps.unit}',
          ),
          _HealthSummaryTile(
            color: const Color(0xFF8D7CF6),
            title: '睡眠',
            value: sleep.value,
          ),
          _HealthSummaryTile(
            color: const Color(0xFFFF6F9D),
            title: '身体状态',
            value: '$bodyTag · $moodNote',
          ),
        ],
      ),
    );
  }
}

class _HealthSummaryTile extends StatelessWidget {
  const _HealthSummaryTile({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  const _ActivityRingsPainter({required this.progress});

  final List<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16;
    final rings = [
      (radius: 56.0, color: const Color(0xFF48CE81), value: progress[0]),
      (radius: 38.0, color: const Color(0xFFFF9559), value: progress[1]),
      (radius: 20.0, color: const Color(0xFF7D9CFF), value: progress[2]),
    ];

    for (final ring in rings) {
      paint.color = const Color(0xFFE9ECF4);
      canvas.drawCircle(center, ring.radius, paint);
      paint.color = ring.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ring.radius),
        -math.pi / 2,
        math.pi * 2 * ring.value,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

class _MiniRingsPainter extends CustomPainter {
  const _MiniRingsPainter({
    required this.selected,
    required this.progress,
  });

  final bool selected;
  final List<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = selected ? 2.7 : 2.2;
    final colors = [
      const Color(0xFF48CE81),
      const Color(0xFFFF9559),
      const Color(0xFF7D9CFF),
    ];

    for (var i = 0; i < 3; i++) {
      final radius = 15.0 - i * 4;
      paint.color = const Color(0xFFE7EAF2);
      canvas.drawCircle(center, radius, paint);
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress[i],
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRingsPainter oldDelegate) {
    return selected != oldDelegate.selected || progress != oldDelegate.progress;
  }
}

class _TinyBarsPainter extends CustomPainter {
  _TinyBarsPainter({
    required this.values,
    required this.color,
  });

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFFE9ECF4)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 2),
      Offset(size.width, size.height - 2),
      axisPaint,
    );
    if (values.isEmpty) {
      return;
    }

    final maxValue = math.max(1.0, values.reduce(math.max));
    final barWidth = size.width / (values.length * 1.55);
    final gap = barWidth * 0.55;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < values.length; i++) {
      final x = i * (barWidth + gap) + barWidth / 2;
      final height = (size.height - 8) * values[i] / maxValue;
      paint.strokeWidth = barWidth;
      canvas.drawLine(
        Offset(x, size.height - 4),
        Offset(x, size.height - 4 - height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TinyBarsPainter oldDelegate) {
    return values != oldDelegate.values || color != oldDelegate.color;
  }
}
