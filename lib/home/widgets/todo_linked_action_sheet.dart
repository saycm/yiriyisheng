part of '../../main.dart';

class _TodoLinkedActionSheet extends StatelessWidget {
  const _TodoLinkedActionSheet({
    required this.todo,
    required this.onSelect,
  });

  final TodoItem todo;
  final ValueChanged<TodoLinkedModule> onSelect;

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
      title: '继续记录',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            todo.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '任务已完成，可以顺手把相关模块的数据补齐。',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...todo.linkedModules.map(
            (module) => _TodoLinkedActionTile(
              module: module,
              prompt: _linkedTodoPrompt(todo, module),
              onTap: () => onSelect(module),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '稍后处理',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoLinkedActionTile extends StatelessWidget {
  const _TodoLinkedActionTile({
    required this.module,
    required this.prompt,
    required this.onTap,
  });

  final TodoLinkedModule module;
  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(module.icon, color: module.color, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.actionLabel,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        prompt,
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
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.muted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _linkedTodoPrompt(TodoItem todo, TodoLinkedModule module) {
  return switch (module) {
    TodoLinkedModule.finance => '${todo.title} 已完成，可以补一条财务记录。',
    TodoLinkedModule.food => '${todo.title} 已完成，可以补充饮食记录。',
    TodoLinkedModule.workout => '${todo.title} 已完成，可以记录训练组数。',
    TodoLinkedModule.health => todo.done
        ? '${todo.title} 已完成，健康模块会同步今日状态。'
        : '${todo.title} 未完成，明天关注睡眠和恢复。',
  };
}
