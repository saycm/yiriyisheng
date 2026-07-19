import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/models/models.dart';

void main() {
  group('重复待办下一期', () {
    test('每天和每周任务保留用户字段并重置执行状态', () {
      final daily = _todo(
        id: 'daily_todo',
        dueDate: DateTime(2026, 7, 10),
        repeatRule: TodoRepeatRule.daily,
      );
      final weekly = _todo(
        id: 'weekly_todo',
        dueDate: DateTime(2026, 7, 10),
        repeatRule: TodoRepeatRule.weekly,
      );

      final nextDaily = daily.createNextOccurrence();
      final nextWeekly = weekly.createNextOccurrence();

      expect(nextDaily, isNotNull);
      expect(nextDaily!.id, isNot(daily.id));
      expect(nextDaily.id, daily.createNextOccurrence()!.id);
      expect(nextDaily.dueDate, DateTime(2026, 7, 11));
      expect(nextDaily.status, TodoStatus.notStarted);
      expect(nextDaily.completedAt, isNull);
      expect(nextDaily.postponedCount, 0);
      expect(nextDaily.title, daily.title);
      expect(nextDaily.category, daily.category);
      expect(nextDaily.color, daily.color);
      expect(nextDaily.priority, daily.priority);
      expect(nextDaily.note, daily.note);
      expect(nextDaily.repeatRule, daily.repeatRule);
      expect(nextDaily.linkedModules, daily.linkedModules);
      expect(nextWeekly!.dueDate, DateTime(2026, 7, 17));
    });

    test('每月任务在短月份夹取到月底', () {
      final todo = _todo(
        id: 'monthly_todo',
        dueDate: DateTime(2024, 1, 31),
        repeatRule: TodoRepeatRule.monthly,
      );

      expect(todo.repeatAnchorDay, 31);
      final february = todo.createNextOccurrence();
      february!.done = true;
      final march = february.createNextOccurrence();

      expect(february.dueDate, DateTime(2024, 2, 29));
      expect(march!.dueDate, DateTime(2024, 3, 31));
    });

    test('每月任务序列化后仍保留原始重复日期', () {
      final todo = _todo(
        id: 'monthly_todo',
        dueDate: DateTime(2025, 1, 30),
        repeatRule: TodoRepeatRule.monthly,
      );
      final february = todo.createNextOccurrence()!;
      final restored = TodoItem.fromJson(february.toJson());
      restored.done = true;

      expect(restored.createNextOccurrence()!.dueDate, DateTime(2025, 3, 30));
    });

    test('只有完全未处理的下一期可以随撤销删除', () {
      final todo = _todo(
        id: 'daily_todo',
        dueDate: DateTime(2026, 7, 10),
        repeatRule: TodoRepeatRule.daily,
      );
      final next = todo.createNextOccurrence()!;

      expect(isUntouchedTodoOccurrence(next, next), isTrue);
      next.done = true;
      expect(isUntouchedTodoOccurrence(next, todo.createNextOccurrence()!),
          isFalse);
    });

    test('不重复、自定义周期和归档任务不创建下一期', () {
      final none = _todo(
        id: 'none_todo',
        dueDate: DateTime(2026, 7, 10),
        repeatRule: TodoRepeatRule.none,
      );
      final custom = _todo(
        id: 'custom_todo',
        dueDate: DateTime(2026, 7, 10),
        repeatRule: TodoRepeatRule.custom,
      );
      final archived = _todo(
        id: 'archived_todo',
        dueDate: DateTime(2026, 7, 10),
        repeatRule: TodoRepeatRule.daily,
        status: TodoStatus.archived,
      );

      expect(none.createNextOccurrence(), isNull);
      expect(custom.createNextOccurrence(), isNull);
      expect(archived.createNextOccurrence(), isNull);
    });
  });
}

TodoItem _todo({
  required String id,
  required DateTime dueDate,
  required TodoRepeatRule repeatRule,
  TodoStatus status = TodoStatus.completed,
}) {
  return TodoItem(
    id: id,
    title: '整理周报',
    category: '工作',
    color: const Color(0xFF123456),
    priority: TodoPriority.mustDo,
    status: status,
    dueDate: dueDate,
    note: '保留备注',
    repeatRule: repeatRule,
    linkedModules: const [TodoLinkedModule.finance],
    postponedCount: 3,
    completedAt: DateTime(2026, 7, 10, 9),
  );
}
