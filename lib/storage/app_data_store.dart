part of '../main.dart';

class _AppDataStore {
  const _AppDataStore();

  static const _databaseName = 'pingsheng_life.db';
  static const _databaseVersion = 3;
  static Future<void> _pendingSave = Future<void>.value();

  Future<LifeSummarySnapshot?> load() async {
    if (!_isSupportedPlatform) {
      return null;
    }
    try {
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
        aiFinanceEndpoint: await _readStringMeta(
          db,
          'aiFinanceEndpoint',
          _defaultGlmChatEndpoint,
        ),
        aiFinanceModel: await _readStringMeta(
          db,
          'aiFinanceModel',
          _defaultGlmTextModel,
        ),
        aiFinanceApiKey: await _readStringMeta(db, 'aiFinanceApiKey', ''),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required int foodCalories,
    required Map<String, int> workoutGroupsByAction,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
    required String aiFinanceEndpoint,
    required String aiFinanceModel,
    required String aiFinanceApiKey,
  }) async {
    if (!_isSupportedPlatform) {
      return;
    }
    _pendingSave = _pendingSave.then(
      (_) => _saveNow(
        foodCalories: foodCalories,
        workoutGroupsByAction: workoutGroupsByAction,
        todos: todos,
        financeRecords: financeRecords,
        aiFinanceEndpoint: aiFinanceEndpoint,
        aiFinanceModel: aiFinanceModel,
        aiFinanceApiKey: aiFinanceApiKey,
      ),
    );
    await _pendingSave;
  }

  Future<void> _saveNow({
    required int foodCalories,
    required Map<String, int> workoutGroupsByAction,
    required List<TodoItem> todos,
    required List<FinanceRecord> financeRecords,
    required String aiFinanceEndpoint,
    required String aiFinanceModel,
    required String aiFinanceApiKey,
  }) async {
    try {
      final db = await _open();
      await db.transaction((txn) async {
        await txn.delete('app_meta');
        await txn.delete('todos');
        await txn.delete('finance_records');
        await txn.delete('workout_groups');

        await txn.insert('app_meta', {'key': 'initialized', 'value': '1'});
        await txn.insert('app_meta', {
          'key': 'foodCalories',
          'value': foodCalories.toString(),
        });
        await txn.insert('app_meta', {
          'key': 'aiFinanceEndpoint',
          'value': aiFinanceEndpoint,
        });
        await txn.insert('app_meta', {
          'key': 'aiFinanceModel',
          'value': aiFinanceModel,
        });
        await txn.insert('app_meta', {
          'key': 'aiFinanceApiKey',
          'value': aiFinanceApiKey,
        });

        for (var index = 0; index < todos.length; index++) {
          final todo = todos[index];
          await txn.insert('todos', {
            'position': index,
            'todoId': todo.id,
            'title': todo.title,
            'category': todo.category,
            'done': todo.done ? 1 : 0,
            'priority': todo.priority.name,
            'status': todo.status.name,
            'dueDate': _dateToJson(todo.dueDate),
            'note': todo.note,
            'repeatRule': todo.repeatRule.name,
            'linkedModulesJson': jsonEncode(
              todo.linkedModules.map((module) => module.name).toList(),
            ),
            'postponedCount': todo.postponedCount,
            'createdAt': todo.createdAt.toIso8601String(),
            'completedAt': todo.completedAt?.toIso8601String(),
          });
        }

        for (var index = 0; index < financeRecords.length; index++) {
          final record = financeRecords[index];
          await txn.insert('finance_records', {
            'position': index,
            'title': record.title,
            'subtitle': record.subtitle,
            'amount': record.amount,
            'type': record.type,
            'date': record.date?.toIso8601String(),
          });
        }

        for (final entry in workoutGroupsByAction.entries) {
          await txn.insert('workout_groups', {
            'actionName': entry.key,
            'groups': entry.value,
          });
        }
      });
    } catch (_) {
      // 非 Android 测试环境可能没有 sqflite 插件；主流程继续使用内存状态。
    }
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
            date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_groups (
            actionName TEXT PRIMARY KEY,
            groups INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
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
      },
    );
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

  TodoItem _todoFromRow(Map<String, Object?> row) {
    final category = row['category'] as String? ?? '生活';
    final rawLinkedModules = row['linkedModulesJson'] as String?;
    final linkedModules = rawLinkedModules == null
        ? const <TodoLinkedModule>[]
        : _linkedModulesFromJson(jsonDecode(rawLinkedModules));
    return TodoItem(
      id: row['todoId'] as String?,
      title: row['title'] as String? ?? '未命名待办',
      category: category,
      color: _todoColorForCategory(category),
      priority: _enumByName(
        TodoPriority.values,
        row['priority'] as String?,
        fallback: TodoPriority.shouldDo,
      ),
      status: _enumByName(
        TodoStatus.values,
        row['status'] as String?,
        fallback:
            row['done'] == 1 ? TodoStatus.completed : TodoStatus.notStarted,
      ),
      dueDate: _dateFromJson(row['dueDate'] as String?),
      note: row['note'] as String? ?? '',
      repeatRule: _enumByName(
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
    final title = row['title'] as String? ?? '手动记录';
    return FinanceRecord(
      icon: _financeIconForTitle(title),
      title: title,
      subtitle: row['subtitle'] as String? ?? '手动记录',
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      type: row['type'] as String? ?? '支出',
      date: DateTime.tryParse(row['date'] as String? ?? ''),
    );
  }
}
