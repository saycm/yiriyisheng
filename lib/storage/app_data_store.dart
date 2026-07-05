// 中文注释：本地存储层，负责 SQLite 持久化和桌面小组件数据同步。

part of 'storage.dart';

abstract class LifeSummaryStore {
  // 首页只依赖这个抽象读写完整快照，测试时可以替换成内存实现。
  Future<LifeSummarySnapshot?> load();

  Future<void> save({
    required int foodCalories,
    required Map<String, int> workoutGroupsByAction,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
    required List<WorkoutPlan> workoutPlans,
    required ActiveWorkoutSession? activeWorkoutSession,
    required List<WorkoutHistoryEntry> workoutHistory,
    required String aiFinanceEndpoint,
    required String aiFinanceModel,
    required String aiFinanceApiKey,
    required AiFinanceParseStrategy aiFinanceParseStrategy,
    required String aiFinanceCustomPrompt,
  });
}

class AppDataStoreRows {
  const AppDataStoreRows._();

  // 财务记录在 SQLite 中按行保存；复杂字段转 JSON，读取时再还原成模型。
  static Map<String, Object?> financeRecordToRow(
    FinanceRecord record,
    int position,
  ) {
    return {
      'position': position,
      'title': record.title,
      'subtitle': record.subtitle,
      'amount': record.amount,
      'type': record.type,
      'date': record.date?.toIso8601String(),
      'account': record.account,
      'tagsJson': jsonEncode(record.tags),
    };
  }

  static FinanceRecord financeRecordFromRow(Map<String, Object?> row) {
    final title = row['title'] as String? ?? '手动记录';
    return FinanceRecord(
      icon: financeIconForTitle(title),
      title: title,
      subtitle: row['subtitle'] as String? ?? '手动记录',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      type: row['type'] as String? ?? '支出',
      date: DateTime.tryParse(row['date'] as String? ?? ''),
      account: (row['account'] as String?)?.trim().isEmpty == false
          ? (row['account'] as String).trim()
          : '银行卡',
      tags: financeStringListFromJson(
        jsonDecode(row['tagsJson'] as String? ?? '[]'),
      ),
    );
  }
}

class AppDataStore implements LifeSummaryStore {
  const AppDataStore();

  static const _databaseName = 'pingsheng_life.db';
  static const _databaseVersion = 5;
  // 多个模块会连续触发保存，用队列串行化，避免 SQLite 写入互相覆盖。
  static Future<void> _pendingSave = Future<void>.value();

  @override
  Future<LifeSummarySnapshot?> load() async {
    if (!_isSupportedPlatform) {
      return null;
    }
    try {
      // 先等上一次保存完成，再读取，保证恢复到的是最新快照。
      await _pendingSave;
      final db = await _open();
      final meta = await db.query(
        'app_meta',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['initialized'],
        limit: 1,
      );
      if (meta.isEmpty || meta.first['value'] != '1') {
        return null;
      }

      final foodCalories = await _readIntMeta(db, 'foodCalories');
      final todos = await db.query('todos', orderBy: 'position ASC, id ASC');
      final financeRecords = await db.query(
        'finance_records',
        orderBy: 'position ASC, id ASC',
      );
      final workoutRows = await db.query('workout_groups');
      final workoutPlanRows = await db.query(
        'workout_plans',
        orderBy: 'position ASC, id ASC',
      );
      final activeSessionRows = await db.query(
        'active_workout_session',
        limit: 1,
      );
      final workoutHistoryRows = await db.query(
        'workout_history',
        orderBy: 'position ASC, id ASC',
      );
      final workoutGroups = <String, int>{};
      for (final row in workoutRows) {
        final action = row['actionName'] as String? ?? '';
        final groups = row['groups'];
        if (action.isNotEmpty && groups is num) {
          workoutGroups[action] = groups.toInt();
        }
      }

      return LifeSummarySnapshot(
        foodCalories: foodCalories,
        workoutGroupsByAction: workoutGroups,
        todos: todos.map(_todoFromRow).toList(),
        financeRecords: financeRecords.map(_financeRecordFromRow).toList(),
        workoutPlans: workoutPlanRows.map(_workoutPlanFromRow).toList(),
        activeWorkoutSession: activeSessionRows.isEmpty
            ? null
            : _activeWorkoutSessionFromRow(activeSessionRows.first),
        workoutHistory: workoutHistoryRows.map(_workoutHistoryFromRow).toList(),
        aiFinanceEndpoint: await _readStringMeta(
          db,
          'aiFinanceEndpoint',
          defaultGlmChatEndpoint,
        ),
        aiFinanceModel: await _readStringMeta(
          db,
          'aiFinanceModel',
          defaultGlmTextModel,
        ),
        aiFinanceApiKey: await _readStringMeta(db, 'aiFinanceApiKey', ''),
        aiFinanceParseStrategy: await _readAiFinanceParseStrategy(db),
        aiFinanceCustomPrompt:
            await _readStringMeta(db, 'aiFinanceCustomPrompt', ''),
      );
    } catch (error, stackTrace) {
      debugPrint('App data restore failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> save({
    required int foodCalories,
    required Map<String, int> workoutGroupsByAction,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
    required List<WorkoutPlan> workoutPlans,
    required ActiveWorkoutSession? activeWorkoutSession,
    required List<WorkoutHistoryEntry> workoutHistory,
    required String aiFinanceEndpoint,
    required String aiFinanceModel,
    required String aiFinanceApiKey,
    required AiFinanceParseStrategy aiFinanceParseStrategy,
    required String aiFinanceCustomPrompt,
  }) async {
    if (!_isSupportedPlatform) {
      return;
    }
    final previousSave = _pendingSave.catchError((Object _) {});
    // 保存请求排队执行；即便上一轮失败，也不能阻断后续保存。
    _pendingSave = previousSave.then(
      (_) => _saveNow(
        foodCalories: foodCalories,
        workoutGroupsByAction: workoutGroupsByAction,
        todos: todos,
        financeRecords: financeRecords,
        workoutPlans: workoutPlans,
        activeWorkoutSession: activeWorkoutSession,
        workoutHistory: workoutHistory,
        aiFinanceEndpoint: aiFinanceEndpoint,
        aiFinanceModel: aiFinanceModel,
        aiFinanceApiKey: aiFinanceApiKey,
        aiFinanceParseStrategy: aiFinanceParseStrategy,
        aiFinanceCustomPrompt: aiFinanceCustomPrompt,
      ),
    );
    await _pendingSave;
  }

  Future<void> _saveNow({
    required int foodCalories,
    required Map<String, int> workoutGroupsByAction,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
    required List<WorkoutPlan> workoutPlans,
    required ActiveWorkoutSession? activeWorkoutSession,
    required List<WorkoutHistoryEntry> workoutHistory,
    required String aiFinanceEndpoint,
    required String aiFinanceModel,
    required String aiFinanceApiKey,
    required AiFinanceParseStrategy aiFinanceParseStrategy,
    required String aiFinanceCustomPrompt,
  }) async {
    try {
      final db = await _open();
      await db.transaction((txn) async {
        // 元信息保存低频配置和初始化标记，列表数据保存在各自表中。
        await _saveMeta(txn, {
          'initialized': '1',
          'foodCalories': foodCalories.toString(),
          'aiFinanceEndpoint': aiFinanceEndpoint,
          'aiFinanceModel': aiFinanceModel,
          'aiFinanceApiKey': aiFinanceApiKey,
          'aiFinanceParseStrategy': jsonEncode(
            aiFinanceParseStrategy.toJson(),
          ),
          'aiFinanceCustomPrompt': aiFinanceCustomPrompt,
        });

        final todoIds = <String>[];
        for (var index = 0; index < todos.length; index++) {
          final todo = todos[index];
          todoIds.add(todo.id);
          final row = {
            'position': index,
            'todoId': todo.id,
            'title': todo.title,
            'category': todo.category,
            'done': todo.done ? 1 : 0,
            'priority': todo.priority.name,
            'status': todo.status.name,
            'dueDate': dateToJson(todo.dueDate),
            'note': todo.note,
            'repeatRule': todo.repeatRule.name,
            'linkedModulesJson': jsonEncode(
              todo.linkedModules.map((module) => module.name).toList(),
            ),
            'postponedCount': todo.postponedCount,
            'createdAt': todo.createdAt.toIso8601String(),
            'completedAt': todo.completedAt?.toIso8601String(),
          };
          await _upsertByTextKey(txn, 'todos', 'todoId', todo.id, row);
        }
        // 用当前内存 id 集合作为准，删除数据库里已经不存在的旧待办。
        await _deleteMissingTextKeys(txn, 'todos', 'todoId', todoIds);

        for (var index = 0; index < financeRecords.length; index++) {
          final record = financeRecords[index];
          await _upsertByPosition(
            txn,
            'finance_records',
            index,
            AppDataStoreRows.financeRecordToRow(record, index),
          );
        }
        await txn.delete(
          'finance_records',
          where: 'position >= ?',
          whereArgs: [financeRecords.length],
        );

        final workoutActionNames = <String>[];
        for (final entry in workoutGroupsByAction.entries) {
          workoutActionNames.add(entry.key);
          await txn.insert(
              'workout_groups',
              {
                'actionName': entry.key,
                'groups': entry.value,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await _deleteMissingTextKeys(
          txn,
          'workout_groups',
          'actionName',
          workoutActionNames,
        );

        final workoutPlanIds = <String>[];
        for (var index = 0; index < workoutPlans.length; index++) {
          final plan = workoutPlans[index];
          workoutPlanIds.add(plan.id);
          await txn.insert(
              'workout_plans',
              {
                'position': index,
                'planId': plan.id,
                'name': plan.name,
                'target': plan.target,
                'bodyPartsJson': jsonEncode(plan.bodyParts),
                'actionNamesJson': jsonEncode(plan.actionNames),
                'estimatedMinutes': plan.estimatedMinutes,
                'createdAt': plan.createdAt.toIso8601String(),
                'updatedAt': plan.updatedAt.toIso8601String(),
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await _deleteMissingTextKeys(
          txn,
          'workout_plans',
          'planId',
          workoutPlanIds,
        );

        final session = activeWorkoutSession;
        if (session != null) {
          await txn.insert(
              'active_workout_session',
              {
                'id': 1,
                'sessionId': session.id,
                'planId': session.planId,
                'planName': session.planName,
                'startedAt': session.startedAt.toIso8601String(),
                'actionProgressJson': jsonEncode(session.actionProgress),
                'feedback': session.feedback,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          await txn.delete('active_workout_session');
        }

        final workoutHistoryIds = <String>[];
        for (var index = 0; index < workoutHistory.length; index++) {
          final entry = workoutHistory[index];
          workoutHistoryIds.add(entry.id);
          await txn.insert(
              'workout_history',
              {
                'position': index,
                'entryId': entry.id,
                'planId': entry.planId,
                'planName': entry.planName,
                'startedAt': entry.startedAt.toIso8601String(),
                'finishedAt': entry.finishedAt.toIso8601String(),
                'durationMinutes': entry.durationMinutes,
                'totalGroups': entry.totalGroups,
                'estimatedCalories': entry.estimatedCalories,
                'actionResultsJson': jsonEncode(
                  entry.actionResults.map((item) => item.toJson()).toList(),
                ),
                'feedback': entry.feedback,
              },
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await _deleteMissingTextKeys(
          txn,
          'workout_history',
          'entryId',
          workoutHistoryIds,
        );
      });
    } catch (error, stackTrace) {
      // 非 Android 测试环境可能没有 sqflite 插件；主流程继续使用内存状态。
      debugPrint('App data save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _saveMeta(
    Transaction txn,
    Map<String, String> values,
  ) async {
    for (final entry in values.entries) {
      await txn.insert(
        'app_meta',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _upsertByTextKey(
    Transaction txn,
    String table,
    String keyColumn,
    String key,
    Map<String, Object?> row,
  ) async {
    final updated = await txn.update(
      table,
      row,
      where: '$keyColumn = ?',
      whereArgs: [key],
    );
    if (updated == 0) {
      await txn.insert(table, row);
    }
  }

  Future<void> _upsertByPosition(
    Transaction txn,
    String table,
    int position,
    Map<String, Object?> row,
  ) async {
    final updated = await txn.update(
      table,
      row,
      where: 'position = ?',
      whereArgs: [position],
    );
    if (updated == 0) {
      await txn.insert(table, row);
    }
  }

  Future<void> _deleteMissingTextKeys(
    Transaction txn,
    String table,
    String keyColumn,
    List<String> keys,
  ) async {
    if (keys.isEmpty) {
      // 空列表代表当前模块没有任何数据，整表清空才和内存状态一致。
      await txn.delete(table);
      return;
    }
    final placeholders = List.filled(keys.length, '?').join(',');
    await txn.delete(
      table,
      where: '$keyColumn NOT IN ($placeholders)',
      whereArgs: keys,
    );
  }

  Future<Database> _open() async {
    final path = '${await getDatabasesPath()}/$_databaseName';
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            position INTEGER NOT NULL,
            todoId TEXT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            done INTEGER NOT NULL,
            priority TEXT,
            status TEXT,
            dueDate TEXT,
            note TEXT,
            repeatRule TEXT,
            linkedModulesJson TEXT,
            postponedCount INTEGER,
            createdAt TEXT,
            completedAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE finance_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            position INTEGER NOT NULL,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            date TEXT,
            account TEXT,
            tagsJson TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_groups (
            actionName TEXT PRIMARY KEY,
            groups INTEGER NOT NULL
          )
        ''');
        await _createWorkoutTrainingTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 版本升级只追加字段/表，保留用户已有的本地数据。
        if (oldVersion < 2) {
          await _addColumnIfMissing(db, 'todos', 'todoId TEXT');
          await _addColumnIfMissing(db, 'todos', 'priority TEXT');
          await _addColumnIfMissing(db, 'todos', 'status TEXT');
          await _addColumnIfMissing(db, 'todos', 'dueDate TEXT');
          await _addColumnIfMissing(db, 'todos', 'note TEXT');
          await _addColumnIfMissing(db, 'todos', 'repeatRule TEXT');
          await _addColumnIfMissing(db, 'todos', 'linkedModulesJson TEXT');
          await _addColumnIfMissing(db, 'todos', 'postponedCount INTEGER');
          await _addColumnIfMissing(db, 'todos', 'createdAt TEXT');
          await _addColumnIfMissing(db, 'todos', 'completedAt TEXT');
        }
        if (oldVersion < 3) {
          await _addColumnIfMissing(db, 'finance_records', 'date TEXT');
        }
        if (oldVersion < 4) {
          await _createWorkoutTrainingTables(db);
        }
        if (oldVersion < 5) {
          await _addColumnIfMissing(db, 'finance_records', 'account TEXT');
          await _addColumnIfMissing(db, 'finance_records', 'tagsJson TEXT');
        }
      },
    );
  }

  Future<void> _createWorkoutTrainingTables(DatabaseExecutor db) async {
    // 训练计划、进行中训练、历史记录独立建表，便于页面按模块恢复。
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        position INTEGER NOT NULL,
        planId TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        target TEXT NOT NULL,
        bodyPartsJson TEXT NOT NULL,
        actionNamesJson TEXT NOT NULL,
        estimatedMinutes INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS active_workout_session (
        id INTEGER PRIMARY KEY,
        sessionId TEXT NOT NULL,
        planId TEXT NOT NULL,
        planName TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        actionProgressJson TEXT NOT NULL,
        feedback TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        position INTEGER NOT NULL,
        entryId TEXT NOT NULL UNIQUE,
        planId TEXT NOT NULL,
        planName TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        finishedAt TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        totalGroups INTEGER NOT NULL,
        estimatedCalories INTEGER NOT NULL,
        actionResultsJson TEXT NOT NULL,
        feedback TEXT NOT NULL
      )
    ''');
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String columnDefinition,
  ) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDefinition');
    } catch (_) {
      // 旧库可能已经被部分升级过；重复列直接跳过。
    }
  }

  bool get _isSupportedPlatform =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  Future<int> _readIntMeta(Database db, String key) async {
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return 0;
    }
    return int.tryParse(rows.first['value'] as String? ?? '') ?? 0;
  }

  Future<String> _readStringMeta(
    Database db,
    String key,
    String fallback,
  ) async {
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return fallback;
    }
    return rows.first['value'] as String? ?? fallback;
  }

  Future<AiFinanceParseStrategy> _readAiFinanceParseStrategy(
    Database db,
  ) async {
    final raw = await _readStringMeta(db, 'aiFinanceParseStrategy', '');
    if (raw.trim().isEmpty) {
      return AiFinanceParseStrategy.defaults;
    }
    try {
      return AiFinanceParseStrategy.fromJson(jsonDecode(raw));
    } on FormatException {
      // 旧版本或手动损坏的配置不让页面崩溃，回到默认解析策略。
      return AiFinanceParseStrategy.defaults;
    }
  }

  TodoItem _todoFromRow(Map<String, Object?> row) {
    // 数据库里只存可序列化字段，颜色和枚举在恢复模型时重新推导。
    final category = row['category'] as String? ?? '生活';
    final linkedModules = linkedModulesFromJson(
      _decodeJsonList(row['linkedModulesJson']),
    );
    return TodoItem(
      id: row['todoId'] as String?,
      title: row['title'] as String? ?? '未命名待办',
      category: category,
      color: todoColorForCategory(category),
      priority: enumByName(
        TodoPriority.values,
        row['priority'] as String?,
        fallback: TodoPriority.shouldDo,
      ),
      status: enumByName(
        TodoStatus.values,
        row['status'] as String?,
        fallback:
            row['done'] == 1 ? TodoStatus.completed : TodoStatus.notStarted,
      ),
      dueDate: dateFromJson(row['dueDate'] as String?),
      note: row['note'] as String? ?? '',
      repeatRule: enumByName(
        TodoRepeatRule.values,
        row['repeatRule'] as String?,
        fallback: TodoRepeatRule.none,
      ),
      linkedModules: linkedModules,
      postponedCount: (row['postponedCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(row['createdAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(row['completedAt'] as String? ?? ''),
    );
  }

  FinanceRecord _financeRecordFromRow(Map<String, Object?> row) {
    return AppDataStoreRows.financeRecordFromRow(row);
  }

  WorkoutPlan _workoutPlanFromRow(Map<String, Object?> row) {
    return WorkoutPlan.fromJson({
      'id': row['planId'],
      'name': row['name'],
      'target': row['target'],
      'bodyParts': _decodeJsonList(row['bodyPartsJson']),
      'actionNames': _decodeJsonList(row['actionNamesJson']),
      'estimatedMinutes': row['estimatedMinutes'],
      'createdAt': row['createdAt'],
      'updatedAt': row['updatedAt'],
    });
  }

  ActiveWorkoutSession _activeWorkoutSessionFromRow(
    Map<String, Object?> row,
  ) {
    return ActiveWorkoutSession.fromJson({
      'id': row['sessionId'],
      'planId': row['planId'],
      'planName': row['planName'],
      'startedAt': row['startedAt'],
      'actionProgress': _decodeJsonMap(row['actionProgressJson']),
      'feedback': row['feedback'],
    });
  }

  WorkoutHistoryEntry _workoutHistoryFromRow(Map<String, Object?> row) {
    return WorkoutHistoryEntry.fromJson({
      'id': row['entryId'],
      'planId': row['planId'],
      'planName': row['planName'],
      'startedAt': row['startedAt'],
      'finishedAt': row['finishedAt'],
      'durationMinutes': row['durationMinutes'],
      'totalGroups': row['totalGroups'],
      'estimatedCalories': row['estimatedCalories'],
      'actionResults': _decodeJsonList(row['actionResultsJson']),
      'feedback': row['feedback'],
    });
  }

  List<Object?> _decodeJsonList(Object? source) {
    final decoded = _decodeJson(source);
    if (decoded is List) {
      return List<Object?>.from(decoded);
    }
    return [];
  }

  Map<String, Object?> _decodeJsonMap(Object? source) {
    final decoded = _decodeJson(source);
    if (decoded is Map) {
      final result = <String, Object?>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        if (key is String) {
          result[key] = entry.value;
        }
      }
      return result;
    }
    return {};
  }

  Object? _decodeJson(Object? source) {
    if (source is String) {
      if (source.trim().isEmpty) {
        return null;
      }
      try {
        return jsonDecode(source);
      } on FormatException {
        return null;
      } catch (_) {
        return null;
      }
    }
    return source;
  }
}
