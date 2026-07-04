// 中文注释：全局基础配置，集中放置颜色、版本和跨模块常量。

import 'package:flutter/material.dart';

enum LifeModule { plan, finance, food, workout, health }

enum WidgetQuickAction {
  addTodo,
  addFinance,
  addFood,
  startWorkout,
  openHealth,
}

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

const String apiBaseUrl = String.fromEnvironment(
  'PINGSHENG_API_BASE_URL',
  defaultValue: 'http://192.168.20.11:3000',
);
const String appVersionName = String.fromEnvironment(
  'PINGSHENG_APP_VERSION_NAME',
  defaultValue: '1.0.42',
);
const int appVersionCode = int.fromEnvironment(
  'PINGSHENG_APP_VERSION_CODE',
  defaultValue: 43,
);

final RegExp authHiddenOrWhitespacePattern =
    RegExp(r'[\s\u00A0\u200B-\u200D\uFEFF\u3000]');
