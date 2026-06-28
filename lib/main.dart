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
part 'models/life_event.dart';
part 'models/system_health.dart';
part 'storage/app_data_store.dart';
part 'storage/widget_store.dart';
part 'home/life_home_page.dart';
part 'home/life_home_persistence.dart';
part 'home/life_home_overlays.dart';
part 'home/life_home_mutations.dart';
part 'home/life_home_routing.dart';
part 'home/life_home_seed_data.dart';
part 'home/home_module_page_builder.dart';
part 'home/widgets/quick_record_sheet.dart';
part 'home/widgets/todo_linked_action_sheet.dart';
part 'modules/plan/plan_shared.dart';
part 'modules/plan/plan_module.dart';
part 'modules/plan/plan_state.dart';
part 'modules/plan/plan_actions.dart';
part 'modules/plan/sheets/inbox_quick_capture_sheet.dart';
part 'modules/plan/sheets/plan_more_sheet.dart';
part 'modules/plan/sheets/todo_editor_sheet.dart';
part 'modules/plan/widgets/inbox_view.dart';
part 'modules/plan/widgets/plan_header.dart';
part 'modules/plan/widgets/plan_stats_view.dart';
part 'modules/plan/widgets/today_overview_card.dart';
part 'modules/plan/widgets/plan_body.dart';
part 'modules/plan/widgets/todo_card.dart';
part 'modules/plan/widgets/todo_list.dart';
part 'modules/plan/widgets/week_plan_view.dart';
part 'modules/finance/finance_module.dart';
part 'modules/food/food_module.dart';
part 'modules/workout/workout_models.dart';
part 'modules/workout/workout_module.dart';
part 'modules/health/health_module.dart';
part 'shared/module_shell.dart';

void main() {
  runApp(const PingShengApp(enableAuth: true));
}
