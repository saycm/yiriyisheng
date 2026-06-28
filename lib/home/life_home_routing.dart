part of '../main.dart';

LifeModule _lifeModuleFromRoute(String route) {
  final path = _lifeHomeRoutePath(route);
  return switch (path) {
    '/finance' => LifeModule.finance,
    '/food' => LifeModule.food,
    '/workout' => LifeModule.workout,
    '/health' => LifeModule.health,
    _ => LifeModule.plan,
  };
}

String _lifeHomeRoutePath(String route) {
  final uri = Uri.tryParse(route);
  final path = uri?.path ?? route;
  return path.isEmpty ? '/' : path;
}

WidgetQuickAction? _widgetQuickActionFromRoute(String route) {
  final uri = Uri.tryParse(route);
  return _widgetQuickActionFromName(uri?.queryParameters['action']);
}

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
