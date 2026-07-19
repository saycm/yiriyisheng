// 中文注释：本地存储层，负责 SQLite 持久化和桌面小组件数据同步。

part of 'storage.dart';

abstract class LifeSummaryStore {
  // 首页只依赖这个抽象读写完整快照，测试时可以替换成内存实现。
  Future<LifeSummarySnapshot?> load();

  Future<void> save({
    required int foodCalories,
    required List<FoodLogEntry> foodLogs,
    required Map<String, int> workoutGroupsByAction,
    required DateTime? workoutProgressDate,
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

class AppDataStore implements LifeSummaryStore {
  const AppDataStore();

  static const _databaseName = 'pingsheng_life.db';
  static const _databaseVersion = 8;
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
      final foodLogRows = await db.query(
        'food_logs',
        orderBy: 'position ASC, id ASC',
      );
      final todoRows = AppDataStoreRows.todoRowsWithRepeatAnchors(
        await db.query('todos', orderBy: 'position ASC, id ASC'),
      );
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
        foodLogs: foodLogRows.map(_foodLogFromRow).toList(),
        workoutGroupsByAction: workoutGroups,
        workoutProgressDate: await _readDateMeta(db, 'workoutProgressDate'),
        todos: todoRows.map(_todoFromRow).toList(),
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
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> save({
    required int foodCalories,
    required List<FoodLogEntry> foodLogs,
    required Map<String, int> workoutGroupsByAction,
    required DateTime? workoutProgressDate,
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
        foodLogs: foodLogs,
        workoutGroupsByAction: workoutGroupsByAction,
        workoutProgressDate: workoutProgressDate,
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
    required List<FoodLogEntry> foodLogs,
    required Map<String, int> workoutGroupsByAction,
    required DateTime? workoutProgressDate,
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
          'workoutProgressDate': dateToJson(workoutProgressDate) ?? '',
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
            'repeatAnchorDay': todo.repeatAnchorDay,
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

        for (var index = 0; index < foodLogs.length; index++) {
          await _upsertByPosition(
            txn,
            'food_logs',
            index,
            AppDataStoreRows.foodLogToRow(foodLogs[index], index),
          );
        }
        await txn.delete(
          'food_logs',
          where: 'position >= ?',
          whereArgs: [foodLogs.length],
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

  bool get _isSupportedPlatform =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}
