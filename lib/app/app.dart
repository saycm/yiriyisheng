// 中文注释：应用外层壳和启动流程，负责更新检查与首页挂载。

import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth.dart';
import '../core/app_core.dart';
import '../home/life_home.dart';
import '../ui_preview/liquid_glass_preview.dart';

class PingShengApp extends StatefulWidget {
  const PingShengApp({
    super.key,
    this.enableAuth = false,
    this.authPreview = false,
    this.updateResponseOverride,
  });

  final bool enableAuth;
  final bool authPreview;
  final Future<Map<String, dynamic>> Function()? updateResponseOverride;

  @override
  State<PingShengApp> createState() => _PingShengAppState();
}

class _PingShengAppState extends State<PingShengApp> {
  late final AppSettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = AppSettingsController();
    // 设置加载是异步的，先用默认主题启动，读到偏好后再刷新外层 MaterialApp。
    unawaited(_settingsController.load());
  }

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget entryBuilder(BuildContext context) {
      // 测试、预览和正式登录共用同一个 App 壳，通过开关选择入口。
      if (widget.authPreview) {
        return const AuthPreviewPage();
      }
      return widget.enableAuth
          ? AuthGate(updateResponseOverride: widget.updateResponseOverride)
          : const LifeHomePage();
    }

    return AppSettingsScope(
      controller: _settingsController,
      child: AnimatedBuilder(
        animation: _settingsController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: '平生',
            themeMode: _settingsController.themePreference.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            routes: {
              '/': entryBuilder,
              '/finance': entryBuilder,
              '/plan': entryBuilder,
              '/food': entryBuilder,
              '/workout': entryBuilder,
              '/health': entryBuilder,
              '/liquid-glass-preview': (_) => const LiquidGlassPreviewPage(),
            },
            onGenerateRoute: (settings) {
              // 桌面小组件会携带 action 查询参数，未知路由统一交给首页解析。
              return MaterialPageRoute<void>(
                settings: settings,
                builder: entryBuilder,
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        surfaceTint: AppColors.surfaceTint,
      ),
      fontFamily: 'sans',
      scaffoldBackgroundColor: AppColors.background,
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),
      chipTheme: _buildReadableChipTheme(),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.muted.withValues(alpha: 0.45),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: const Color(0xFF151B2C),
    );
    return ThemeData(
      colorScheme: colorScheme,
      fontFamily: 'sans',
      scaffoldBackgroundColor: const Color(0xFF0F1424),
      canvasColor: const Color(0xFF0F1424),
      splashColor: AppColors.primary.withValues(alpha: 0.14),
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFAEB8FF),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      chipTheme: _buildReadableChipTheme(),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      useMaterial3: true,
    );
  }

  ChipThemeData _buildReadableChipTheme() {
    return ChipThemeData.fromDefaults(
      brightness: Brightness.light,
      secondaryColor: AppColors.primary,
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
    ).copyWith(
      backgroundColor: AppColors.background,
      disabledColor: AppColors.line,
      selectedColor: AppColors.primarySoft,
      secondarySelectedColor: AppColors.primarySoft,
      checkmarkColor: AppColors.primary,
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w900,
      ),
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
