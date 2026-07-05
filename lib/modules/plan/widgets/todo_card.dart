// 中文注释：计划模块页面组件，负责今日总览、待办箱、周计划和统计视图。

part of '../plan.dart';

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
    return AnimatedContainer(
      key: ValueKey('todo_card_${todo.title}'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: airyCardDecoration(
        color: todo.done
            ? AppColors.primarySoft.withValues(alpha: 0.78)
            : AppColors.surface.withValues(alpha: 0.97),
        shadows: [airyShadow(todo.done ? AppColors.success : todo.color)],
      ),
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: todo.done
                        ? const Icon(
                            Icons.check,
                            key: ValueKey('todo_check_done'),
                            size: 15,
                            color: Colors.white,
                          )
                        : const SizedBox(
                            key: ValueKey('todo_check_empty'),
                          ),
                  ),
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
                    ? linkedTodoPrompt(todo, todo.linkedModules.first)
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TodoActionButton(
          label: done ? '重新打开' : '完成',
          icon: done ? Icons.undo_rounded : Icons.check_rounded,
          color: AppColors.primary,
          filled: true,
          onTap: onComplete,
        ),
        _TodoActionButton(
          label: '下个工作日',
          icon: Icons.event_repeat_rounded,
          color: AppColors.sun,
          onTap: done ? null : onPostpone,
        ),
        _TodoActionButton(
          label: '归档',
          icon: Icons.archive_rounded,
          color: AppColors.muted,
          onTap: onArchive,
        ),
        _TodoActionButton(
          label: '删除',
          icon: Icons.delete_outline_rounded,
          color: AppColors.financeRed,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _TodoActionButton extends StatelessWidget {
  const _TodoActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground =
        enabled ? (filled ? Colors.white : color) : AppColors.muted;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: filled
              ? color
              : enabled
                  ? color.withValues(alpha: 0.10)
                  : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: filled ? 0.0 : 0.18)
                : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
