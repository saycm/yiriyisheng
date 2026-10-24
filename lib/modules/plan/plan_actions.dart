// 中文注释：计划模块源码，负责待办状态、日期选择和计划页交互。

part of 'plan.dart';

// 当前屏幕上显示的待办完成反馈浮层；同一时间只保留一个，避免多条重叠。
OverlayEntry? _planTodoCompletionFeedbackEntry;

/// 计划页的用户操作集合：勾选待办、快速收集、打开更多面板、新增待办。
mixin _PlanModuleActions on _PlanModuleState {
  // 勾选/取消勾选待办；标记完成时弹出带“撤销”和关联模块入口的反馈。
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

  // 把待办箱输入框里的文字快速创建成一条“生活”分类的待办。
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

  // 打开“更多”面板：分类筛选、清理已完成待办。
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
            // 清理前先移除完成反馈浮层，避免它引用已经删除的待办。
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

  // 打开新增待办表单，保存后通过首页回调写入全局状态。
  void _showAddTodoSheet() {
    _showPlanTodoEditorSheet(
      context: context,
      today: _today,
      onSave: widget.onAddTodo,
    );
  }

  // 显示待办完成反馈：优先用自定义 Overlay 浮层，拿不到 Overlay 时退回 SnackBar。
  void _showTodoCompletionFeedback({
    required String title,
    required TodoLinkedModule? linkedModule,
    required VoidCallback onUndo,
  }) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final message = '已完成：$title';
    // 没有根 Overlay（例如测试环境）时降级为普通 SnackBar。
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
    // 保证浮层只被移除一次，并同步清空全局引用。
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

/// 待办完成后的底部浮层：显示完成文案、撤销按钮和关联模块快捷入口。
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

/// 待办完成浮层的动画与自动关闭状态。
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
    // 入场动画：从下方 34% 位置滑入并淡入。
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
    // 4 秒后自动收起，用户仍可在期间点击撤销。
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  @override
  void dispose() {
    // 销毁时取消定时器并通知父级清理 Overlay 引用。
    _dismissTimer?.cancel();
    _controller.dispose();
    widget.onDisposed();
    super.dispose();
  }

  Future<void> _dismiss() async {
    // 防止自动超时和手动点击同时触发关闭。
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

  // 点击“撤销”：先回滚待办状态，再收起浮层。
  void _handleUndo() {
    widget.onUndo();
    _dismiss();
  }

  // 点击关联模块按钮：跳转到对应模块后收起浮层。
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

// 浮层内文字按钮的统一样式，按关联模块颜色着色。
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
