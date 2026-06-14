part of '../main.dart';

class LifeSummarySnapshot {
  const LifeSummarySnapshot({
    required this.foodCalories,
    required this.workoutGroupsByAction,
    required this.todos,
    required this.financeRecords,
  });

  final int foodCalories;
  final Map<String, int> workoutGroupsByAction;
  final List<TodoItem>? todos;
  final List<FinanceRecord>? financeRecords;
}

enum SystemHealthStatus {
  loading,
  ok,
  permissionRequired,
  unavailable,
  updateRequired,
  error,
}

class HealthSensorSnapshot {
  const HealthSensorSnapshot({
    required this.stepCounterAvailable,
    required this.heartRateSensorAvailable,
    required this.accelerometerAvailable,
    this.stepCounterSinceBoot,
    this.heartRateBpm,
    this.accelerationMagnitude,
    this.lastSensorUpdate,
  });

  final bool stepCounterAvailable;
  final bool heartRateSensorAvailable;
  final bool accelerometerAvailable;
  final int? stepCounterSinceBoot;
  final double? heartRateBpm;
  final double? accelerationMagnitude;
  final DateTime? lastSensorUpdate;

  String get summary {
    final connected = [
      if (stepCounterAvailable) '计步器',
      if (heartRateSensorAvailable) '心率',
      if (accelerometerAvailable) '加速度',
    ];
    return connected.isEmpty ? '未检测到可用传感器' : connected.join(' / ');
  }

  factory HealthSensorSnapshot.fromMap(Object? value) {
    final map = value is Map<Object?, Object?> ? value : const {};
    final millis = _healthInt(map['lastSensorUpdateMillis']);
    return HealthSensorSnapshot(
      stepCounterAvailable: map['stepCounterAvailable'] == true,
      heartRateSensorAvailable: map['heartRateSensorAvailable'] == true,
      accelerometerAvailable: map['accelerometerAvailable'] == true,
      stepCounterSinceBoot: _healthInt(map['stepCounterSinceBoot']),
      heartRateBpm: _healthDouble(map['heartRateBpm']),
      accelerationMagnitude: _healthDouble(map['accelerationMagnitude']),
      lastSensorUpdate:
          millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}

class HealthSystemDaySample {
  const HealthSystemDaySample({
    required this.date,
    this.steps,
    this.activeCaloriesKcal,
    this.basalCaloriesKcal,
    this.sleepMinutes,
    this.heartRateBpm,
    this.respiratoryRate,
  });

  final DateTime date;
  final int? steps;
  final double? activeCaloriesKcal;
  final double? basalCaloriesKcal;
  final int? sleepMinutes;
  final int? heartRateBpm;
  final double? respiratoryRate;

  factory HealthSystemDaySample.empty(DateTime date) {
    return HealthSystemDaySample(
        date: DateTime(date.year, date.month, date.day));
  }

  factory HealthSystemDaySample.fromMap(Object? value) {
    final map = value is Map<Object?, Object?> ? value : const {};
    final parsedDate = DateTime.tryParse(map['dateIso'] as String? ?? '');
    return HealthSystemDaySample(
      date: parsedDate ?? DateTime.now(),
      steps: _healthInt(map['steps']),
      activeCaloriesKcal: _healthDouble(map['activeCaloriesKcal']),
      basalCaloriesKcal: _healthDouble(map['basalCaloriesKcal']),
      sleepMinutes: _healthInt(map['sleepMinutes']),
      heartRateBpm: _healthInt(map['heartRateBpm']),
      respiratoryRate: _healthDouble(map['respiratoryRate']),
    );
  }
}

class HealthSystemSnapshot {
  const HealthSystemSnapshot({
    required this.status,
    required this.message,
    required this.days,
    required this.sensors,
    this.lastUpdated,
  });

  final SystemHealthStatus status;
  final String message;
  final List<HealthSystemDaySample> days;
  final HealthSensorSnapshot sensors;
  final DateTime? lastUpdated;

  bool get isReady => status == SystemHealthStatus.ok;
  bool get needsPermission => status == SystemHealthStatus.permissionRequired;

  static HealthSystemSnapshot loading() {
    return HealthSystemSnapshot(
      status: SystemHealthStatus.loading,
      message: '正在读取系统健康数据',
      days: [HealthSystemDaySample.empty(DateTime.now())],
      sensors: const HealthSensorSnapshot(
        stepCounterAvailable: false,
        heartRateSensorAvailable: false,
        accelerometerAvailable: false,
      ),
    );
  }

  static HealthSystemSnapshot unsupported(String message) {
    return HealthSystemSnapshot(
      status: SystemHealthStatus.unavailable,
      message: message,
      days: [HealthSystemDaySample.empty(DateTime.now())],
      sensors: const HealthSensorSnapshot(
        stepCounterAvailable: false,
        heartRateSensorAvailable: false,
        accelerometerAvailable: false,
      ),
      lastUpdated: DateTime.now(),
    );
  }

  factory HealthSystemSnapshot.fromMap(Map<Object?, Object?> map) {
    final rawDays = map['days'];
    final parsedDays = rawDays is List<Object?>
        ? rawDays.map(HealthSystemDaySample.fromMap).toList()
        : <HealthSystemDaySample>[];
    return HealthSystemSnapshot(
      status: _healthStatusFromName(map['status'] as String?),
      message: map['message'] as String? ?? '系统健康数据状态未知',
      days: parsedDays.isEmpty
          ? [HealthSystemDaySample.empty(DateTime.now())]
          : parsedDays,
      sensors: HealthSensorSnapshot.fromMap(map['sensors']),
      lastUpdated: DateTime.tryParse(map['lastUpdated'] as String? ?? ''),
    );
  }
}

class _SystemHealthStore {
  const _SystemHealthStore();

  static const _channel = MethodChannel('pingsheng_life/system_health');

  Future<HealthSystemSnapshot> load() async {
    try {
      final result = await _channel.invokeMethod<Object?>('loadHealthSnapshot');
      if (result is Map<Object?, Object?>) {
        return HealthSystemSnapshot.fromMap(result);
      }
      return HealthSystemSnapshot.unsupported('系统健康接口返回了无法识别的数据。');
    } on MissingPluginException {
      return HealthSystemSnapshot.unsupported('当前平台没有系统健康数据通道。');
    } on PlatformException catch (error) {
      return HealthSystemSnapshot.unsupported(
        error.message ?? '系统健康数据读取失败。',
      );
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final result =
          await _channel.invokeMethod<Object?>('requestHealthPermissions');
      if (result is Map<Object?, Object?>) {
        return result['granted'] == true;
      }
      return false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openHealthConnectSettings');
    } on MissingPluginException {
      // 非 Android 平台没有系统健康设置入口，页面仍会提示当前状态。
    }
  }
}

SystemHealthStatus _healthStatusFromName(String? name) {
  return switch (name) {
    'ok' => SystemHealthStatus.ok,
    'permissionRequired' => SystemHealthStatus.permissionRequired,
    'updateRequired' => SystemHealthStatus.updateRequired,
    'error' => SystemHealthStatus.error,
    'loading' => SystemHealthStatus.loading,
    _ => SystemHealthStatus.unavailable,
  };
}

int? _healthInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

double? _healthDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return null;
}
