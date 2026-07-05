// 中文注释：计划周视图反馈，负责底部浮层、撤销按钮和 snack bar 兜底。

part of '../../plan.dart';

OverlayEntry? _weekPlanFeedbackEntry;

extension _WeekPlanFeedbackActions on _WeekPlanView {
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

  void _showPlainWeekSnackBar(BuildContext context, String message) {
    _showWeekPlanFeedback(context, message: message);
  }

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
