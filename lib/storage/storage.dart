// 中文注释：本地存储层，负责 SQLite 持久化和桌面小组件数据同步。

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import '../modules/finance/finance_ai_core.dart';

part 'app_data_rows.dart';
part 'app_data_store.dart';
part 'app_data_tables.dart';
part 'widget_store.dart';
