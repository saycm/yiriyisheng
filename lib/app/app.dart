part of '../main.dart';

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
        return _AuthPage(
          api: const _PingShengApi(),
          onSignedIn: (_) async {},
        );
      }
      return enableAuth
          ? _AuthGate(updateResponseOverride: updateResponseOverride)
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

const String _apiBaseUrl = String.fromEnvironment(
  'PINGSHENG_API_BASE_URL',
  defaultValue: 'http://192.168.20.11:3000',
);
const String _appVersionName = String.fromEnvironment(
  'PINGSHENG_APP_VERSION_NAME',
  defaultValue: '1.0.21',
);
const int _appVersionCode = int.fromEnvironment(
  'PINGSHENG_APP_VERSION_CODE',
  defaultValue: 22,
);

final RegExp _authHiddenOrWhitespacePattern =
    RegExp(r'[\s\u00A0\u200B-\u200D\uFEFF\u3000]');
