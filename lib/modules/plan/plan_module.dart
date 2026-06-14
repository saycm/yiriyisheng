part of '../../main.dart';

class PlanModulePage extends StatefulWidget {
  const PlanModulePage({
    super.key,
    required this.onOpenModules,
    required this.onSwitchModule,
    required this.foodCalories,
    required this.workoutGroups,
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

  final VoidCallback onOpenModules;
  final ValueChanged<LifeModule> onSwitchModule;
  final int foodCalories;
  final int workoutGroups;
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

class _PlanModulePageState extends State<PlanModulePage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  int _selectedTab = 0;
  String _categoryFilter = '全部';
  int _handledQuickActionToken = 0;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  List<TodoItem> get _activeTodos =>
      widget.todos.where((todo) => todo.isActive).toList();

  List<TodoItem> get _todayTodos {
    final today = _today;
    return _activeTodos.where((todo) {
      final dueDate = todo.dueDate;
      return dueDate != null && !dueDate.isAfter(today);
    }).toList()
      ..sort(_sortTodos);
  }

  List<TodoItem> get _inboxTodos =>
      _activeTodos.where((todo) => todo.isInbox).toList()..sort(_sortTodos);

  List<TodoItem> get _completedTodos =>
      widget.todos.where((todo) => todo.done).toList()..sort(_sortTodos);

  List<TodoItem> get _archivedTodos =>
      widget.todos.where((todo) => todo.status == TodoStatus.archived).toList()
        ..sort(_sortTodos);

  List<TodoItem> get _filteredTodayTodos {
    if (_categoryFilter == '全部') {
      return _todayTodos;
    }
    return _todayTodos
        .where((todo) => todo.category == _categoryFilter)
        .toList();
  }

  int _sortTodos(TodoItem a, TodoItem b) {
    final priority = a.priority.index.compareTo(b.priority.index);
    if (priority != 0) {
      return priority;
    }
    final aDate = a.dueDate ?? DateTime(9999);
    final bDate = b.dueDate ?? DateTime(9999);
    return aDate.compareTo(bDate);
  }

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
                  selectedDate: _selectedDate,
                  todos: widget.todos,
                  onDateChanged: (date) => setState(() {
                    _selectedDate = date;
                    _selectedTab = 2;
                  }),
                  onOpenModules: widget.onOpenModules,
                  onOpenMore: _openMoreSheet,
                ),
                _ModuleLinkStrip(
                  selected: LifeModule.plan,
                  onSwitchModule: widget.onSwitchModule,
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildTabContent()),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
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
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton(
          onPressed: _showAddTodoSheet,
          tooltip: 'Add',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 9,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 34),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == 1) {
      return _InboxView(
        inboxTodos: _inboxTodos,
        completedTodos: _completedTodos,
        archivedTodos: _archivedTodos,
        onToggle: _toggleTodo,
        onPostpone: widget.onPostponeTodo,
        onArchive: widget.onArchiveTodo,
        onDelete: widget.onDeleteTodo,
      );
    }
    if (_selectedTab == 2) {
      return _WeekPlanView(
        selectedDate: _selectedDate,
        todos: widget.todos,
        onSelectDate: (date) => setState(() => _selectedDate = date),
        onToggle: _toggleTodo,
        onPostpone: widget.onPostponeTodo,
        onArchive: widget.onArchiveTodo,
        onDelete: widget.onDeleteTodo,
      );
    }
    if (_selectedTab == 3) {
      // 计划回顾读取父级共享数据，把饮食和锻炼的记录汇总到同一个复盘入口。
      return _PlanStatsView(
        todos: widget.todos,
        events: widget.events,
        foodCalories: widget.foodCalories,
        workoutGroups: widget.workoutGroups,
      );
    }
    return _TodoList(
      title: '今日计划',
      emptyTitle: '今天没有待处理事项',
      emptySubtitle: '可以把无日期任务从待办箱安排到今天，或新增一个今日任务。',
      todos: _filteredTodayTodos,
      activeFilter: _categoryFilter,
      onToggle: _toggleTodo,
      onPostpone: widget.onPostponeTodo,
      onArchive: widget.onArchiveTodo,
      onDelete: widget.onDeleteTodo,
    );
  }

  void _toggleTodo(TodoItem todo) {
    widget.onToggleTodo(todo);
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
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final customCategoryController = TextEditingController();
    final categories = _todoCategoryOptions();
    var selectedCategory = categories.first;
    var selectedPriority = TodoPriority.shouldDo;
    var selectedStatus = TodoStatus.notStarted;
    DateTime? selectedDate = _today;
    var selectedRepeat = TodoRepeatRule.none;
    final linkedModules = <TodoLinkedModule>{};

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SheetHandle(),
                      const SizedBox(height: 20),
                      const Text(
                        '新增待办',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        autofocus: true,
                        decoration: _planInputDecoration('标题，例如：还信用卡'),
                      ),
                      const SizedBox(height: 16),
                      const _PlanFieldLabel('分类'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: categories.map((category) {
                          final selected = selectedCategory.$1 == category.$1;
                          return ChoiceChip(
                            label: Text(category.$1),
                            selected: selected,
                            selectedColor: category.$2.withValues(alpha: 0.16),
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: selected ? category.$2 : AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide(
                              color:
                                  selected ? category.$2 : Colors.transparent,
                            ),
                            onSelected: (_) {
                              setSheetState(() => selectedCategory = category);
                            },
                          );
                        }).toList(),
                      ),
                      if (selectedCategory.$1 == '自定义') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: customCategoryController,
                          decoration: _planInputDecoration('自定义分类名称'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const _PlanFieldLabel('优先级'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: TodoPriority.values.map((priority) {
                          final selected = selectedPriority == priority;
                          return ChoiceChip(
                            avatar: Icon(
                              priority.icon,
                              size: 17,
                              color:
                                  selected ? priority.color : AppColors.muted,
                            ),
                            label: Text(priority.label),
                            selected: selected,
                            selectedColor:
                                priority.color.withValues(alpha: 0.13),
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color:
                                  selected ? priority.color : AppColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? priority.color
                                  : Colors.transparent,
                            ),
                            onSelected: (_) {
                              setSheetState(() => selectedPriority = priority);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const _PlanFieldLabel('日期'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ChoiceChip(
                            label: const Text('今天'),
                            selected: DateUtils.isSameDay(selectedDate, _today),
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            onSelected: (_) {
                              setSheetState(() => selectedDate = _today);
                            },
                          ),
                          ChoiceChip(
                            label: const Text('明天'),
                            selected: DateUtils.isSameDay(
                              selectedDate,
                              _today.add(const Duration(days: 1)),
                            ),
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            onSelected: (_) {
                              setSheetState(
                                () => selectedDate =
                                    _today.add(const Duration(days: 1)),
                              );
                            },
                          ),
                          ChoiceChip(
                            label: const Text('无日期'),
                            selected: selectedDate == null,
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            onSelected: (_) {
                              setSheetState(() => selectedDate = null);
                            },
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: sheetContext,
                                initialDate: selectedDate ?? _today,
                                firstDate:
                                    _today.subtract(const Duration(days: 365)),
                                lastDate:
                                    _today.add(const Duration(days: 365 * 2)),
                              );
                              if (picked == null) {
                                return;
                              }
                              setSheetState(
                                () => selectedDate = DateUtils.dateOnly(picked),
                              );
                            },
                            icon: const Icon(Icons.calendar_month_rounded),
                            label: Text(
                              selectedDate == null
                                  ? '选择日期'
                                  : _formatPlanDate(selectedDate),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _PlanFieldLabel('状态'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          TodoStatus.notStarted,
                          TodoStatus.inProgress,
                        ].map((status) {
                          final selected = selectedStatus == status;
                          return ChoiceChip(
                            avatar: Icon(
                              status.icon,
                              size: 17,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                            label: Text(status.label),
                            selected: selected,
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            onSelected: (_) {
                              setSheetState(() => selectedStatus = status);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const _PlanFieldLabel('重复'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: TodoRepeatRule.values.map((rule) {
                          final selected = selectedRepeat == rule;
                          return ChoiceChip(
                            label: Text(rule.label),
                            selected: selected,
                            selectedColor: AppColors.primarySoft,
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                            onSelected: (_) {
                              setSheetState(() => selectedRepeat = rule);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const _PlanFieldLabel('任务联动'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: TodoLinkedModule.values.map((module) {
                          final selected = linkedModules.contains(module);
                          return FilterChip(
                            avatar: Icon(
                              module.icon,
                              size: 17,
                              color: selected ? module.color : AppColors.muted,
                            ),
                            label: Text(module.label),
                            selected: selected,
                            selectedColor: module.color.withValues(alpha: 0.13),
                            backgroundColor: AppColors.background,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: selected ? module.color : AppColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                            onSelected: (checked) {
                              setSheetState(() {
                                if (checked) {
                                  linkedModules.add(module);
                                } else {
                                  linkedModules.remove(module);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: noteController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: _planInputDecoration('备注，可写触发条件或补充说明'),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: () {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              return;
                            }
                            final customCategory =
                                customCategoryController.text.trim();
                            final category = selectedCategory.$1 == '自定义' &&
                                    customCategory.isNotEmpty
                                ? customCategory
                                : selectedCategory.$1;
                            widget.onAddTodo(
                              TodoItem(
                                title: title,
                                category: category,
                                color: _todoColorForCategory(category),
                                priority: selectedPriority,
                                status: selectedStatus,
                                dueDate: selectedDate,
                                note: noteController.text.trim(),
                                repeatRule: selectedRepeat,
                                linkedModules: linkedModules.toList(),
                              ),
                            );
                            Navigator.of(sheetContext).pop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '保存',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PlanFieldLabel extends StatelessWidget {
  const _PlanFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

InputDecoration _planInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
}

List<(String, Color)> _todoCategoryOptions() {
  return const [
    ('工作', Color(0xFF9278F7)),
    ('生活', Color(0xFF7D9CFF)),
    ('健康', Color(0xFFFF6F9D)),
    ('财务', AppColors.success),
    ('学习', Color(0xFFB88955)),
    ('自定义', AppColors.muted),
  ];
}

String _formatPlanDate(DateTime? date) {
  if (date == null) {
    return '无日期';
  }
  return '${date.month}/${date.day}';
}

String _weekdayLabel(DateTime date) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[date.weekday - 1];
}

String _pendingLinkedHint(TodoItem todo) {
  if (todo.linkedModules.isEmpty) {
    return '';
  }
  final modules = todo.linkedModules.map((module) => module.label).join('、');
  return '完成后会提醒你补充$modules记录。';
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.selectedDate,
    required this.todos,
    required this.onDateChanged,
    required this.onOpenModules,
    required this.onOpenMore,
  });

  final DateTime selectedDate;
  final List<TodoItem> todos;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    final days = List.generate(
      7,
      (index) => DateUtils.dateOnly(weekStart.add(Duration(days: index))),
    );
    final monthText =
        '${selectedDate.year}年${selectedDate.month.toString().padLeft(2, '0')}月';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        children: [
          Row(
            children: [
              _IconBubble(
                icon: Icons.view_sidebar_rounded,
                color: const Color(0xFF91A3FF),
                onTap: onOpenModules,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthText,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _IconBubble(
                icon: Icons.more_horiz_rounded,
                color: AppColors.primary,
                onTap: onOpenMore,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              final selected = DateUtils.isSameDay(selectedDate, day);
              final count = todos
                  .where((todo) => todo.isActive && todo.isDueOn(day))
                  .length;
              return _DatePill(
                week: _weekdayLabel(day),
                day: day.day,
                selected: selected,
                isToday: DateUtils.isSameDay(today, day),
                count: count,
                onTap: () => onDateChanged(day),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF9AA0AD),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.week,
    required this.day,
    required this.selected,
    required this.isToday,
    required this.count,
    required this.onTap,
  });

  final String week;
  final int day;
  final bool selected;
  final bool isToday;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              week,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$day',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: count > 0 ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : isToday
                        ? AppColors.primary
                        : AppColors.muted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList({
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.todos,
    required this.activeFilter,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final List<TodoItem> todos;
  final String activeFilter;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final filtered = activeFilter != '全部';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
      children: [
        Text(
          filtered
              ? '$title  ${todos.length} · $activeFilter'
              : '$title  ${todos.length}',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (todos.isEmpty)
          _EmptyCard(
            title: filtered ? '这个类别没有待办' : emptyTitle,
            subtitle: filtered ? '切回全部或添加新的$activeFilter事项' : emptySubtitle,
          )
        else
          ...todos.map(
            (todo) => _TodoCard(
              todo: todo,
              onTap: () => onToggle(todo),
              onPostpone: () => onPostpone(todo),
              onArchive: () => onArchive(todo),
              onDelete: () => onDelete(todo),
            ),
          ),
      ],
    );
  }
}

class _PlanMoreSheet extends StatelessWidget {
  const _PlanMoreSheet({
    required this.activeFilter,
    required this.completedCount,
    required this.onSelectFilter,
    required this.onClearCompleted,
  });

  final String activeFilter;
  final int completedCount;
  final ValueChanged<String> onSelectFilter;
  final VoidCallback onClearCompleted;

  @override
  Widget build(BuildContext context) {
    final categories = [
      '全部',
      ..._todoCategoryOptions().map((category) => category.$1),
    ];

    return _InfoSheetFrame(
      title: '待办选项',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '筛选类别',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: categories.map((category) {
              return ChoiceChip(
                key: ValueKey('plan_filter_$category'),
                label: Text(category),
                selected: activeFilter == category,
                selectedColor: AppColors.primarySoft,
                backgroundColor: AppColors.surface,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: activeFilter == category
                      ? AppColors.primary
                      : AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: activeFilter == category
                      ? AppColors.primary
                      : Colors.transparent,
                ),
                onSelected: (_) => onSelectFilter(category),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: completedCount == 0 ? null : onClearCompleted,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.financeRed,
                side: BorderSide(
                  color: completedCount == 0
                      ? AppColors.muted.withValues(alpha: 0.24)
                      : AppColors.financeRed.withValues(alpha: 0.32),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.cleaning_services_rounded, size: 19),
              label: Text(
                '清理已完成 ($completedCount)',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.onTap,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final TodoItem todo;
  final VoidCallback onTap;
  final VoidCallback onPostpone;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8C0D9).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: todo.done ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: todo.done
                            ? AppColors.primary
                            : const Color(0xFFE0E4EF),
                        width: 2,
                      ),
                    ),
                    child: todo.done
                        ? const Icon(Icons.check, size: 15, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            decoration:
                                todo.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (todo.note.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            todo.note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TodoMetaChip(
                    label: todo.category,
                    icon: Icons.sell_rounded,
                    color: todo.color,
                  ),
                  _TodoMetaChip(
                    label: todo.priority.label,
                    icon: todo.priority.icon,
                    color: todo.priority.color,
                  ),
                  _TodoMetaChip(
                    label: todo.status.label,
                    icon: todo.status.icon,
                    color: todo.status == TodoStatus.postponed
                        ? AppColors.financeRed
                        : AppColors.primary,
                  ),
                  _TodoMetaChip(
                    label: todo.dueDate == null
                        ? '无日期'
                        : _formatPlanDate(todo.dueDate),
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.muted,
                  ),
                  if (todo.repeatRule != TodoRepeatRule.none)
                    _TodoMetaChip(
                      label: todo.repeatRule.label,
                      icon: Icons.repeat_rounded,
                      color: AppColors.success,
                    ),
                ],
              ),
              if (todo.linkedModules.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final module in todo.linkedModules)
                      _TodoMetaChip(
                        label: module.label,
                        icon: module.icon,
                        color: module.color,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  todo.done
                      ? _linkedTodoPrompt(todo, todo.linkedModules.first)
                      : _pendingLinkedHint(todo),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _TodoQuickActions(
                done: todo.done,
                onComplete: onTap,
                onPostpone: onPostpone,
                onArchive: onArchive,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoMetaChip extends StatelessWidget {
  const _TodoMetaChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoQuickActions extends StatelessWidget {
  const _TodoQuickActions({
    required this.done,
    required this.onComplete,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final bool done;
  final VoidCallback onComplete;
  final VoidCallback onPostpone;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: done ? '重新打开' : '完成',
          child: IconButton.filledTonal(
            onPressed: onComplete,
            icon: Icon(done ? Icons.undo_rounded : Icons.check_rounded),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primarySoft,
            ),
          ),
        ),
        Tooltip(
          message: '延后到明天',
          child: IconButton(
            onPressed: done ? null : onPostpone,
            icon: const Icon(Icons.event_repeat_rounded),
          ),
        ),
        Tooltip(
          message: '归档',
          child: IconButton(
            onPressed: onArchive,
            icon: const Icon(Icons.archive_rounded),
          ),
        ),
        const Spacer(),
        Tooltip(
          message: '删除',
          child: IconButton(
            onPressed: onDelete,
            color: AppColors.financeRed,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ),
      ],
    );
  }
}

class _InboxView extends StatelessWidget {
  const _InboxView({
    required this.inboxTodos,
    required this.completedTodos,
    required this.archivedTodos,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final List<TodoItem> inboxTodos;
  final List<TodoItem> completedTodos;
  final List<TodoItem> archivedTodos;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
      children: [
        Text(
          '待办箱  ${inboxTodos.length}',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (inboxTodos.isEmpty)
          const _EmptyCard(
            title: '待办箱是空的',
            subtitle: '没有日期的任务会先收集在这里，想清楚后再安排到今天或本周。',
          )
        else
          ...inboxTodos.map(
            (todo) => _TodoCard(
              todo: todo,
              onTap: () => onToggle(todo),
              onPostpone: () => onPostpone(todo),
              onArchive: () => onArchive(todo),
              onDelete: () => onDelete(todo),
            ),
          ),
        const SizedBox(height: 18),
        _PlanArchiveSection(
          title: '已完成',
          todos: completedTodos,
          emptyText: '完成任务后会留在这里，复盘时一起统计。',
        ),
        const SizedBox(height: 14),
        _PlanArchiveSection(
          title: '已归档',
          todos: archivedTodos,
          emptyText: '暂时不处理但不想删除的任务可以归档。',
        ),
      ],
    );
  }
}

class _PlanArchiveSection extends StatelessWidget {
  const _PlanArchiveSection({
    required this.title,
    required this.todos,
    required this.emptyText,
  });

  final String title;
  final List<TodoItem> todos;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title  ${todos.length}',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (todos.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            )
          else
            ...todos.take(5).map((todo) => _DoneCard(todo: todo)),
        ],
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.todo});

  final TodoItem todo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              todo.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            todo.category,
            style: TextStyle(
              color: todo.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekPlanView extends StatelessWidget {
  const _WeekPlanView({
    required this.selectedDate,
    required this.todos,
    required this.onSelectDate,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final DateTime selectedDate;
  final List<TodoItem> todos;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday % 7),
    );
    final days = List.generate(
      7,
      (index) => DateUtils.dateOnly(weekStart.add(Duration(days: index))),
    );
    final selectedTodos = todos
        .where((todo) => todo.isActive && todo.isDueOn(selectedDate))
        .toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
      children: [
        const Text(
          '周计划',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 18) / 4;
            return Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final day in days)
                  SizedBox(
                    width: tileWidth,
                    child: _WeekDayCard(
                      date: day,
                      selected: DateUtils.isSameDay(day, selectedDate),
                      todos: todos
                          .where((todo) => todo.isActive && todo.isDueOn(day))
                          .toList(),
                      onTap: () => onSelectDate(day),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          '${_formatPlanDate(selectedDate)}  ${selectedTodos.length} 项',
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (selectedTodos.isEmpty)
          const _EmptyCard(
            title: '这天还没有安排',
            subtitle: '周计划会把每天的任务密度摊开，避免都挤到今天。',
          )
        else
          ...selectedTodos.map(
            (todo) => _TodoCard(
              todo: todo,
              onTap: () => onToggle(todo),
              onPostpone: () => onPostpone(todo),
              onArchive: () => onArchive(todo),
              onDelete: () => onDelete(todo),
            ),
          ),
      ],
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  const _WeekDayCard({
    required this.date,
    required this.selected,
    required this.todos,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final List<TodoItem> todos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mustDoCount =
        todos.where((todo) => todo.priority == TodoPriority.mustDo).length;
    final postponedCount =
        todos.where((todo) => todo.status == TodoStatus.postponed).length;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _weekdayLabel(date),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${todos.length} 项',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (mustDoCount > 0 || postponedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                [
                  if (mustDoCount > 0) '必做 $mustDoCount',
                  if (postponedCount > 0) '延后 $postponedCount',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.82)
                      : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanStatsView extends StatelessWidget {
  const _PlanStatsView({
    required this.todos,
    required this.events,
    required this.foodCalories,
    required this.workoutGroups,
  });

  final List<TodoItem> todos;
  final List<LifeEvent> events;
  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    final actionable =
        todos.where((todo) => todo.status != TodoStatus.archived).toList();
    final total = actionable.length;
    final done = todos.where((todo) => todo.done).length;
    final percent = total == 0 ? 0 : (done * 100 / total).round();
    final postponed = todos
        .where(
          (todo) =>
              todo.status == TodoStatus.postponed || todo.postponedCount > 0,
        )
        .toList();
    final delayedByCategory = <String, int>{};
    for (final todo in postponed) {
      delayedByCategory[todo.category] =
          (delayedByCategory[todo.category] ?? 0) + 1;
    }
    final topDelayed = delayedByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final linkedInsight = foodCalories == 0 && workoutGroups == 0
        ? '记录饮食和锻炼后，计划会自动把摄入、训练和待办放在一起复盘。'
        : '饮食 $foodCalories kcal，锻炼 $workoutGroups 组，今天的计划可以按真实状态微调。';
    final moments = <(String, String)>[
      ('🍽️', '饮食模块今日已记录 $foodCalories kcal'),
      ('🏋️', '锻炼模块今日已完成 $workoutGroups 组'),
      ('📘', '$total 项任务已完成 $done 项，完成率 $percent%'),
      ('⏳', '${postponed.length} 项任务被延后过'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
      children: [
        _WeeklyProgressCard(
          percent: percent,
          done: done,
          total: total,
        ),
        const SizedBox(height: 16),
        _PlanLinkedReviewCard(
          foodCalories: foodCalories,
          workoutGroups: workoutGroups,
        ),
        const SizedBox(height: 16),
        _PlanReviewMetricsCard(
          completedRate: percent,
          postponedCount: postponed.length,
          delayedCategories: topDelayed.take(3).toList(),
        ),
        const SizedBox(height: 16),
        _LifeEventFeedCard(events: events.take(4).toList()),
        const SizedBox(height: 16),
        const _ReviewSectionTitle(
          icon: Icons.auto_awesome_rounded,
          title: '被看见的瞬间',
        ),
        const SizedBox(height: 10),
        _MomentListCard(moments: moments),
        const SizedBox(height: 18),
        const _ReviewSectionTitle(
          icon: Icons.grid_view_rounded,
          title: '你这周的几个模式',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: _InsightCard(
                title: '拖延信号',
                body: '已延后的任务会继续留在周计划里，复盘时优先看是不是分类过载或日期安排太密。',
                icon: Icons.event_repeat_rounded,
                accent: Color(0xFF7F7AF7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InsightCard(
                title: '状态同步',
                body: linkedInsight,
                icon: Icons.hub_rounded,
                accent: Color(0xFF7D9CFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _ReviewSectionTitle(
          icon: Icons.layers_rounded,
          title: '这段时间的几个数字',
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.58,
          children: [
            const _NumberCard(
              icon: Icons.directions_walk_rounded,
              value: '20,885步',
              label: '总步数',
              color: Color(0xFF7D9CFF),
            ),
            const _NumberCard(
              icon: Icons.payments_rounded,
              value: '499.96元',
              label: '最大单笔',
              color: Color(0xFFE85C59),
            ),
            _NumberCard(
              icon: Icons.local_fire_department_rounded,
              value: '$foodCalories kcal',
              label: '饮食摄入',
              color: Color(0xFFB88955),
            ),
            _NumberCard(
              icon: Icons.fact_check_rounded,
              value: '$done 项',
              label: '完成任务',
              color: AppColors.primary,
            ),
            _NumberCard(
              icon: Icons.event_repeat_rounded,
              value: '${postponed.length} 项',
              label: '延后任务',
              color: AppColors.financeRed,
            ),
            _NumberCard(
              icon: Icons.fitness_center_rounded,
              value: '$workoutGroups 组',
              label: '锻炼完成',
              color: AppColors.success,
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanLinkedReviewCard extends StatelessWidget {
  const _PlanLinkedReviewCard({
    required this.foodCalories,
    required this.workoutGroups,
  });

  final int foodCalories;
  final int workoutGroups;

  @override
  Widget build(BuildContext context) {
    return _ModuleLinkedSummaryCard(
      title: '计划联动',
      subtitle: '把饮食、锻炼和待办合成同一个本周复盘入口。',
      icon: Icons.hub_rounded,
      values: [
        ('饮食', '$foodCalories kcal'),
        ('锻炼', '$workoutGroups 组'),
      ],
    );
  }
}

class _PlanReviewMetricsCard extends StatelessWidget {
  const _PlanReviewMetricsCard({
    required this.completedRate,
    required this.postponedCount,
    required this.delayedCategories,
  });

  final int completedRate;
  final int postponedCount;
  final List<MapEntry<String, int>> delayedCategories;

  @override
  Widget build(BuildContext context) {
    final delayedText = delayedCategories.isEmpty
        ? '暂时没有明显拖延分类'
        : delayedCategories
            .map((entry) => '${entry.key} ${entry.value} 次')
            .join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.query_stats_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                '复盘指标',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PlanMetricPill(
                  label: '完成率',
                  value: '$completedRate%',
                  icon: Icons.fact_check_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlanMetricPill(
                  label: '拖延任务',
                  value: '$postponedCount 项',
                  icon: Icons.event_repeat_rounded,
                  color: AppColors.financeRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '常被延后的分类：$delayedText',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMetricPill extends StatelessWidget {
  const _PlanMetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleLinkedSummaryCard extends StatelessWidget {
  const _ModuleLinkedSummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.values,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<(String label, String value)> values;

  @override
  Widget build(BuildContext context) {
    // 所有模块共用这个摘要卡片，保证跨模块数据的展示口径一致。
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final entry in values)
                  _LinkedValue(label: entry.$1, value: entry.$2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeEventFeedCard extends StatelessWidget {
  const _LifeEventFeedCard({required this.events});

  final List<LifeEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '联动记录',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Text(
              '完成待办、记录饮食或开始训练后，会在这里形成时间线。',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...List.generate(events.length, (index) {
              final event = events[index];
              return _LifeEventRow(
                event: event,
                showDivider: index != events.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _LifeEventRow extends StatelessWidget {
  const _LifeEventRow({
    required this.event,
    required this.showDivider,
  });

  final LifeEvent event;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(event.icon, color: event.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFE9ECF4)),
      ],
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({
    required this.percent,
    required this.done,
    required this.total,
  });

  final int percent;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.primarySoft,
                  color: AppColors.primary,
                ),
                Center(
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '本周回顾',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '已完成 $done 项，还有 ${total - done} 项待处理',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSectionTitle extends StatelessWidget {
  const _ReviewSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MomentListCard extends StatelessWidget {
  const _MomentListCard({required this.moments});

  final List<(String, String)> moments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(moments.length, (index) {
          final moment = moments[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    Text(moment.$1, style: const TextStyle(fontSize: 21)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        moment.$2,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (index != moments.length - 1)
                const Divider(height: 1, color: Color(0xFFE9ECF4)),
            ],
          );
        }),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 172),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              height: 1.45,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(icon, color: accent, size: 36),
          ),
        ],
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
