part of '../../../main.dart';

class _InboxQuickCaptureSheet extends StatefulWidget {
  const _InboxQuickCaptureSheet({required this.onSave});

  final ValueChanged<String> onSave;

  @override
  State<_InboxQuickCaptureSheet> createState() =>
      _InboxQuickCaptureSheetState();
}

class _InboxQuickCaptureSheetState extends State<_InboxQuickCaptureSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InfoSheetFrame(
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
    final title = _controller.text.trim();
    if (title.isEmpty) {
      return;
    }
    widget.onSave(title);
  }
}
