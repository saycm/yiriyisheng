// 中文注释：计划模块页面组件，负责今日总览、待办箱、周计划和统计视图。

part of '../plan.dart';

class _TodayExecutionView extends StatelessWidget {
  const _TodayExecutionView({
    required this.title,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.todos,
    required this.activeFilter,
    this.header,
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
  final Widget? header;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final filtered = activeFilter != '全部';
    final today = DateUtils.dateOnly(DateTime.now());
    final overdueTodos = todos.where((todo) {
      final dueDate = todo.dueDate;
      return dueDate != null && dueDate.isBefore(today);
    }).toList()
      ..sort(_sortPlanTodos);
    final todayOnlyTodos = todos.where((todo) {
      final dueDate = todo.dueDate;
      return dueDate != null && DateUtils.isSameDay(dueDate, today);
    }).toList()
      ..sort(_sortPlanTodos);
    final topThree = todayOnlyTodos.take(3).toList(growable: false);
    final laterTodos = todayOnlyTodos.skip(3).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        88,
      ),
      children: [
        if (header != null) ...[
          header!,
          const SizedBox(height: 16),
        ],
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
          EmptyCard(
            title: filtered ? '这个类别没有待办' : emptyTitle,
            subtitle: filtered ? '切回全部或添加新的$activeFilter事项' : emptySubtitle,
          )
        else ...[
          _TodayTodoSection(
            key: const ValueKey('plan_today_top_three'),
            title: '今日三件事',
            subtitle: '先处理最重要、正在进行或联动其他模块的事项。',
            todos: topThree,
            emptyText: '今天还没有核心事项。',
            onToggle: onToggle,
            onPostpone: onPostpone,
            onArchive: onArchive,
            onDelete: onDelete,
          ),
          const SizedBox(height: 12),
          _TodayTodoSection(
            title: '稍后处理',
            subtitle: '剩余任务先放在后面，避免今天的执行列表太吵。',
            todos: laterTodos,
            emptyText: '没有排在稍后的任务。',
            compactWhenEmpty: true,
            onToggle: onToggle,
            onPostpone: onPostpone,
            onArchive: onArchive,
            onDelete: onDelete,
          ),
          if (overdueTodos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TodayTodoSection(
              title: '逾期待处理',
              subtitle: '这些任务已经过期，建议重新排期或归档。',
              todos: overdueTodos,
              emptyText: '没有逾期任务。',
              onToggle: onToggle,
              onPostpone: onPostpone,
              onArchive: onArchive,
              onDelete: onDelete,
            ),
          ],
        ],
      ],
    );
  }
}

class _TodayTodoSection extends StatelessWidget {
  const _TodayTodoSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.todos,
    required this.emptyText,
    this.compactWhenEmpty = false,
    required this.onToggle,
    required this.onPostpone,
    required this.onArchive,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final List<TodoItem> todos;
  final String emptyText;
  final bool compactWhenEmpty;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty && compactWhenEmpty) {
      return _TodaySectionHeader(
        title: title,
        subtitle: emptyText,
        count: 0,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TodaySectionHeader(
          title: title,
          subtitle: subtitle,
          count: todos.length,
        ),
        const SizedBox(height: 10),
        if (todos.isEmpty)
          _TodayEmptySection(text: emptyText)
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

class _TodaySectionHeader extends StatelessWidget {
  const _TodaySectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      color: AppColors.surface.withValues(alpha: 0.78),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.35,
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

class _TodayEmptySection extends StatelessWidget {
  const _TodayEmptySection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
