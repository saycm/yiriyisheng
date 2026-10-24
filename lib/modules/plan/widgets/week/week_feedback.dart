// 中文注释：计划周视图反馈，负责底部浮层、撤销按钮和 snack bar 兜底。

part of '../../plan.dart';

// 当前周计划反馈浮层的引用，保证同一时间只显示一条。
OverlayEntry? _weekPlanFeedbackEntry;

/// 周计划的反馈扩展：统一处理排期成功提示、撤销和浮层展示。
extension _WeekPlanFeedbackActions on _WeekPlanView {
  // 显示带“撤销”按钮的排期结果提示，撤销时逐条恢复原始任务。
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

  // 显示一条普通提示（无撤销）。
  void _showPlainWeekSnackBar(BuildContext context, String message) {
    _showWeekPlanFeedback(context, message: message);
  }

  // 优先使用自定义浮层反馈；没有 Overlay 时退回 SnackBar。
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

  // 自定义浮层不可用时的兜底提示。
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
}

/// 周计划操作的底部反馈浮层，支持撤销和自动消失。
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

/// 周计划反馈浮层的动画与关闭状态。
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
    // 入场动画 + 4 秒后自动关闭。
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
    // 取消定时器并释放动画资源。
    _dismissTimer?.cancel();
    _controller.dispose();
    widget.onDisposed();
    super.dispose();
  }

  Future<void> _dismiss() async {
    // 防止重复触发关闭动画。
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
    // 执行撤销回调后再收起浮层。
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
