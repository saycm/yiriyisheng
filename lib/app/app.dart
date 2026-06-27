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
        ),
        fontFamily: 'sans',
        scaffoldBackgroundColor: AppColors.background,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
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
  static const background = Color(0xFFF4F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF5E7CF7);
  static const primarySoft = Color(0xFFE7EBFF);
  static const accent = Color(0xFFFFA86B);
  static const ink = Color(0xFF182033);
  static const muted = Color(0xFF8B92A6);
  static const financeRed = Color(0xFFE85C59);
  static const success = Color(0xFF41C782);
  static const line = Color(0xFFE5EAF5);
}

const String _apiBaseUrl = String.fromEnvironment(
  'PINGSHENG_API_BASE_URL',
  defaultValue: 'http://192.168.20.11:3000',
);
const String _appVersionName = String.fromEnvironment(
  'PINGSHENG_APP_VERSION_NAME',
  defaultValue: '1.0.12',
);
const int _appVersionCode = int.fromEnvironment(
  'PINGSHENG_APP_VERSION_CODE',
  defaultValue: 13,
);

final RegExp _authHiddenOrWhitespacePattern =
    RegExp(r'[\s\u00A0\u200B-\u200D\uFEFF\u3000]');
