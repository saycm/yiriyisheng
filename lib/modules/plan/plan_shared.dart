part of '../../main.dart';

InputDecoration _planInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: AppColors.muted,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
}

List<(String, Color)> _todoCategoryOptions() {
  return const [
    ('工作', Color(0xFF9278F7)),
    ('生活', Color(0xFF7D9CFF)),
    ('健康', Color(0xFFFF6F9D)),
    ('财务', AppColors.success),
    ('学习', Color(0xFFB88955)),
    ('自定义', AppColors.muted),
  ];
}

String _formatPlanDate(DateTime? date) {
  if (date == null) {
    return '无日期';
  }
  return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
}

String _formatPlanMonth(DateTime date) {
  return '${date.year}年${date.month.toString().padLeft(2, '0')}月';
}

String _weekdayLabel(DateTime date) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[date.weekday - 1];
}

String _pendingLinkedHint(TodoItem todo) {
  if (todo.linkedModules.isEmpty) {
    return '';
  }
  final modules = todo.linkedModules.map((module) => module.label).join('、');
  return '完成后会提醒你补充$modules记录。';
}
