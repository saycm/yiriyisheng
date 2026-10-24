// 中文注释：计划模块弹层组件，负责待办新增、筛选和快捷收集。

part of '../plan.dart';

/// 待办箱快速录入弹层：输入一句话即可创建待办。
class _InboxQuickCaptureSheet extends StatefulWidget {
  const _InboxQuickCaptureSheet({required this.onSave});

  final ValueChanged<String> onSave;

  @override
  State<_InboxQuickCaptureSheet> createState() =>
      _InboxQuickCaptureSheetState();
}

/// 快速录入弹层的输入状态。
class _InboxQuickCaptureSheetState extends State<_InboxQuickCaptureSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    // 弹层关闭时释放输入框控制器，避免内存泄漏。
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 底部留出键盘高度，保证输入时按钮不被遮挡。
    return InfoSheetFrame(
      title: '收件箱快速录入',
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            TextField(
              key: const ValueKey('plan_inbox_quick_capture_field'),
              controller: _controller,
              autofocus: true,
              cursorColor: AppColors.primary,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              decoration: _planInputDecoration('先写一句话'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                key: const ValueKey('plan_inbox_quick_capture_save'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text(
                  '放入待办箱',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    // 忽略空白输入，避免创建空标题待办。
    final title = _controller.text.trim();
    if (title.isEmpty) {
      return;
    }
    widget.onSave(title);
  }
}
