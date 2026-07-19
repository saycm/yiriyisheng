// 中文注释：计划模块源码，负责待办状态、日期选择和计划页交互。

part of 'plan.dart';

OverlayEntry? _planTodoCompletionFeedbackEntry;

mixin _PlanModuleActions on _PlanModuleState {
  void _toggleTodo(TodoItem todo) {
    final willComplete = !todo.done;
    final title = todo.title;
    final linkedModule =
        todo.linkedModules.isEmpty ? null : todo.linkedModules.first;
    widget.onToggleTodo(todo);
    if (!willComplete) {
      return;
    }
    _showTodoCompletionFeedback(
      title: title,
      linkedModule: linkedModule,
      onUndo: () => widget.onToggleTodo(todo),
    );
  }

  void _addInboxTodo(String title) {
    widget.onAddTodo(
      TodoItem(
        title: title,
        category: '生活',
        color: todoColorForCategory('生活'),
        priority: TodoPriority.shouldDo,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已放入待办箱'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            _planTodoCompletionFeedbackEntry?.remove();
            _planTodoCompletionFeedbackEntry = null;
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
    _showPlanTodoEditorSheet(
      context: context,
      today: _today,
      onSave: widget.onAddTodo,
    );
  }

  void _showTodoCompletionFeedback({
    required String title,
    required TodoLinkedModule? linkedModule,
    required VoidCallback onUndo,
  }) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final message = '已完成：$title';
    if (overlay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: '撤销', onPressed: onUndo),
        ),
      );
      return;
    }

    _planTodoCompletionFeedbackEntry?.remove();
    _planTodoCompletionFeedbackEntry = null;

    late OverlayEntry entry;
    var removed = false;
    void removeEntry() {
      if (removed) {
        return;
      }
      removed = true;
      if (identical(_planTodoCompletionFeedbackEntry, entry)) {
        _planTodoCompletionFeedbackEntry = null;
      }
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) {
        return _TodoCompletionFeedbackToast(
          message: message,
          linkedModule: linkedModule,
          onUndo: onUndo,
          onLinkedAction: linkedModule == null
              ? null
              : () => widget.onOpenLinkedTodoAction(linkedModule),
          onClose: removeEntry,
          onDisposed: () {
            if (identical(_planTodoCompletionFeedbackEntry, entry)) {
              _planTodoCompletionFeedbackEntry = null;
            }
          },
        );
      },
    );
    _planTodoCompletionFeedbackEntry = entry;
    overlay.insert(entry);
  }
}

class _TodoCompletionFeedbackToast extends StatefulWidget {
  const _TodoCompletionFeedbackToast({
    required this.message,
    required this.onUndo,
    required this.onClose,
    required this.onDisposed,
    required this.linkedModule,
    required this.onLinkedAction,
  });

  final String message;
  final VoidCallback onUndo;
  final VoidCallback onClose;
  final VoidCallback onDisposed;
  final TodoLinkedModule? linkedModule;
  final VoidCallback? onLinkedAction;

  @override
  State<_TodoCompletionFeedbackToast> createState() =>
      _TodoCompletionFeedbackToastState();
}

class _TodoCompletionFeedbackToastState
    extends State<_TodoCompletionFeedbackToast>
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
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.34),
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
    widget.onUndo();
    _dismiss();
  }

  void _handleLinkedAction() {
    widget.onLinkedAction?.call();
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    const bottomOffset = moduleSwitchBarBottomGap + 2;
    final linkedModule = widget.linkedModule;

    return Positioned(
      left: 18,
      right: 76,
      bottom: bottomOffset,
      child: SafeArea(
        top: false,
        child: SlideTransition(
          position: _offset,
          child: FadeTransition(
            opacity: _opacity,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Semantics(
                liveRegion: true,
                label: widget.message,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Material(
                    key: const ValueKey('plan_todo_completion_feedback'),
                    type: MaterialType.transparency,
                    child: GlassSurface(
                      borderRadius: 16,
                      color: AppColors.surface.withValues(alpha: 0.88),
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColors.success,
                              size: 19,
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
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: _handleUndo,
                            style: _todoCompletionFeedbackButtonStyle(
                              AppColors.muted,
                            ),
                            child: const Text('撤销'),
                          ),
                          if (linkedModule != null &&
                              widget.onLinkedAction != null)
                            TextButton(
                              onPressed: _handleLinkedAction,
                              style: _todoCompletionFeedbackButtonStyle(
                                linkedModule.color,
                              ),
                              child: Text(linkedModule.actionLabel),
                            ),
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

ButtonStyle _todoCompletionFeedbackButtonStyle(Color color) {
  return TextButton.styleFrom(
    foregroundColor: color,
    minimumSize: const Size(46, 40),
    padding: const EdgeInsets.symmetric(horizontal: 7),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w900,
    ),
  );
}
