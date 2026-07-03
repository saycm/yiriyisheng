import 'package:flutter/material.dart';

import '../auth/auth.dart';
import '../core/app_core.dart';
import '../home/life_home.dart';

class PingShengApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Widget entryBuilder(BuildContext context) {
      if (authPreview) {
        return const AuthPreviewPage();
      }
      return enableAuth
          ? AuthGate(updateResponseOverride: updateResponseOverride)
          : const LifeHomePage();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '平生',
      theme: ThemeData(
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
      ),
      routes: {
        '/': entryBuilder,
        '/finance': entryBuilder,
        '/plan': entryBuilder,
        '/food': entryBuilder,
        '/workout': entryBuilder,
        '/health': entryBuilder,
      },
      onGenerateRoute: (settings) {
        // 桌面小组件会携带 action 查询参数，未知路由统一交给首页解析。
        return MaterialPageRoute<void>(
          settings: settings,
          builder: entryBuilder,
        );
      },
    );
  }
}
