// 中文注释：App 数据行映射，负责 SQLite row 与业务模型之间的转换。

part of 'storage.dart';

class AppDataStoreRows {
  const AppDataStoreRows._();

  static Map<String, Object?> foodLogToRow(FoodLogEntry entry, int position) {
    return {
      'position': position,
      'foodJson': jsonEncode(entry.food.toJson()),
      'meal': entry.meal,
      'servings': entry.servings,
      'note': entry.note,
      'recordedAt': entry.recordedAt.toIso8601String(),
    };
  }

  static FoodLogEntry foodLogFromRow(Map<String, Object?> row) {
    return FoodLogEntry.fromJson({
      'food': jsonDecode(row['foodJson'] as String? ?? '{}'),
      'meal': row['meal'],
      'servings': row['servings'],
      'note': row['note'],
      'recordedAt': row['recordedAt'],
    });
  }

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

extension _AppDataStoreRowMapping on AppDataStore {
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

  FoodLogEntry _foodLogFromRow(Map<String, Object?> row) {
    return AppDataStoreRows.foodLogFromRow(row);
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
