// 中文注释：计划模块源码，负责待办状态、日期选择和计划页交互。

part of 'plan.dart';

/// 计划页共享状态：选中日期、页签、分类筛选和排序辅助方法。
mixin _PlanModuleState on State<PlanModulePage> {
  // 当前选中的日期，默认是今天（去掉时分秒）。
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  // 当前顶部页签：0=今日、1=待办箱、2=周计划、3=统计。
  int _selectedTab = 0;
  // 今日视图的分类筛选条件，“全部”表示不过滤。
  String _categoryFilter = '全部';
  // 已处理过的桌面小组件快捷动作序号，避免同一个动作被重复触发。
  int _handledQuickActionToken = 0;

  // 今天的日期（只保留年月日），用于判断待办是否到期。
  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  // 已完成待办列表，按优先级和到期日排序，供“更多”面板统计展示。
  List<TodoItem> get _completedTodos =>
      widget.todos.where((todo) => todo.done).toList()..sort(_sortTodos);

  // 待办排序规则：先按优先级（紧急→应该→可以），再按到期日，无日期排最后。
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
