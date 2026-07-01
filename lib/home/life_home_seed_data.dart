part of '../main.dart';

List<TodoItem> _createSeedTodos() {
  final today = DateUtils.dateOnly(DateTime.now());
  return [
    TodoItem(
      title: '遛狗',
      category: '生活',
      color: const Color(0xFF7D9CFF),
      priority: TodoPriority.shouldDo,
      dueDate: today,
    ),
    TodoItem(
      title: '打羽毛球',
      category: '健康',
      color: const Color(0xFFFF6F9D),
      priority: TodoPriority.mustDo,
      dueDate: today,
      linkedModules: const [TodoLinkedModule.workout, TodoLinkedModule.health],
    ),
    TodoItem(
      title: '做报表',
      category: '工作',
      color: const Color(0xFF9278F7),
      priority: TodoPriority.mustDo,
      status: TodoStatus.inProgress,
      dueDate: today,
    ),
    TodoItem(
      title: '还信用卡',
      category: '财务',
      color: AppColors.success,
      priority: TodoPriority.mustDo,
      dueDate: today,
      linkedModules: const [TodoLinkedModule.finance],
      note: '完成后补一条还款记录。',
    ),
    TodoItem(
      title: '早睡',
      category: '健康',
      color: const Color(0xFFFF6F9D),
      priority: TodoPriority.shouldDo,
      dueDate: today.add(const Duration(days: 1)),
      repeatRule: TodoRepeatRule.daily,
      linkedModules: const [TodoLinkedModule.health],
    ),
    TodoItem(
      title: '整理学习清单',
      category: '学习',
      color: const Color(0xFFB88955),
      priority: TodoPriority.canDelay,
      note: '无日期任务先放进待办箱。',
    ),
  ];
}

List<FinanceRecord> _createSeedFinanceRecords() {
  return [
    FinanceRecord(
      icon: Icons.restaurant_rounded,
      title: '三餐',
      subtitle: '原味板烧鸡腿麦满分',
      amount: 18,
      type: '支出',
      account: '现金',
    ),
    FinanceRecord(
      icon: Icons.phone_iphone_rounded,
      title: '数码分期',
      subtitle: '手机分期还款',
      amount: 500,
      type: '支出',
      account: '信用卡',
    ),
    FinanceRecord(
      icon: Icons.account_balance_wallet_rounded,
      title: '工资',
      subtitle: '本月收入',
      amount: 3000,
      type: '收入',
      account: '银行卡',
    ),
    FinanceRecord(
      icon: Icons.local_cafe_rounded,
      title: '咖啡',
      subtitle: '优品豆浆（小杯）',
      amount: 6,
      type: '支出',
      account: '支付宝',
    ),
  ];
}
