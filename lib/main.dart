import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

part 'app/app.dart';
part 'auth/auth.dart';
part 'api/pingsheng_api.dart';
part 'models/life_data.dart';
part 'models/system_health.dart';
part 'storage/app_data_store.dart';
part 'storage/widget_store.dart';
part 'home/life_home_page.dart';
part 'modules/plan/plan_module.dart';
part 'modules/finance/finance_module.dart';
part 'modules/food/food_module.dart';
part 'modules/workout/workout_module.dart';
part 'modules/health/health_module.dart';
part 'shared/module_shell.dart';

void main() {
  runApp(const PingShengApp(enableAuth: true));
}
