part of '../../main.dart';

class PlanModulePage extends StatefulWidget {
  const PlanModulePage({
    super.key,
    required this.moduleNav,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.onOpenQuickRecord,
    required this.foodCalories,
    required this.workoutGroups,
    required this.todayExpense,
    required this.healthStatusText,
    required this.todos,
    required this.events,
    required this.onToggleTodo,
    required this.onUpdateTodo,
    required this.onPostponeTodo,
    required this.onArchiveTodo,
    required this.onDeleteTodo,
    required this.onAddTodo,
    required this.onClearCompletedTodos,
    required this.quickAction,
    required this.quickActionToken,
    required this.onQuickActionHandled,
  });

  final Widget moduleNav;
  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final VoidCallback onOpenQuickRecord;
  final int foodCalories;
  final int workoutGroups;
  final double todayExpense;
  final String healthStatusText;
  final List<TodoItem> todos;
  final List<LifeEvent> events;
  final ValueChanged<TodoItem> onToggleTodo;
  final ValueChanged<TodoItem> onUpdateTodo;
  final ValueChanged<TodoItem> onPostponeTodo;
  final ValueChanged<TodoItem> onArchiveTodo;
  final ValueChanged<TodoItem> onDeleteTodo;
  final ValueChanged<TodoItem> onAddTodo;
  final VoidCallback onClearCompletedTodos;
  final WidgetQuickAction? quickAction;
  final int quickActionToken;
  final VoidCallback onQuickActionHandled;

  @override
  State<PlanModulePage> createState() => _PlanModulePageState();
}

class _PlanModulePageState extends State<PlanModulePage>
    with _PlanModuleState, _PlanModuleActions {
  @override
  void initState() {
    super.initState();
    _maybeHandleQuickAction();
  }

  @override
  void didUpdateWidget(covariant PlanModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeHandleQuickAction();
  }

  void _maybeHandleQuickAction() {
    if (widget.quickAction != WidgetQuickAction.addTodo ||
        widget.quickActionToken == _handledQuickActionToken) {
      return;
    }
    _handledQuickActionToken = widget.quickActionToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // 来自桌面小组件的“加待办”会直接拉起待办详情表单。
      _showAddTodoSheet();
      widget.onQuickActionHandled();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _PlanHeader(
                  onOpenModules: widget.onOpenModules,
                  onOpenMore: _openMoreSheet,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: widget.moduleNav,
                ),
                _PlanDateToolbar(
                  selectedDate: _selectedDate,
                  onDateChanged: (date) => setState(() {
                    _selectedDate = date;
                    _selectedTab = 2;
                  }),
                ),
                Expanded(
                  child: _PlanBody(
                    selectedTab: _selectedTab,
                    selectedDate: _selectedDate,
                    activeFilter: _categoryFilter,
                    todos: widget.todos,
                    events: widget.events,
                    foodCalories: widget.foodCalories,
                    workoutGroups: widget.workoutGroups,
                    todayExpense: widget.todayExpense,
                    healthStatusText: widget.healthStatusText,
                    onSelectDate: (date) => setState(() {
                      _selectedDate = date;
                      _selectedTab = 2;
                    }),
                    onToggleTodo: _toggleTodo,
                    onPostponeTodo: widget.onPostponeTodo,
                    onArchiveTodo: widget.onArchiveTodo,
                    onDeleteTodo: widget.onDeleteTodo,
                    onQuickCapture: _addInboxTodo,
                    onAddTodo: widget.onAddTodo,
                    onClearCompletedTodos: widget.onClearCompletedTodos,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: _moduleSwitchBarBottomGap),
                child: _PlanBottomNav(
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: _moduleSwitchBarReservedHeight + 12,
        ),
        child: FloatingActionButton.small(
          key: const ValueKey('plan_add_todo_fab'),
          onPressed: _showAddTodoSheet,
          tooltip: 'Add',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          child: const Icon(Icons.add, size: 24),
        ),
      ),
    );
  }
}
