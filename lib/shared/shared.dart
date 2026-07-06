// 中文注释：跨模块共享 UI 组件，负责统一卡片、导航、弹层和模块外壳。

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth.dart';
import '../core/app_core.dart';
import '../models/models.dart';

part 'module_center_sheet.dart';
part 'module_common_widgets.dart';
part 'module_info_sheets.dart';
part 'module_settings_sheet.dart';
part 'module_shell.dart';
