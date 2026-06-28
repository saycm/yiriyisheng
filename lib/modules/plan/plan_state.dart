part of '../../main.dart';

mixin _PlanModuleState on State<PlanModulePage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  int _selectedTab = 0;
  String _categoryFilter = '全部';
  int _handledQuickActionToken = 0;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  List<TodoItem> get _completedTodos =>
      widget.todos.where((todo) => todo.done).toList()..sort(_sortTodos);

  int _sortTodos(TodoItem a, TodoItem b) {
    final priority = a.priority.index.compareTo(b.priority.index);
    if (priority != 0) {
      return priority;
    }
    final aDate = a.dueDate ?? DateTime(9999);
    final bDate = b.dueDate ?? DateTime(9999);
    return aDate.compareTo(bDate);
  }
}
