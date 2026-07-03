import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void mockSystemHealthSnapshot() {
  const channel = MethodChannel('pingsheng_life/system_health');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'loadHealthSnapshot') {
      return {
        'status': 'ok',
        'message': '已连接 Health Connect 和本机传感器。',
        'lastUpdated': '2026-06-05T08:30:00.000Z',
        'sensors': {
          'stepCounterAvailable': true,
          'heartRateSensorAvailable': true,
          'accelerometerAvailable': true,
          'stepCounterSinceBoot': 11880,
          'heartRateBpm': 78.0,
          'accelerationMagnitude': 9.8,
          'lastSensorUpdateMillis': 1780619400000,
        },
        'days': [
          {
            'dateIso': '2026-06-03',
            'steps': 4300,
            'activeCaloriesKcal': 420.0,
            'basalCaloriesKcal': 1588.0,
            'sleepMinutes': 390,
            'heartRateBpm': 84,
            'respiratoryRate': 15.1,
          },
          {
            'dateIso': '2026-06-04',
            'steps': 4814,
            'activeCaloriesKcal': 520.0,
            'basalCaloriesKcal': 1591.0,
            'sleepMinutes': 435,
            'heartRateBpm': 88,
            'respiratoryRate': 15.3,
          },
          {
            'dateIso': '2026-06-05',
            'steps': 6320,
            'activeCaloriesKcal': 610.0,
            'basalCaloriesKcal': 1591.0,
            'sleepMinutes': 408,
            'heartRateBpm': 82,
            'respiratoryRate': 15.8,
          },
        ],
      };
    }
    if (call.method == 'requestHealthPermissions') {
      return {'granted': true, 'grantedCount': 6};
    }
    if (call.method == 'openHealthConnectSettings') {
      return null;
    }
    throw PlatformException(code: 'not_implemented');
  });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
}

void mockSystemHealthStatus({
  required String status,
  required String message,
  List<Map<String, Object?>> days = const [],
}) {
  const channel = MethodChannel('pingsheng_life/system_health');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'loadHealthSnapshot') {
      return {
        'status': status,
        'message': message,
        'lastUpdated': '2026-06-05T08:30:00.000Z',
        'sensors': {
          'stepCounterAvailable': false,
          'heartRateSensorAvailable': false,
          'accelerometerAvailable': false,
        },
        'days': days,
      };
    }
    if (call.method == 'requestHealthPermissions') {
      return {'granted': status == 'ok'};
    }
    if (call.method == 'openHealthConnectSettings') {
      return null;
    }
    throw PlatformException(code: 'not_implemented');
  });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
}

Future<void> dragPageUp(WidgetTester tester) async {
  await tester.dragFrom(const Offset(300, 500), const Offset(0, -360));
  await tester.pumpAndSettle();
}

Future<void> dragPageDown(WidgetTester tester) async {
  await tester.dragFrom(const Offset(300, 220), const Offset(0, 360));
  await tester.pumpAndSettle();
}

Future<void> dragUntilFound(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  bool up = true,
  int maxDrags = 8,
}) async {
  for (var index = 0; index < maxDrags && finder.evaluate().isEmpty; index++) {
    await tester.drag(
      scrollable ?? find.byType(Scrollable).first,
      Offset(0, up ? -360 : 360),
    );
    await tester.pumpAndSettle();
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

Future<void> openFinanceAiRecord(WidgetTester tester) async {
  final aiRecord = find.byKey(const ValueKey('finance_ai_record'));
  await dragUntilFound(
    tester,
    aiRecord,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(aiRecord);
  await tester.pumpAndSettle();
}

Future<void> tapWorkoutActionByName(
  WidgetTester tester,
  String actionName,
) async {
  final workoutList = find.byKey(const ValueKey('workout_main_list'));
  await dragUntilFound(
    tester,
    find.text(actionName),
    scrollable: workoutList,
    maxDrags: 18,
  );
  await tester.tap(find.text(actionName).first);
  await tester.pumpAndSettle();
}
