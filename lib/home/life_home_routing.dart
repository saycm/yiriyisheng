// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

part of 'life_home.dart';

/// 把路由路径解析成对应的生活模块，未知路径默认回到计划页。
LifeModule _lifeModuleFromRoute(String route) {
  // 小组件、系统路由和底部导航最终都映射到同一组 LifeModule 枚举。
  final path = _lifeHomeRoutePath(route);
  return switch (path) {
    '/finance' => LifeModule.finance,
    '/food' => LifeModule.food,
    '/workout' => LifeModule.workout,
    '/health' => LifeModule.health,
    _ => LifeModule.plan,
  };
}

/// 去掉查询参数，得到模块路由的纯路径。
String _lifeHomeRoutePath(String route) {
  final uri = Uri.tryParse(route);
  final path = uri?.path ?? route;
  return path.isEmpty ? '/' : path;
}

/// 从完整路由（含 query）中解析小组件快捷动作。
WidgetQuickAction? _widgetQuickActionFromRoute(String route) {
  // /plan?action=add_todo 这类路由只保存动作名，具体弹层由模块页面消费。
  final uri = Uri.tryParse(route);
  return _widgetQuickActionFromName(uri?.queryParameters['action']);
}

/// 把动作名转换成快捷动作枚举。
WidgetQuickAction? _widgetQuickActionFromName(String? action) {
  return switch (action) {
    'add_todo' => WidgetQuickAction.addTodo,
    'add_finance' => WidgetQuickAction.addFinance,
    'add_food' => WidgetQuickAction.addFood,
    'start_workout' => WidgetQuickAction.startWorkout,
    'open_health' => WidgetQuickAction.openHealth,
    _ => null,
  };
}
