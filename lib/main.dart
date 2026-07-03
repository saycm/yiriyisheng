import 'package:flutter/material.dart';

import 'app/app.dart';

export 'app/app.dart';
export 'core/app_core.dart';
export 'home/life_home.dart';
export 'models/models.dart';
export 'modules/finance/finance.dart';
export 'modules/finance/finance_ai_core.dart';
export 'modules/workout/workout.dart';
export 'storage/storage.dart';

void main() {
  runApp(const PingShengApp(enableAuth: true));
}
