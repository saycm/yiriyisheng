// 中文注释：全局基础配置，集中放置颜色、版本和跨模块常量。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App 的五个核心生活模块，底部导航和模块切换都使用这个枚举。
enum LifeModule { plan, finance, food, workout, health }

/// 桌面小组件的快捷写入动作，点击小组件按钮后会转到对应模块。
enum WidgetQuickAction {
  addTodo,
  addFinance,
  addFood,
  startWorkout,
  openHealth,
}

/// 全局配色表：背景、卡片、主色、文字和一众语义色。
class AppColors {
  static const background = Color(0xFFF6F8FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFEFF5FF);
  static const primary = Color(0xFF5D72F6);
  static const primarySoft = Color(0xFFE9EDFF);
  static const accent = Color(0xFFFFB35C);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF8B97AC);
  static const financeRed = Color(0xFFF35F64);
  static const success = Color(0xFF31C48D);
  static const line = Color(0xFFE4EAF6);
  static const lavender = Color(0xFF8B7CF6);
  static const sun = Color(0xFFF4B64A);
  static const sky = Color(0xFF38BDF8);
  static const mintSoft = Color(0xFFE9F9F2);
  static const roseSoft = Color(0xFFFFEEF2);
}

/// 用户主题偏好：跟随系统 / 浅色 / 深色。
enum AppThemePreference { system, light, dark }

/// 主题偏好的序列化、显示文案和 ThemeMode 转换。
extension AppThemePreferenceX on AppThemePreference {
  String get storageKey {
    switch (this) {
      case AppThemePreference.light:
        return 'light';
      case AppThemePreference.dark:
        return 'dark';
      case AppThemePreference.system:
        return 'system';
    }
  }

  String get label {
    switch (this) {
      case AppThemePreference.light:
        return '浅色';
      case AppThemePreference.dark:
        return '深色';
      case AppThemePreference.system:
        return '跟随系统';
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
        return ThemeMode.system;
    }
  }

  static AppThemePreference fromStorageKey(String? raw) {
    switch (raw) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      default:
        return AppThemePreference.system;
    }
  }
}

/// 全局设置控制器：保存主题模式和每日记录提醒开关，并同步到 Android 原生层。
class AppSettingsController extends ChangeNotifier {
  AppSettingsController();

  // 主题和提醒设置需要落到原生层，方便 Android 重启后仍能恢复。
  static const _channel = MethodChannel('pingsheng_life/app_preferences');

  AppThemePreference _themePreference = AppThemePreference.system;
  bool _dailyRecordReminderEnabled = false;

  AppThemePreference get themePreference => _themePreference;
  bool get dailyRecordReminderEnabled => _dailyRecordReminderEnabled;

  Future<void> load() async {
    try {
      // App 启动时先读一次偏好，再通过 notifyListeners 触发 MaterialApp 重建。
      final result = await _channel.invokeMapMethod<String, Object?>(
        'loadAppPreferences',
      );
      _themePreference = AppThemePreferenceX.fromStorageKey(
        result?['themeMode'] as String?,
      );
      _dailyRecordReminderEnabled =
          result?['dailyRecordReminderEnabled'] as bool? ?? false;
      notifyListeners();
    } on MissingPluginException {
      // 桌面测试环境没有原生设置通道，保留默认设置即可。
    }
  }

  Future<void> updateThemePreference(AppThemePreference preference) async {
    _themePreference = preference;
    notifyListeners();
    try {
      await _channel.invokeMethod<void>('saveThemeMode', {
        'themeMode': preference.storageKey,
      });
    } on MissingPluginException {
      // 非 Android 环境只更新当前会话，不影响主流程。
    }
  }

  Future<bool> updateDailyRecordReminder(bool enabled) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'setDailyRecordReminder',
        {'enabled': enabled},
      );
      _dailyRecordReminderEnabled =
          result?['enabled'] as bool? ?? (enabled && result != null);
      notifyListeners();
      return result?['permissionGranted'] as bool? ??
          _dailyRecordReminderEnabled;
    } on MissingPluginException {
      _dailyRecordReminderEnabled = enabled;
      notifyListeners();
      return enabled;
    }
  }
}

/// 通过 InheritedNotifier 把 AppSettingsController 提供给整棵 Widget 树。
class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope?.notifier != null, 'AppSettingsScope not found');
    return scope!.notifier!;
  }
}

const String apiBaseUrl = String.fromEnvironment(
  // 发布构建可以用 --dart-define 覆盖服务端地址，不需要改源码。
  'PINGSHENG_API_BASE_URL',
  defaultValue: 'http://192.168.20.11:3000',
);
const String appVersionName = String.fromEnvironment(
  'PINGSHENG_APP_VERSION_NAME',
  defaultValue: '1.0.75',
);
const int appVersionCode = int.fromEnvironment(
  'PINGSHENG_APP_VERSION_CODE',
  defaultValue: 76,
);

final RegExp authHiddenOrWhitespacePattern =
    RegExp(r'[\s\u00A0\u200B-\u200D\uFEFF\u3000]');
