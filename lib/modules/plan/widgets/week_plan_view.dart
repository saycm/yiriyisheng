// 中文注释：计划模块页面组件，负责今日总览、待办箱、周计划和统计视图。

part of '../plan.dart';

const int _maxScheduleToSelectedDay = 6;
OverlayEntry? _weekPlanFeedbackEntry;

class _WeekPlanView extends StatelessWidget {
  const _WeekPlanView({
    required this.selectedDate,
    required this.todos,
    required this.onSelectDate,
    required this.onToggle,
    required this.onUpdate,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final DateTime selectedDate;
  final List<TodoItem> todos;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onUpdate;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final normalizedSelectedDate = DateUtils.dateOnly(selectedDate);
    final weekStart = normalizedSelectedDate.subtract(
      Duration(days: normalizedSelectedDate.weekday % 7),
    );
    final days = List.generate(
      7,
      (index) => DateUtils.dateOnly(weekStart.add(Duration(days: index))),
    );
    final weekTodos = _weekTodos(days);
    final unscheduledTodos = _unscheduledTodos(today, days);
    // 周视图把任务分成“本周已有日期”和“未安排/过期待整理”，后续面板都基于这两组数据。
    final selectedTodos = todos
        .where((todo) => todo.isActive && todo.isDueOn(normalizedSelectedDate))
        .toList()
      ..sort(_sortPlanTodos);
    final overdueCount = todos.where((todo) {
      final dueDate = todo.dueDate;
      return todo.isActive && dueDate != null && dueDate.isBefore(today);
    }).length;

    return ListView(
      key: const ValueKey('week_plan_list'),
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        88,
      ),
      children: [
        _WeekCommandCenter(
          weekTodos: weekTodos.length,
          completedCount: _completedInWeek(days),
          unscheduledCount: unscheduledTodos.length,
          riskCount: overdueCount,
          insight: _weekInsight(
            weekTodos: weekTodos,
            unscheduledTodos: unscheduledTodos,
            days: days,
            today: today,
          ),
          onAutoSchedule: unscheduledTodos.isEmpty
              ? null
              : () => _autoScheduleWeek(context, today, days, unscheduledTodos),
          onBalanceWeek: () => _balanceWeek(context, today, days),
          onMoveLowPriorityNextWeek: () =>
              _moveLowPriorityToNextWeek(context, days),
          onCleanOverdue: overdueCount == 0
              ? null
              : () => _cleanOverdueTodos(context, today, days),
        ),
        const SizedBox(height: 12),
        _WeekDayBoard(
          days: days,
          selectedDate: normalizedSelectedDate,
          todos: todos,
          onSelectDate: onSelectDate,
        ),
        const SizedBox(height: 12),
        _WeekUnscheduledSection(
          todos: unscheduledTodos,
          onScheduleToday: (todo) => _scheduleTodo(context, todo, today),
          onScheduleTomorrow: (todo) => _scheduleTodo(
            context,
            todo,
            today.add(const Duration(days: 1)),
          ),
          onScheduleWeek: (todo) => _scheduleTodo(
            context,
            todo,
            _bestScheduleDay(days, todos, today),
          ),
        ),
        const SizedBox(height: 12),
        _WeekSelectedTasksPanel(
          selectedDate: normalizedSelectedDate,
          todos: selectedTodos,
          hasBacklog: unscheduledTodos.isNotEmpty,
          onScheduleBacklogToSelectedDay: unscheduledTodos.isEmpty
              ? null
              : () => _scheduleBacklogToSelectedDay(
                    context,
                    unscheduledTodos,
                    normalizedSelectedDate,
                  ),
          onScheduleAllBacklogToSelectedDay: unscheduledTodos.isEmpty
              ? null
              : () => _scheduleAllBacklogToSelectedDay(
                    context,
                    unscheduledTodos,
                    normalizedSelectedDate,
                  ),
          onToggle: onToggle,
          onPostpone: onPostpone,
          onArchive: onArchive,
          onDelete: onDelete,
        ),
      ],
    );
  }

  List<TodoItem> _weekTodos(List<DateTime> days) {
    return todos.where((todo) {
      return todo.isActive && days.any((day) => todo.isDueOn(day));
    }).toList()
      ..sort(_sortPlanTodos);
  }

  List<TodoItem> _unscheduledTodos(DateTime today, List<DateTime> days) {
    // 未安排区不仅包含无日期任务，也包含过期任务和延期到本周外的任务。
    return todos.where((todo) {
      if (!todo.isActive) {
        return false;
      }
      final dueDate = todo.dueDate;
      if (dueDate == null) {
        return true;
      }
      final belongsToThisWeek = days.any((day) => todo.isDueOn(day));
      if (dueDate.isBefore(today)) {
        return true;
      }
      return todo.status == TodoStatus.postponed && !belongsToThisWeek;
    }).toList()
      ..sort(_sortPlanTodos);
  }

  int _completedInWeek(List<DateTime> days) {
    return todos.where((todo) {
      return todo.done && days.any((day) => todo.isDueOn(day));
    }).length;
  }

  String _weekInsight({
    required List<TodoItem> weekTodos,
    required List<TodoItem> unscheduledTodos,
    required List<DateTime> days,
    required DateTime today,
  }) {
    if (unscheduledTodos.isNotEmpty) {
      return '本周节奏需要整理：有 ${unscheduledTodos.length} 项待安排，可以先放进空档日。';
    }
    if (weekTodos.isEmpty) {
      return '本周节奏还很空，可以从待办箱挑 1-2 项先安排。';
    }
    final overloadedDays = days.where((day) {
      return _dayTodos(day, todos).length >= 5 && !day.isBefore(today);
    }).length;
    if (overloadedDays > 0) {
      return '本周节奏偏满：有 $overloadedDays 天负载较高，建议把低优先级任务往后挪。';
    }
    return '本周节奏稳定：任务分布比较均衡，按当前安排推进就行。';
  }

  void _autoScheduleWeek(
    BuildContext context,
    DateTime today,
    List<DateTime> days,
    List<TodoItem> unscheduledTodos,
  ) {
    // 自动安排会边更新外部状态，边维护 plannedTodos，保证下一项能看到最新负载。
    final plannedTodos = List<TodoItem>.of(todos);
    final originalTodos = <TodoItem>[];
    var scheduledCount = 0;
    for (final todo in unscheduledTodos) {
      final targetDay = _bestScheduleDay(days, plannedTodos, today);
      final updated = _scheduledCopy(todo, targetDay);
      originalTodos.add(todo.copyWith());
      onUpdate(updated);
      scheduledCount++;

      final index = plannedTodos.indexWhere((item) => item.id == todo.id);
      if (index == -1) {
        plannedTodos.add(updated);
      } else {
        plannedTodos[index] = updated;
      }
    }
    _showUndoableScheduleSnackBar(
      context,
      message: '已安排 $scheduledCount 项到本周',
      originalTodos: originalTodos,
    );
  }

  void _balanceWeek(BuildContext context, DateTime today, List<DateTime> days) {
    final unscheduledTodos = _unscheduledTodos(today, days);
    if (unscheduledTodos.isNotEmpty) {
      _autoScheduleWeek(context, today, days, unscheduledTodos);
      return;
    }
    final movableTodos = _weekTodos(days)
        .where((todo) => todo.priority == TodoPriority.canDelay)
        .toList()
      ..sort(_sortPlanTodos);
    if (movableTodos.isEmpty) {
      _showPlainWeekSnackBar(context, '本周已经比较均衡，没有需要移动的低优先级任务');
      return;
    }
    final plannedTodos = List<TodoItem>.of(todos);
    final originalTodos = <TodoItem>[];
    var movedCount = 0;
    for (final todo in movableTodos.take(3)) {
      final targetDay = _bestScheduleDay(days, plannedTodos, today);
      if (todo.isDueOn(targetDay)) {
        continue;
      }
      final updated = _scheduledCopy(todo, targetDay);
      originalTodos.add(todo.copyWith());
      onUpdate(updated);
      movedCount++;
      final index = plannedTodos.indexWhere((item) => item.id == todo.id);
      if (index != -1) {
        plannedTodos[index] = updated;
      }
    }
    if (movedCount == 0) {
      _showPlainWeekSnackBar(context, '本周已经比较均衡');
      return;
    }
    _showUndoableScheduleSnackBar(
      context,
      message: '已平衡本周 $movedCount 项任务',
      originalTodos: originalTodos,
    );
  }

  void _moveLowPriorityToNextWeek(BuildContext context, List<DateTime> days) {
    final movableTodos = _weekTodos(days)
        .where((todo) => todo.priority == TodoPriority.canDelay)
        .toList()
      ..sort(_sortPlanTodos);
    if (movableTodos.isEmpty) {
      _showPlainWeekSnackBar(context, '本周没有低优先级任务需要移动');
      return;
    }
    final originalTodos = <TodoItem>[];
    for (final todo in movableTodos) {
      final dueDate = todo.dueDate;
      if (dueDate == null) {
        continue;
      }
      originalTodos.add(todo.copyWith());
      onUpdate(
        todo.copyWith(
          dueDate: DateUtils.dateOnly(dueDate.add(const Duration(days: 7))),
          status: TodoStatus.postponed,
          postponedCount: todo.postponedCount + 1,
        ),
      );
    }
    if (originalTodos.isEmpty) {
      _showPlainWeekSnackBar(context, '本周没有低优先级任务需要移动');
      return;
    }
    _showUndoableScheduleSnackBar(
      context,
      message: '已把 ${originalTodos.length} 项低优先级任务移到下周',
      originalTodos: originalTodos,
    );
  }

  void _cleanOverdueTodos(
    BuildContext context,
    DateTime today,
    List<DateTime> days,
  ) {
    final overdueTodos = todos.where((todo) {
      final dueDate = todo.dueDate;
      return todo.isActive && dueDate != null && dueDate.isBefore(today);
    }).toList()
      ..sort(_sortPlanTodos);
    if (overdueTodos.isEmpty) {
      _showPlainWeekSnackBar(context, '没有逾期任务需要清理');
      return;
    }
    final plannedTodos = List<TodoItem>.of(todos);
    final originalTodos = <TodoItem>[];
    for (final todo in overdueTodos) {
      final targetDay = _bestScheduleDay(days, plannedTodos, today);
      final updated = _scheduledCopy(todo, targetDay);
      originalTodos.add(todo.copyWith());
      onUpdate(updated);
      final index = plannedTodos.indexWhere((item) => item.id == todo.id);
      if (index != -1) {
        plannedTodos[index] = updated;
      }
    }
    _showUndoableScheduleSnackBar(
      context,
      message: '已重新安排 ${originalTodos.length} 项逾期任务',
      originalTodos: originalTodos,
    );
  }

  void _scheduleTodo(BuildContext context, TodoItem todo, DateTime targetDay) {
    onUpdate(_scheduledCopy(todo, targetDay));
    _showUndoableScheduleSnackBar(
      context,
      message: '已安排到 ${_formatPlanDate(targetDay)}',
      originalTodos: [todo.copyWith()],
    );
  }

  void _scheduleBacklogToSelectedDay(
    BuildContext context,
    List<TodoItem> backlogTodos,
    DateTime selectedDate,
  ) {
    if (backlogTodos.isEmpty) {
      return;
    }
    final todo = backlogTodos.first;
    onUpdate(_scheduledCopy(todo, selectedDate));
    _showUndoableScheduleSnackBar(
      context,
      message: '已安排 1 项到选中日期',
      originalTodos: [todo.copyWith()],
    );
  }

  void _scheduleAllBacklogToSelectedDay(
    BuildContext context,
    List<TodoItem> backlogTodos,
    DateTime selectedDate,
  ) {
    if (backlogTodos.isEmpty) {
      return;
    }
    final scheduledTodos =
        backlogTodos.take(_maxScheduleToSelectedDay).toList(growable: false);
    for (final todo in scheduledTodos) {
      onUpdate(_scheduledCopy(todo, selectedDate));
    }
    final remainingCount = backlogTodos.length - scheduledTodos.length;
    final message = remainingCount > 0
        ? '已安排 ${scheduledTodos.length} 项到选中日期，还有 $remainingCount 项留在待安排'
        : '已安排 ${scheduledTodos.length} 项到选中日期';
    _showUndoableScheduleSnackBar(
      context,
      message: message,
      originalTodos: scheduledTodos.map((todo) => todo.copyWith()).toList(),
    );
  }

  void _showUndoableScheduleSnackBar(
    BuildContext context, {
    required String message,
    required List<TodoItem> originalTodos,
  }) {
    _showWeekPlanFeedback(
      context,
      message: message,
      onUndo: () {
        for (final todo in originalTodos) {
          onUpdate(todo);
        }
      },
    );
  }

  void _showPlainWeekSnackBar(BuildContext context, String message) {
    _showWeekPlanFeedback(context, message: message);
  }

  void _showWeekPlanFeedback(
    BuildContext context, {
    required String message,
    VoidCallback? onUndo,
  }) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _showFallbackWeekSnackBar(context, message, onUndo);
      return;
    }

    _weekPlanFeedbackEntry?.remove();
    _weekPlanFeedbackEntry = null;

    late OverlayEntry entry;
    var removed = false;
    void removeEntry() {
      if (removed) {
        return;
      }
      removed = true;
      if (identical(_weekPlanFeedbackEntry, entry)) {
        _weekPlanFeedbackEntry = null;
      }
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) {
        return _WeekPlanFeedbackToast(
          message: message,
          onUndo: onUndo,
          onClose: removeEntry,
          onDisposed: () {
            if (identical(_weekPlanFeedbackEntry, entry)) {
              _weekPlanFeedbackEntry = null;
            }
          },
        );
      },
    );
    _weekPlanFeedbackEntry = entry;
    overlay.insert(entry);
  }

  void _showFallbackWeekSnackBar(
    BuildContext context,
    String message,
    VoidCallback? onUndo,
  ) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: onUndo == null
            ? null
            : SnackBarAction(label: '撤销', onPressed: onUndo),
      ),
    );
  }

  TodoItem _scheduledCopy(TodoItem todo, DateTime targetDay) {
    return todo.copyWith(
      dueDate: DateUtils.dateOnly(targetDay),
      status: todo.status == TodoStatus.postponed
          ? TodoStatus.notStarted
          : todo.status,
    );
  }

  DateTime _bestScheduleDay(
    List<DateTime> days,
    List<TodoItem> plannedTodos,
    DateTime today,
  ) {
    final candidates = days.where((day) => !day.isBefore(today)).toList();
    final usableDays = candidates.isEmpty ? days : candidates;
    usableDays.sort((a, b) {
      final aCount = _dayTodos(a, plannedTodos).length;
      final bCount = _dayTodos(b, plannedTodos).length;
      final countCompare = aCount.compareTo(bCount);
      if (countCompare != 0) {
        return countCompare;
      }
      return a.compareTo(b);
    });
    return usableDays.first;
  }
}

class _WeekPlanFeedbackToast extends StatefulWidget {
  const _WeekPlanFeedbackToast({
    required this.message,
    required this.onClose,
    required this.onDisposed,
    this.onUndo,
  });

  final String message;
  final VoidCallback onClose;
  final VoidCallback onDisposed;
  final VoidCallback? onUndo;

  @override
  State<_WeekPlanFeedbackToast> createState() => _WeekPlanFeedbackToastState();
}

class _WeekPlanFeedbackToastState extends State<_WeekPlanFeedbackToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  Timer? _dismissTimer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    _controller.forward();
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    widget.onDisposed();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_closing) {
      return;
    }
    _closing = true;
    _dismissTimer?.cancel();
    if (mounted) {
      await _controller.reverse();
    }
    widget.onClose();
  }

  void _handleUndo() {
    widget.onUndo?.call();
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    const bottomOffset = moduleSwitchBarReservedHeight + 12;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomOffset,
      child: SafeArea(
        top: false,
        child: SlideTransition(
          position: _offset,
          child: FadeTransition(
            opacity: _opacity,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Semantics(
                liveRegion: true,
                label: widget.message,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 272),
                  child: Material(
                    key: const ValueKey('week_plan_schedule_feedback'),
                    type: MaterialType.transparency,
                    child: GlassSurface(
                      borderRadius: 16,
                      color: AppColors.surface.withValues(alpha: 0.86),
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColors.success,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                                height: 1.25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (widget.onUndo != null) ...[
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: _handleUndo,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                minimumSize: const Size(48, 40),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              child: const Text('撤销'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekCommandCenter extends StatelessWidget {
  const _WeekCommandCenter({
    required this.weekTodos,
    required this.completedCount,
    required this.unscheduledCount,
    required this.riskCount,
    required this.insight,
    required this.onAutoSchedule,
    required this.onBalanceWeek,
    required this.onMoveLowPriorityNextWeek,
    required this.onCleanOverdue,
  });

  final int weekTodos;
  final int completedCount;
  final int unscheduledCount;
  final int riskCount;
  final String insight;
  final VoidCallback? onAutoSchedule;
  final VoidCallback onBalanceWeek;
  final VoidCallback onMoveLowPriorityNextWeek;
  final VoidCallback? onCleanOverdue;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week_plan_command_center'),
      padding: const EdgeInsets.all(14),
      decoration: _weekCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '一周安排工作台',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WeekMetricTile(
                  label: '本周',
                  value: '$weekTodos',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekMetricTile(
                  label: '完成',
                  value: '$completedCount',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekMetricTile(
                  label: '待安排',
                  value: '$unscheduledCount',
                  color: const Color(0xFFFF9559),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WeekMetricTile(
                  label: '风险',
                  value: '$riskCount',
                  color: AppColors.financeRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('week_plan_auto_schedule'),
              onPressed: onAutoSchedule,
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: const Text('一键排周'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primarySoft,
                disabledForegroundColor: AppColors.muted,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WeekCommandButton(
                key: const ValueKey('week_plan_balance_week'),
                onPressed: onBalanceWeek,
                icon: Icons.balance_rounded,
                label: '平衡本周',
              ),
              _WeekCommandButton(
                key: const ValueKey('week_plan_clean_overdue'),
                onPressed: onCleanOverdue,
                icon: Icons.history_toggle_off_rounded,
                label: '清理逾期',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _WeekCommandButton(
            key: const ValueKey('week_plan_move_low_priority_next_week'),
            onPressed: onMoveLowPriorityNextWeek,
            icon: Icons.low_priority_rounded,
            label: '低优先级移到下周',
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _WeekCommandButton extends StatelessWidget {
  const _WeekCommandButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.fullWidth = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.24)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = (constraints.maxWidth - 8) / 2;
        final width = available < 124.0 ? 124.0 : available;
        return SizedBox(width: width, child: button);
      },
    );
  }
}

class _WeekMetricTile extends StatelessWidget {
  const _WeekMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayBoard extends StatelessWidget {
  const _WeekDayBoard({
    required this.days,
    required this.selectedDate,
    required this.todos,
    required this.onSelectDate,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final List<TodoItem> todos;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week_plan_day_board'),
      padding: const EdgeInsets.all(14),
      decoration: _weekCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModuleSectionTitle(
            icon: Icons.view_week_rounded,
            title: '7 天任务板',
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.85,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              return _WeekDayCard(
                date: day,
                todos: _dayTodos(day, todos),
                selected: DateUtils.isSameDay(day, selectedDate),
                onTap: () => onSelectDate(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  const _WeekDayCard({
    required this.date,
    required this.todos,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final List<TodoItem> todos;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final load = _loadInfo(todos.length);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _weekdayLabel(date),
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '负载 ${load.label} · ${todos.length} 项',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: 0.86)
                    : load.color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Spacer(),
            if (todos.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : load.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${todos.length}',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: selected ? Colors.white : load.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekUnscheduledSection extends StatelessWidget {
  const _WeekUnscheduledSection({
    required this.todos,
    required this.onScheduleToday,
    required this.onScheduleTomorrow,
    required this.onScheduleWeek,
  });

  final List<TodoItem> todos;
  final ValueChanged<TodoItem> onScheduleToday;
  final ValueChanged<TodoItem> onScheduleTomorrow;
  final ValueChanged<TodoItem> onScheduleWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week_plan_unscheduled_section'),
      padding: const EdgeInsets.all(14),
      decoration: _weekCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: ModuleSectionTitle(
                  icon: Icons.move_to_inbox_rounded,
                  title: '待安排任务',
                ),
              ),
              Text(
                '待安排 ${todos.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todos.isEmpty)
            const _WeekEmptyHint(
              title: '本周没有待安排任务',
              subtitle: '无日期、过期或需要重新整理的任务会出现在这里。',
            )
          else
            for (final todo in todos)
              _UnscheduledTodoTile(
                todo: todo,
                onScheduleToday: () => onScheduleToday(todo),
                onScheduleTomorrow: () => onScheduleTomorrow(todo),
                onScheduleWeek: () => onScheduleWeek(todo),
              ),
        ],
      ),
    );
  }
}

class _UnscheduledTodoTile extends StatelessWidget {
  const _UnscheduledTodoTile({
    required this.todo,
    required this.onScheduleToday,
    required this.onScheduleTomorrow,
    required this.onScheduleWeek,
  });

  final TodoItem todo;
  final VoidCallback onScheduleToday;
  final VoidCallback onScheduleTomorrow;
  final VoidCallback onScheduleWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: todo.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  todo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _PriorityChip(priority: todo.priority),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScheduleActionChip(label: '排今天', onTap: onScheduleToday),
              _ScheduleActionChip(label: '排明天', onTap: onScheduleTomorrow),
              _ScheduleActionChip(label: '排本周', onTap: onScheduleWeek),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleActionChip extends StatelessWidget {
  const _ScheduleActionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primarySoft,
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TodoPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: priority.color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WeekSelectedTasksPanel extends StatelessWidget {
  const _WeekSelectedTasksPanel({
    required this.selectedDate,
    required this.todos,
    required this.hasBacklog,
    required this.onScheduleBacklogToSelectedDay,
    required this.onScheduleAllBacklogToSelectedDay,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final DateTime selectedDate;
  final List<TodoItem> todos;
  final bool hasBacklog;
  final VoidCallback? onScheduleBacklogToSelectedDay;
  final VoidCallback? onScheduleAllBacklogToSelectedDay;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final load = _loadInfo(todos.length);
    final overloaded = todos.length >= 5;

    return Container(
      key: const ValueKey('week_plan_selected_tasks_panel'),
      padding: const EdgeInsets.all(14),
      decoration: _weekCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatPlanDate(selectedDate)}  ${todos.length} 项',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${_weekdayLabel(selectedDate)} · ${load.label}',
                style: TextStyle(
                  color: load.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (overloaded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.financeRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.financeRed.withValues(alpha: 0.18),
                ),
              ),
              child: const Text(
                '这天任务偏满，建议只排高优先级事项。',
                style: TextStyle(
                  color: AppColors.financeRed,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (hasBacklog) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('week_plan_schedule_selected_day'),
                    onPressed: onScheduleBacklogToSelectedDay,
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('排一项到这天'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey(
                      'week_plan_schedule_all_selected_day',
                    ),
                    onPressed: onScheduleAllBacklogToSelectedDay,
                    icon:
                        const Icon(Icons.playlist_add_check_rounded, size: 18),
                    label: const Text('排全部到这天'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (todos.isEmpty)
            _WeekEmptyHint(
              title: '这天还空着',
              subtitle:
                  hasBacklog ? '可以从上方待安排任务里排入这一天。' : '这天没有任务，适合留作缓冲或新增一个轻量安排。',
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
      ),
    );
  }
}

class _WeekEmptyHint extends StatelessWidget {
  const _WeekEmptyHint({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

({String label, Color color}) _loadInfo(int count) {
  if (count == 0) {
    return (label: '空档', color: AppColors.success);
  }
  if (count <= 2) {
    return (label: '轻松', color: AppColors.primary);
  }
  if (count <= 4) {
    return (label: '合理', color: const Color(0xFFFF9559));
  }
  return (label: '偏满', color: AppColors.financeRed);
}

List<TodoItem> _dayTodos(DateTime day, List<TodoItem> todos) {
  return todos.where((todo) => todo.isActive && todo.isDueOn(day)).toList()
    ..sort(_sortPlanTodos);
}

BoxDecoration _weekCardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.line),
  );
}
