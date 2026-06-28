part of '../../../main.dart';

class _TodoList extends StatelessWidget {
  const _TodoList({
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        0,
        18,
        _moduleSwitchBarReservedHeight + 88,
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
