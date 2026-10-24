// 中文注释：计划模块源码，负责待办状态、日期选择和计划页交互。

part of 'plan.dart';

// 计划模块里新增/编辑待办表单共用的输入框样式（浅灰底、无边框、紧凑高度）。
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

// 待办分类的可选值及对应主题色，新增待办时用于生成分类选择器。
List<(String, Color)> _todoCategoryOptions() {
  return const [
    ('工作', Color(0xFF9278F7)),
    ('生活', Color(0xFF7D9CFF)),
    ('状态', Color(0xFFFF6F9D)),
    ('财务', AppColors.success),
    ('学习', Color(0xFFB88955)),
    ('自定义', AppColors.muted),
  ];
}

// 把可选日期格式化成“2026年07月22日”，null 显示“无日期”。
String _formatPlanDate(DateTime? date) {
  if (date == null) {
    return '无日期';
  }
  return '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';
}

// 把 DateTime.weekday（1=周一）转换成中文星期标签，用于周计划表头。
String _weekdayLabel(DateTime date) {
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[date.weekday - 1];
}

// 生成“完成后会提醒你补充饮食、锻炼记录”这类关联模块提示文案。
String _pendingLinkedHint(TodoItem todo) {
  if (todo.linkedModules.isEmpty) {
    return '';
  }
  final modules = todo.linkedModules.map((module) => module.label).join('、');
  return '完成后会提醒你补充$modules记录。';
}
