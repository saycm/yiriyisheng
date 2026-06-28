part of '../../../main.dart';

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
      decoration: _airyCardDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        shadows: [_airyShadow(todo.color)],
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
