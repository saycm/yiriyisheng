part of '../../main.dart';

mixin _PlanModuleActions on _PlanModuleState {

  void _toggleTodo(TodoItem todo) {
    widget.onToggleTodo(todo);
  }

  void _addInboxTodo(String title) {
    widget.onAddTodo(
      TodoItem(
        title: title,
        category: '生活',
        color: _todoColorForCategory('生活'),
        priority: TodoPriority.shouldDo,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已放入待办箱'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openMoreSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _PlanMoreSheet(
          activeFilter: _categoryFilter,
          completedCount: _completedTodos.length,
          onSelectFilter: (category) {
            Navigator.of(sheetContext).pop();
            setState(() {
              _categoryFilter = category;
              _selectedTab = 0;
            });
          },
          onClearCompleted: () {
            final count = _completedTodos.length;
            Navigator.of(sheetContext).pop();
            if (count == 0) {
              return;
            }
            widget.onClearCompletedTodos();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已清理 $count 项完成记录'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTodoSheet() {
    _showPlanTodoEditorSheet(
      context: context,
      today: _today,
      onSave: widget.onAddTodo,
    );
  }
}
