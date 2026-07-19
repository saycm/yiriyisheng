// 中文注释：App 数据表 helper，负责 SQLite 建表、升级、meta 和通用 upsert。

part of 'storage.dart';

extension _AppDataStoreTables on AppDataStore {
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
    final path = '${await getDatabasesPath()}/'
        '${AppDataStore._databaseName}';
    return openDatabase(
      path,
      version: AppDataStore._databaseVersion,
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
            repeatAnchorDay INTEGER,
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
            toAccount TEXT,
            tagsJson TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_groups (
            actionName TEXT PRIMARY KEY,
            groups INTEGER NOT NULL
          )
        ''');
        await _createFoodLogTable(db);
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
        if (oldVersion < 6) {
          await _createFoodLogTable(db);
        }
        if (oldVersion < 7) {
          await _addColumnIfMissing(db, 'finance_records', 'toAccount TEXT');
        }
        if (oldVersion < 8) {
          await _addColumnIfMissing(db, 'todos', 'repeatAnchorDay INTEGER');
        }
      },
    );
  }

  Future<void> _createFoodLogTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        position INTEGER NOT NULL,
        foodJson TEXT NOT NULL,
        meal TEXT NOT NULL,
        servings REAL NOT NULL,
        note TEXT NOT NULL,
        recordedAt TEXT NOT NULL
      )
    ''');
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
    final columnName = columnDefinition.trim().split(RegExp(r'\s+')).first;
    final quotedTable = '"${table.replaceAll('"', '""')}"';
    final columns = await db.rawQuery('PRAGMA table_info($quotedTable)');
    if (columns.any((column) => column['name'] == columnName)) {
      return;
    }
    await db.execute('ALTER TABLE $quotedTable ADD COLUMN $columnDefinition');
  }

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

  Future<DateTime?> _readDateMeta(Database db, String key) async {
    final rows = await db.query(
      'app_meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return dateFromJson(rows.first['value'] as String?);
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
}
