part of '../../../main.dart';

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
  });

  final List<TodoItem> inboxTodos;
  final List<TodoItem> completedTodos;
  final List<TodoItem> archivedTodos;
  final ValueChanged<TodoItem> onToggle;
  final ValueChanged<TodoItem> onPostpone;
  final ValueChanged<TodoItem> onArchive;
  final ValueChanged<TodoItem> onDelete;
  final ValueChanged<String> onQuickCapture;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        _moduleSwitchBarReservedHeight + 88,
      ),
      children: [
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

class _InboxQuickCaptureCard extends StatelessWidget {
  const _InboxQuickCaptureCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: const ValueKey('plan_inbox_quick_capture'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
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
