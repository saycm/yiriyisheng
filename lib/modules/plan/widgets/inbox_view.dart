// 中文注释：计划模块页面组件，负责今日总览、待办箱、周计划和统计视图。

part of '../plan.dart';

class _InboxView extends StatelessWidget {
  const _InboxView({
    required this.inboxTodos,
    required this.completedTodos,
    required this.archivedTodos,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
    required this.onQuickCapture,
    required this.onUpdate,
  });

  final List<TodoItem> inboxTodos;
  final List<TodoItem> completedTodos;
  final List<TodoItem> archivedTodos;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;
  final ValueChanged<String> onQuickCapture;
  final ValueChanged<TodoItem> onUpdate;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final triageGroups = _inboxTriageGroups(inboxTodos, today);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        88,
      ),
      children: [
        _InboxTriageHeader(
          total: inboxTodos.length,
          noDateCount: triageGroups.noDate.length,
          lowPriorityCount: triageGroups.lowPriority.length,
          staleCount: triageGroups.stale.length,
        ),
        const SizedBox(height: 12),
        _InboxQuickCaptureCard(
          onTap: () => _openQuickCaptureSheet(context),
        ),
        const SizedBox(height: 16),
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
          const EmptyCard(
            title: '待办箱是空的',
            subtitle: '没有日期的任务会先收集在这里，想清楚后再安排到今天或本周。',
          )
        else
          ..._buildTriageSections(
            context,
            groups: triageGroups,
            today: today,
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

  List<Widget> _buildTriageSections(
    BuildContext context, {
    required _InboxTriageGroups groups,
    required DateTime today,
  }) {
    final sections = <Widget>[];
    void addSection(String title, String subtitle, List<TodoItem> todos) {
      if (todos.isEmpty) {
        return;
      }
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 12));
      }
      sections.add(
        _InboxTriageSection(
          title: title,
          subtitle: subtitle,
          todos: todos,
          onToggle: onToggle,
          onArchive: onArchive,
          onDelete: onDelete,
          onScheduleToday: (todo) => _scheduleTodo(
            context,
            todo,
            today,
            '已安排到今天',
          ),
          onScheduleTomorrow: (todo) => _scheduleTodo(
            context,
            todo,
            today.add(const Duration(days: 1)),
            '已安排到明天',
          ),
          onScheduleWeek: (todo) => _scheduleTodo(
            context,
            todo,
            today.add(Duration(days: 7 - today.weekday)),
            '已安排到本周',
          ),
          onPostpone: onPostpone,
        ),
      );
    }

    addSection('无日期', '还没决定哪天做，先排到今天、明天或本周。', groups.noDate);
    addSection('无分类', '分类信息不完整，后续可以补充到更准确的领域。', groups.noCategory);
    addSection('已过期', '这些任务已经错过原日期，需要重新安排。', groups.stale);
    addSection('低优先级', '可推迟事项不要挤占今天的核心精力。', groups.lowPriority);
    return sections;
  }

  void _scheduleTodo(
    BuildContext context,
    TodoItem todo,
    DateTime targetDay,
    String message,
  ) {
    onUpdate(
      todo.copyWith(
        dueDate: DateUtils.dateOnly(targetDay),
        status: TodoStatus.notStarted,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openQuickCaptureSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _InboxQuickCaptureSheet(
          onSave: (title) {
            onQuickCapture(title);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }
}

class _InboxTriageHeader extends StatelessWidget {
  const _InboxTriageHeader({
    required this.total,
    required this.noDateCount,
    required this.lowPriorityCount,
    required this.staleCount,
  });

  final int total;
  final int noDateCount;
  final int lowPriorityCount;
  final int staleCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('plan_inbox_triage_center'),
      padding: const EdgeInsets.all(14),
      decoration: airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rule_folder_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                '收集整理中心',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '先把脑子里的事收进来，再决定今天做、本周做，还是暂时归档。',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _InboxTriageMetric(label: '待整理', value: total)),
              const SizedBox(width: 8),
              Expanded(
                  child: _InboxTriageMetric(label: '无日期', value: noDateCount)),
              const SizedBox(width: 8),
              Expanded(
                  child: _InboxTriageMetric(
                      label: '低优先级', value: lowPriorityCount)),
              const SizedBox(width: 8),
              Expanded(
                  child: _InboxTriageMetric(label: '已过期', value: staleCount)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InboxTriageMetric extends StatelessWidget {
  const _InboxTriageMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxTriageSection extends StatelessWidget {
  const _InboxTriageSection({
    required this.title,
    required this.subtitle,
    required this.todos,
    required this.onToggle,
    required this.onArchive,
    required this.onDelete,
    required this.onScheduleToday,
    required this.onScheduleTomorrow,
    required this.onScheduleWeek,
    required this.onPostpone,
  });

  final String title;
  final String subtitle;
  final List<TodoItem> todos;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;
  final ValueChanged<TodoItem> onScheduleToday;
  final ValueChanged<TodoItem> onScheduleTomorrow;
  final ValueChanged<TodoItem> onScheduleWeek;
  final ValueChanged<TodoItem> onPostpone;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title  ${todos.length}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.tune_rounded,
                  color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final todo in todos)
            _InboxTriageTodoTile(
              todo: todo,
              onToggle: () => onToggle(todo),
              onArchive: () => onArchive(todo),
              onDelete: () => onDelete(todo),
              onScheduleToday: () => onScheduleToday(todo),
              onScheduleTomorrow: () => onScheduleTomorrow(todo),
              onScheduleWeek: () => onScheduleWeek(todo),
              onPostpone: () => onPostpone(todo),
            ),
        ],
      ),
    );
  }
}

class _InboxTriageTodoTile extends StatelessWidget {
  const _InboxTriageTodoTile({
    required this.todo,
    required this.onToggle,
    required this.onArchive,
    required this.onDelete,
    required this.onScheduleToday,
    required this.onScheduleTomorrow,
    required this.onScheduleWeek,
    required this.onPostpone,
  });

  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onScheduleToday;
  final VoidCallback onScheduleTomorrow;
  final VoidCallback onScheduleWeek;
  final VoidCallback onPostpone;

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
              _ScheduleActionChip(label: '稍后', onTap: onPostpone),
              _ScheduleActionChip(label: '归档', onTap: onArchive),
              _ScheduleActionChip(label: '完成', onTap: onToggle),
              _ScheduleActionChip(label: '删除', onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

typedef _InboxTriageGroups = ({
  List<TodoItem> noDate,
  List<TodoItem> noCategory,
  List<TodoItem> stale,
  List<TodoItem> lowPriority,
});

_InboxTriageGroups _inboxTriageGroups(List<TodoItem> todos, DateTime today) {
  final noDate = <TodoItem>[];
  final noCategory = <TodoItem>[];
  final stale = <TodoItem>[];
  final lowPriority = <TodoItem>[];
  for (final todo in todos) {
    if (todo.dueDate == null) {
      noDate.add(todo);
    }
    if (todo.category.trim().isEmpty || todo.category == '自定义') {
      noCategory.add(todo);
    }
    final dueDate = todo.dueDate;
    if (dueDate != null && dueDate.isBefore(today)) {
      stale.add(todo);
    }
    if (todo.priority == TodoPriority.canDelay) {
      lowPriority.add(todo);
    }
  }
  return (
    noDate: noDate..sort(_sortPlanTodos),
    noCategory: noCategory..sort(_sortPlanTodos),
    stale: stale..sort(_sortPlanTodos),
    lowPriority: lowPriority..sort(_sortPlanTodos),
  );
}

class _InboxQuickCaptureCard extends StatelessWidget {
  const _InboxQuickCaptureCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('plan_inbox_quick_capture'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.inbox_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '收件箱快速录入',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
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
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(14),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: 14,
        color: AppColors.surface.withValues(alpha: 0.74),
        padding: const EdgeInsets.all(16),
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
      ),
    );
  }
}
