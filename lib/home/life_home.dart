// 中文注释：首页状态与模块调度层，负责组合财务、计划、饮食、锻炼和健康模块。

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_core.dart';
import '../models/models.dart';
import '../modules/finance/finance.dart';
import '../modules/finance/finance_ai_core.dart';
import '../modules/food/food.dart';
import '../modules/health/health.dart';
import '../modules/plan/plan.dart';
import '../modules/workout/workout.dart';
import '../shared/shared.dart';
import '../storage/storage.dart';

part 'home_module_page_builder.dart';
part 'life_home_mutations.dart';
part 'life_home_overlays.dart';
part 'life_home_page.dart';
part 'life_home_persistence.dart';
part 'life_home_routing.dart';
part 'life_home_seed_data.dart';
part 'life_home_state.dart';
part 'widgets/quick_record_sheet.dart';
